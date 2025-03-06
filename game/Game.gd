extends Node2D
class_name Game


signal game_stage_changed(game_manager)

enum GAME_STAGE {SETTING_UP, READY, INTRO, PLAYING, END_SUCCESS, END_FAIL}
var game_stage: int = -1 setget _change_game_stage

export (Array, NodePath) var main_signal_connecting_paths: Array = []
var main_signal_connecting_nodes: Array = []

enum VIEW_TILE {ONE, TWO_VER, THREE_LEFT, THREE_RIGHT, FOUR }

var fast_start_window_on: bool = false # driver ga čekira in reagira
var game_views_with_drivers: Dictionary = {}

# level
var game_level: Level
var level_profile: Dictionary # set_level seta iz profilov
var level_index: int = -1
var start_position_nodes: Array # dobi od levela

# shadows
onready var game_shadows_length_factor: float = Sts.game_shadows_length_factor # set_game seta iz profilov
onready var game_shadows_alpha: float = Sts.game_shadows_alpha # set_game seta iz profilov
onready var game_shadows_color: Color = Sts.game_shadows_color # set_game seta iz profilov
onready var game_shadows_rotation_deg: float = Sts.game_shadows_rotation_deg # set_game seta iz profilov
onready var game_views_holder: VFlowContainer = $GameViewFlow
onready var GameView: PackedScene = preload("res://game/GameView.tscn")
onready var hud: Control = $Gui/Hud
onready var game_tracker: Node = $Tracker
onready var game_reactor: Node = $Reactor

var finale_game_data: Dictionary = {}
var drivers_on_start: Array = [] # to so nodeti
var camera_leader: Node2D = null setget _change_camera_leader
onready var curr_game_settings: Dictionary = {
	"max_wins_count": Sts.wins_goal_count
	#var game_levels: Array = []
}

func _input(event: InputEvent) -> void:


	if Input.is_action_just_pressed("no1"):
		get_tree().set_group(Rfs.group_shadows, "imitate_3d", true)
	elif Input.is_action_just_pressed("no2"):
		get_tree().set_group(Rfs.group_shadows, "imitate_3d", false)
	elif Input.is_action_just_pressed("no3"):
		game_reactor.animate_day_night()


func _ready() -> void:
#	printt("GM")
	printt("game in", Time.get_ticks_msec())

	Rfs.game_manager = self
	modulate = Color.black

	# debug reset views
	for view in game_views_holder.get_children():
		if not view == game_views_holder.get_child(0):
			view.queue_free()

	for path in main_signal_connecting_paths:
		main_signal_connecting_nodes.append(get_node(path))

#	game_levels = Sts.game_levels
	call_deferred("set_game")
	printt("game read", Time.get_ticks_msec())


func set_game():
	# čez set_game gre tudi next level

	self.game_stage = GAME_STAGE.SETTING_UP

	# reset
	drivers_on_start.clear()

	for view in game_views_holder.get_children():
		if not view == game_views_holder.get_child(0):
			view.queue_free()
	game_views_with_drivers.clear()

	level_index += 1
	_set_game_level()



	yield(get_tree(), "idle_frame")


	game_reactor.game_level = game_level
	game_tracker.game_level = game_level

	# prvi level
	if level_index == 0:
		for driver_id in Sts.drivers_on_game_start:
			finale_game_data[driver_id] = {}
			finale_game_data[driver_id]["driver_profile"] = Pfs.driver_profiles[driver_id]
			_spawn_vehicle(driver_id, Sts.drivers_on_game_start.find(driver_id))
	else:
		var start_position_index: int = 0
		for driver_id in finale_game_data:
			if not finale_game_data[driver_id]["driver_stats"][Pfs.STATS.LEVEL_RANK] == -1:
				_spawn_vehicle(driver_id, start_position_index)
				start_position_index += 1

		# prenos stats v vehicle iz prejšnega levela ... tihi, ker hud še ni spawnan
		for driver in drivers_on_start:
			var prev_level_stats: Dictionary = finale_game_data[driver.driver_id]["driver_stats"]
			var stats_to_reset: Array = [Pfs.STATS.LAP_TIME, Pfs.STATS.LAP_COUNT, Pfs.STATS.LEVEL_TIME, Pfs.STATS.LEVEL_RANK]
			for stat in prev_level_stats:
				if not stat in stats_to_reset:
					driver.driver_stats[stat] = prev_level_stats[stat]
			finale_game_data[driver.driver_id].erase("driver_stats")


	yield(get_tree(), "idle_frame")


	# camera in views
	if Sts.one_screen_mode:
		var game_camera: Camera2D = get_tree().get_nodes_in_group(Rfs.group_player_cameras)[0]
		game_camera.playing_field.connect( "body_exited_playing_field", game_reactor, "_on_body_exited_playing_field")
		if level_profile["rank_by"] == Pfs.RANK_BY.TIME:
			game_camera.playing_field.enable_playing_field(true)
		else:
			game_camera.playing_field.enable_playing_field(true, true) # z edgom
		for player_vehicle in get_tree().get_nodes_in_group(Rfs.group_players):
			player_vehicle.vehicle_camera = game_camera
		# game view dodam med aktivne
		game_views_with_drivers[game_views_holder.get_child(0)] = get_tree().get_nodes_in_group(Rfs.group_players)[0]
		set_game_views(1)
	else:
		# default view in prvi plejer
		game_views_with_drivers[game_views_holder.get_child(0)] = get_tree().get_nodes_in_group(Rfs.group_players)[0] #  dodam ga med game viewe
		var player_vehicle_in_first_view: Vehicle = game_views_with_drivers.values().front()
		player_vehicle_in_first_view.vehicle_camera = get_tree().get_nodes_in_group(Rfs.group_player_cameras)[0]
		get_tree().get_nodes_in_group(Rfs.group_player_cameras)[0].get_node("PlayingField").enable_playing_field(false)
		# ostali viewe
		_spawn_game_views()
		var players_count: int = get_tree().get_nodes_in_group(Rfs.group_players).size()
		set_game_views(players_count)
		# camera targets
		for player in get_tree().get_nodes_in_group(Rfs.group_players):
			player.vehicle_camera.follow_target = player






	game_reactor.drivers_finished.clear()

	self.game_stage = GAME_STAGE.READY


	Rfs.ultimate_popup.hide() # skrijem pregame

	_game_intro()


func _set_game_level():

	if level_index > 0:
		# unmute sfx
		if not Rfs.sound_manager.sfx_set_to_mute:
			var bus_index: int = AudioServer.get_bus_index("GameSfx")
			AudioServer.set_bus_mute(bus_index, false)

	if game_level: # če level že obstaja, ga najprej moram zbrisat
		game_level.set_physics_process(false)
		game_level.queue_free()

	var new_level_key: int = Sts.game_levels[level_index]
	level_profile = Pfs.level_profiles[new_level_key]
	_spawn_level(level_profile)


func _game_intro():

	self.game_stage = GAME_STAGE.INTRO

	# pokažem sceno
	var fade_time: float = 1
	var setup_delay: float = 0 # delay, da se kamera naštima
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(self, "modulate", Color.white, fade_time).from(Color.black).set_delay(setup_delay)
	yield(fade_tween, "finished")

	# drivers drive-in
	var drive_in_time: float = 2
	for driver in drivers_on_start:
		var drive_in_position: Vector2 = Vector2.ZERO
		if game_level.level_start:
			drive_in_position = game_level.level_start.drive_in_position_node.global_position
			driver.motion_manager.drive_in(drive_in_position, drive_in_time)

	# počakam, da odpelje
	yield(get_tree().create_timer(drive_in_time),"timeout")

	_start_game()


func _start_game():

	# start countdown
	if Sts.start_countdown and level_profile["rank_by"] == Pfs.RANK_BY.TIME:
		game_level.level_start.start_lights.start_countdown() # če je skrit, pošlje signal takoj
		yield(game_level.level_start.start_lights, "countdown_finished")

	self.game_stage = GAME_STAGE.PLAYING

	Rfs.sound_manager.play_music()


func _change_game_stage(new_game_stage: int):
#	print("GAME_STAGE: ", GAME_STAGE.keys()[new_game_stage])

	game_stage = new_game_stage

	match game_stage:
		GAME_STAGE.SETTING_UP:
			# najprej povežem s s signalom
			for connecting_node in main_signal_connecting_nodes:
				if not self.is_connected("game_stage_changed", connecting_node, "_on_game_stage_changed"):
					self.connect("game_stage_changed", connecting_node, "_on_game_stage_changed")

		GAME_STAGE.READY:
			emit_signal("game_stage_changed", self)

		GAME_STAGE.INTRO:
			emit_signal("game_stage_changed", self)

		GAME_STAGE.PLAYING: # samo kar ni samo na štartu
			if not level_profile["rank_by"] == Pfs.RANK_BY.TIME: # zaženem vsakič, tudi po pavzi
				game_reactor.spawn_random_pickables()
			emit_signal("game_stage_changed", self)

		GAME_STAGE.END_SUCCESS, GAME_STAGE.END_FAIL:
			#			print("finale_game_data")
			#			print(finale_game_data)
			#			yield(get_tree().create_timer(Sts.get_it_time), "timeout")
#			if not game_reactor.drivers_finished.empty(): # zmaga
#				game_reactor.drivers_finished[0].update_stat(Pfs.STATS.WINS, level_profile["level_name"]) # temp WINS pozicija
			emit_signal("game_stage_changed", self)
			# ustavi elemente
				# best lap stats reset
				# looping sounds stop
				# navigacija AI
				# kvefri elementov, ki so v areni
			get_tree().set_group(Rfs.group_player_cameras, "follow_target", null)
			Rfs.sound_manager.stop_music()
			var bus_index: int = AudioServer.get_bus_index("GameSfx")
			AudioServer.set_bus_mute(bus_index, true)


func set_game_views(players_count: int = 1):

	# flow separation
	var v_sep: float = game_views_holder.get_constant("vseparation")
	var h_sep: float = game_views_holder.get_constant("hseparation")

	# view size
	var full_size: Vector2 = get_viewport_rect().size
	var view_tile: int = VIEW_TILE.ONE
	match players_count:
		1:
			view_tile = VIEW_TILE.ONE
			game_views_with_drivers.keys()[0].get_node("Viewport").size = full_size
		2:
			view_tile = VIEW_TILE.TWO_VER
			if view_tile == VIEW_TILE.TWO_VER:
				# view size
				game_views_with_drivers.keys()[0].get_node("Viewport").size = full_size * Vector2(0.5, 1)
				game_views_with_drivers.keys()[1].get_node("Viewport").size = full_size * Vector2(0.5, 1)
				# adapt for separation
				game_views_with_drivers.keys()[0].get_node("Viewport").size.x -= h_sep/2
				game_views_with_drivers.keys()[1].get_node("Viewport").size.x -= h_sep/2
		3:
			view_tile = VIEW_TILE.THREE_LEFT
			if view_tile == VIEW_TILE.THREE_LEFT:
				game_views_with_drivers.keys()[0].get_node("Viewport").size = full_size * Vector2(0.5, 1)
				game_views_with_drivers.keys()[1].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
				game_views_with_drivers.keys()[2].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
				game_views_with_drivers.keys()[0].get_node("Viewport").size.y -= v_sep/2
				game_views_with_drivers.keys()[1].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
				game_views_with_drivers.keys()[2].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
			elif view_tile == VIEW_TILE.THREE_RIGHT:
				game_views_with_drivers.keys()[0].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
				game_views_with_drivers.keys()[2].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
				game_views_with_drivers.keys()[2].get_node("Viewport").size = full_size * Vector2(0.5, 1)
				game_views_with_drivers.keys()[0].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
				game_views_with_drivers.keys()[1].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
				game_views_with_drivers.keys()[2].get_node("Viewport").size.y -= v_sep/2
			game_views_with_drivers.keys()[2].get_node("Viewport").size.y -= v_sep/2
		4:
			view_tile = VIEW_TILE.FOUR
			game_views_with_drivers.keys()[0].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
			game_views_with_drivers.keys()[1].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
			game_views_with_drivers.keys()[3].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
			game_views_with_drivers.keys()[2].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
			game_views_with_drivers.keys()[0].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
			game_views_with_drivers.keys()[1].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
			game_views_with_drivers.keys()[2].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
			game_views_with_drivers.keys()[3].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2


func apply_stats_to_unfinished_drivers(unfinished_driver_ids: Array):

	var current_game_time: int = hud.game_timer.game_time_hunds

	# dodam neuvrščene ai-je, ki vedno pridejo do konca
	for driver_id in unfinished_driver_ids:

		var driver_vehicle: Vehicle
		for vehicle in game_tracker.drivers_in_game:
			if vehicle.driver_id == driver_id:
				driver_vehicle = vehicle
				break

		# izračun predvidenega časa ... glede na prevožen procent
		if driver_vehicle:
			var distance_needed_part: float = driver_vehicle.driver_tracker.unit_offset
			if distance_needed_part == 0: # če obtiči na štartu ... verjetno nioli
				driver_vehicle.driver_stats[Pfs.STATS.LEVEL_TIME] = current_game_time
			else:
				driver_vehicle.driver_stats[Pfs.STATS.LEVEL_TIME] = current_game_time / distance_needed_part
			finale_game_data[driver_id]["driver_stats"] = driver_vehicle.driver_stats.duplicate()


func _change_camera_leader(new_camera_leader: Node2D):

	if not new_camera_leader == camera_leader:
		camera_leader = new_camera_leader
		get_tree().set_group(Rfs.group_player_cameras, "follow_target", camera_leader)


# SPAWNING ---------------------------------------------------------------------------------------------


func _spawn_game_views():

	for player_vehicle in get_tree().get_nodes_in_group(Rfs.group_players):
		# def view je že setan
		if not player_vehicle == get_tree().get_nodes_in_group(Rfs.group_players)[0]:
			var new_game_view: ViewportContainer = GameView.instance()
			game_views_holder.add_child(new_game_view)
			game_views_with_drivers[new_game_view] = player_vehicle
			player_vehicle.vehicle_camera = new_game_view.get_node("Viewport/GameCamera")

	# viewport world
	var world_to_inherit: World2D = game_views_with_drivers.keys()[0].get_node("Viewport").world_2d
	var current_game_views: Dictionary = game_views_with_drivers
	for view_index in game_views_with_drivers.size():
		if view_index > 0:
			game_views_with_drivers.keys()[view_index].get_node("Viewport").world_2d = world_to_inherit


func _spawn_level(spawn_level_profile: Dictionary):

	# spawn
	var level_spawn_parent: Node = game_views_holder.get_child(0).get_node("Viewport") # VP node
	var NewLevel: PackedScene = spawn_level_profile["level_scene"]
	var new_level = NewLevel.instance()
	level_spawn_parent.add_child(new_level)
	level_spawn_parent.move_child(new_level, 0)

	# setup
	new_level.connect("level_is_set", self, "_on_level_is_set") # nujno pred add child, ker ga level sproži že na ready
	for node_path in new_level.level_goals_paths:
		new_level.get_node(node_path).connect("reached_by", game_reactor, "_on_goal_reached")
	if new_level.level_finish_path:
		new_level.get_node(new_level.level_finish_path).connect("reached_by", game_reactor, "_on_finish_crossed")

	new_level.set_level()

	game_level = new_level


func _spawn_vehicle(driver_id: String, spawned_position_index: int):

	var scene_name: String = "vehicle_scene"
	var vehicle_type: int = Pfs.VEHICLE.values()[0]

	var new_driver_stats: Dictionary = {}
	if level_index > 0:
		new_driver_stats = finale_game_data[driver_id]["driver_stats"].duplicate()
	else:
		new_driver_stats = Pfs.start_driver_stats.duplicate()
		# reset notranji arrayev ... da so unique
		# curr/max ... popravi hud, veh update stats, veh spawn, veh deact
		new_driver_stats[Pfs.STATS.WINS] = []
		new_driver_stats[Pfs.STATS.LAP_COUNT] = []
		new_driver_stats[Pfs.STATS.GOALS_REACHED] = []

	var NewVehicleInstance: PackedScene = Pfs.vehicle_profiles[vehicle_type][scene_name]
	var new_vehicle = NewVehicleInstance.instance()
	new_vehicle.driver_id = driver_id
	new_vehicle.modulate.a = 0 # za intro
	new_vehicle.rotation_degrees = game_level.level_start.rotation_degrees - 90 # ob rotaciji 0 je default je obrnjen navzgor
	new_vehicle.global_position = start_position_nodes[spawned_position_index].global_position

	# profili ... iz njih podatke povleče sam na rea dy
	new_vehicle.driver_profile = Pfs.driver_profiles[driver_id].duplicate()
	new_vehicle.driver_stats = new_driver_stats
	new_vehicle.default_vehicle_profile = Pfs.vehicle_profiles[vehicle_type].duplicate()

	# tip level je njegov namen obstoja, edino kar ve o levelu ... zaenkrat
	new_vehicle.rank_by = level_profile["rank_by"] # se ga napolnil ob spawnu levela

	Rfs.node_creation_parent.add_child(new_vehicle)

	# ai navigation
	if Pfs.driver_profiles[driver_id]["driver_type"] == Pfs.DRIVER_TYPE.AI:
		new_vehicle.driver.level_navigation = game_level.level_navigation
	# trackers
	if game_level.level_track:
		new_vehicle.driver_tracker = game_level.level_track.set_new_tracker(new_vehicle)
	# goals
	new_vehicle.driver.goals_to_reach = game_level.level_goals.duplicate()

	# connect
	self.connect("game_stage_changed", new_vehicle.driver, "_on_game_stage_change")
	new_vehicle.connect("vehicle_deactivated", game_reactor, "_on_vehicle_deactivated")
	new_vehicle.connect("stat_changed", hud, "_on_driver_stat_changed")

	drivers_on_start.append(new_vehicle)


func _on_level_is_set(rank_by: int, start_positions: Array, camera_limits: Control, camera_start_position_node: Position2D, level_goals: Array):

	level_profile["rank_by"] = rank_by # do tukaj ga ni v slovarju
	level_profile["level_goals"] = level_goals # do tukaj ga ni v slovarju
	start_position_nodes = start_positions.duplicate()
	get_tree().call_group(Rfs.group_player_cameras, "set_camera", camera_limits, camera_start_position_node)
