extends Node2D
class_name Game


signal game_stage_changed(game_manager)

enum GAME_STAGE {SETTING_UP, READY, PLAYING, END_SUCCESS, END_FAIL}
var game_stage: int = 0 setget _change_game_stage

export (Array, NodePath) var main_signal_connecting_paths: Array = []
var main_signal_connecting_nodes: Array = []
var fast_start_window_on: bool = false # driver ga čekira in reagira

# level
var game_level: Level
var level_profile: Dictionary # set_level seta iz profilov
var level_index: int = 0
#var start_position_nodes: Array # dobi od levela

# shadows
onready var game_shadows_length_factor: float = Sets.game_shadows_length_factor # set_game seta iz profilov
onready var game_shadows_alpha: float = Sets.game_shadows_alpha # set_game seta iz profilov
onready var game_shadows_color: Color = Sets.game_shadows_color # set_game seta iz profilov
onready var game_shadows_rotation_deg: float = Sets.game_shadows_rotation_deg # set_game seta iz profilov

# main nodes
# _temp... za tele ne rabim signalov?
# njim podelim tudi self
onready var gui: CanvasLayer = $Gui
onready var game_tracker: Node = $Tracker
onready var game_reactor: Node = $Reactor
onready var game_views: Control = $GameViews
onready var game_sound: Node = $Sound

var game_levels: Array = []
var camera_leader: Node2D = null setget _change_camera_leader
onready var curr_game_settings: Dictionary = {
	"max_wins_count": Sets.wins_goal_count
	#var game_levels: Array = []
	}
var final_level_data: Dictionary = {
	#	"level_time": 100,
	#	level_profile: {},
	#	"...": "",
	}
var final_drivers_data: Dictionary = {
	#	"xavier": {
	#		"weapon_stats": {},
	#		"driver_stats": {},
	#		"driver_profile": {}
	#		},
	}


func _input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("no1"):
		get_tree().set_group(Refs.group_shadows, "imit1ate_3d", true)
	elif Input.is_action_just_pressed("no2"):
		get_tree().set_group(Refs.group_shadows, "imitate_3d", false)
	elif Input.is_action_just_pressed("no3"):
		game_reactor.animate_day_night()


func _ready() -> void:
#	printt("GM")
	printt("game in", Time.get_ticks_msec())

#	Refs.game_manager = self
	modulate = Color.black

	# nodeti, ki želijo glavni signal
	for path in main_signal_connecting_paths:
		main_signal_connecting_nodes.append(get_node(path))

	gui.game_manager = self
	game_tracker.game = self
	game_reactor.game = self
	game_views.game_manager = self
	game_sound.game_manager = self

	call_deferred("set_game")


func set_game(level_index_add: int = 0):
	# čez set_game gre tudi next level

	self.game_stage = GAME_STAGE.SETTING_UP

	# reset
	game_views.reset_views()
	game_reactor.drivers_finished.clear()

	# level
	game_levels = Sets.game_levels
	level_index += level_index_add
	_spawn_level(level_index)
	final_level_data["level_profile"] = level_profile
	game_reactor.game_level = game_level
	game_tracker.game_level = game_level

	yield(get_tree(), "idle_frame")

	# drivers
	var drivers_on_start: Array = [] # to so nodeti
	if level_index == 0:
		var level_start_positions: Array = game_level.set_start_positions(Pros.start_driver_profiles.size())
		for driver_id_as_profile_key in Pros.start_driver_profiles:
			var new_drivers_profile: Dictionary = Pros.start_driver_profiles[driver_id_as_profile_key]
			final_drivers_data[driver_id_as_profile_key] = {}
			final_drivers_data[driver_id_as_profile_key]["driver_profile"] = new_drivers_profile
			var profile_index: int = Pros.start_driver_profiles.keys().find(driver_id_as_profile_key)



			var new_driver: Vehicle = _spawn_vehicle(driver_id_as_profile_key, level_start_positions[profile_index])
			drivers_on_start.append(new_driver)
	else:
		var level_start_positions: Array = game_level.set_start_positions(drivers_on_start.size())
		var start_position_index: int = 0
		for driver_id in final_drivers_data:
			if not final_drivers_data[driver_id]["driver_stats"][Pros.STATS.LEVEL_RANK] == -1:
				var new_driver: Vehicle = _spawn_vehicle(driver_id,  level_start_positions[start_position_index])
				drivers_on_start.append(new_driver)
				start_position_index += 1
		# prenos stats v vehicle iz prejšnega levela in reset ... tihi, ker hud še ni spawnan
		for driver in drivers_on_start:
			# driver stats
			var prev_level_stats: Dictionary = final_drivers_data[driver.driver_id]["driver_stats"]
			for stat in prev_level_stats:
				if stat in [Pros.STATS.BEST_LAP_TIME, Pros.STATS.LAP_TIME, Pros.STATS.LAP_COUNT, Pros.STATS.LEVEL_TIME, Pros.STATS.LEVEL_RANK]:
					driver.driver_stats[stat] = Pros.start_driver_stats[stat]
				else:
					driver.driver_stats[stat] = prev_level_stats[stat]
			final_drivers_data[driver.driver_id].erase("driver_stats")
			# weapon stats
			prev_level_stats = final_drivers_data[driver.driver_id]["weapon_stats"]
			for stat in prev_level_stats:
				driver.weapon_stats[stat] = prev_level_stats[stat]
			final_drivers_data[driver.driver_id].erase("weapon_stats")

	yield(get_tree(), "idle_frame")

	# game views
	var drivers_with_views: Array = []
	for driver in drivers_on_start:
		if driver.is_in_group(Refs.group_players):
			drivers_with_views.append(driver)
	game_views.set_game_views(drivers_with_views, Sets.one_screen_mode)

	# kamere
	for camera in get_tree().get_nodes_in_group(Refs.group_player_cameras):
		if Sets.one_screen_mode:
			if not camera.playing_field.is_connected( "body_exited_playing_field", game_reactor, "_on_body_exited_playing_field"):
				camera.playing_field.connect( "body_exited_playing_field", game_reactor, "_on_body_exited_playing_field")
		if level_profile["rank_by"] == Pros.RANK_BY.POINTS:
			camera.playing_field.enable_playing_field(true, true)
		else:
			camera.playing_field.enable_playing_field(true)

	# senčke
	get_tree().call_group(Refs.group_shadows, "update_shadow_parameters", self)

	# gui
	gui.set_gui(drivers_on_start)


func _game_intro():

	# camera targets
	if not Sets.one_screen_mode:
		for player in get_tree().get_nodes_in_group(Refs.group_players):
			player.vehicle_camera.follow_target = player

	# pokažem sceno
	var fade_time: float = 1
	var setup_delay: float = 0 # delay, da se kamera naštima
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(self, "modulate", Color.white, fade_time).from(Color.black).set_delay(setup_delay)
	yield(fade_tween, "finished")

	# drivers drive-in
	var drive_in_time: float = 2
	for driver in get_tree().get_nodes_in_group(Refs.group_drivers):
		var drive_in_position: Vector2 = Vector2.ZERO
		if game_level.start_line:
			drive_in_position = game_level.start_line.drive_in_position_node.global_position
			driver.motion_manager.drive_in(drive_in_position, drive_in_time)

	# počakam, da odpelje
	yield(get_tree().create_timer(drive_in_time),"timeout")

	_start_game()


func _start_game():

	# start countdown
	if Sets.start_countdown and level_profile["rank_by"] == Pros.RANK_BY.TIME:
		game_level.start_line.start_lights.start_countdown() # če je skrit, pošlje signal takoj
		yield(game_level.start_line.start_lights, "countdown_finished")

	self.game_stage = GAME_STAGE.PLAYING


func _change_game_stage(new_game_stage: int):
#	print("GAME_STAGE: ", GAME_STAGE.keys()[new_game_stage])

	game_stage = new_game_stage

	match game_stage:

		GAME_STAGE.SETTING_UP:
			game_sound.intro_jingle.play()
			if not game_views.is_connected("views_are_set", self, "_on_views_are_set"):
				game_views.connect("views_are_set", self, "_on_views_are_set")

		GAME_STAGE.READY:
			if not game_sound.intro_jingle.is_playing(): # _temp
				game_sound.intro_jingle.play()
			Refs.ultimate_popup.hide() # skrijem pregame
			_game_intro()

		GAME_STAGE.PLAYING: # samo kar ni samo na štartu

			game_sound.fade_sounds(game_sound.intro_jingle, game_sound.game_music)
			if not level_profile["rank_by"] == Pros.RANK_BY.TIME: # zaženem vsakič, tudi po pavzi
				game_reactor.spawn_random_pickables()

			gui.on_game_start()

			for driver in get_tree().get_nodes_in_group(Refs.group_drivers):
				driver.controller.on_game_start(game_level)

		GAME_STAGE.END_SUCCESS, GAME_STAGE.END_FAIL:

			if game_stage == GAME_STAGE.END_SUCCESS:
				game_sound.fade_sounds(game_sound.game_music, game_sound.win_jingle)
			else:
				game_sound.fade_sounds(game_sound.game_music, game_sound.lose_jingle)

			final_level_data["level_profile"] = level_profile
			#			print("final_drivers_data")
			#			print(final_drivers_data)
			#			yield(get_tree().create_timer(Sets.get_it_time), "timeout")
			#			if not game_reactor.drivers_finished.empty(): # zmaga
			#				game_reactor.drivers_finished[0].update_stat(Pros.STATS.WINS, level_profile["level_name"]) # temp WINS pozicija

			gui.open_game_over()

			# ustavi elemente
				# best lap stats reset
				# looping sounds stop
				# navigacija AI
				# kvefri elementov, ki so v areni
			get_tree().set_group(Refs.group_player_cameras, "follow_target", null)
			#			var bus_index: int = AudioServer.get_bus_index("GameSfx")
			#			AudioServer.set_bus_mute(bus_index, true)


func _change_camera_leader(new_camera_leader: Node2D):

	if not new_camera_leader == camera_leader:
		camera_leader = new_camera_leader
		get_tree().set_group(Refs.group_player_cameras, "follow_target", camera_leader)


# SPAWNING ---------------------------------------------------------------------------------------------


func _spawn_level(new_level_index: int):

	# curr level off
	if new_level_index > 0:
		if not game_sound.sfx_set_to_mute: # unmute sfx
			var bus_index: int = AudioServer.get_bus_index("GameSfx")
			AudioServer.set_bus_mute(bus_index, false)
	if game_level: # če level že obstaja, ga najprej moram zbrisat
		game_level.set_process(false)
		game_level.set_physics_process(false)
		game_level.queue_free()

	var new_level_key: int = game_levels[new_level_index]
	level_profile = Pros.level_profiles[new_level_key]

	# spawn
	var level_spawn_parent: Node = game_views.get_child(0).get_node("Viewport") # VP node
	var NewLevel: PackedScene = level_profile["level_scene"]
	var new_level = NewLevel.instance()
	level_spawn_parent.add_child(new_level)
	level_spawn_parent.move_child(new_level, 0)

	# setup
	new_level.connect("level_is_set", self, "_on_level_is_set") # nujno pred add child, ker ga level sproži že na ready
	for node_path in new_level.level_goals_paths:
		new_level.get_node(node_path).connect("reached_by", game_reactor, "_on_goal_reached")
	if new_level.finish_line.is_enabled:
		new_level.finish_line.connect("reached_by", game_reactor, "_on_finish_crossed")

	new_level.set_level()

	game_level = new_level


func _spawn_vehicle(driver_id: String, spawned_position: Vector2):

	var scene_name: String = "vehicle_scene"
	var vehicle_type: int = Pros.VEHICLE.values()[0]

	var NewVehicleInstance: PackedScene = Pros.vehicle_profiles[vehicle_type][scene_name]
	var new_vehicle = NewVehicleInstance.instance()

	new_vehicle.modulate.a = 0 # za intro
	new_vehicle.rotation_degrees = game_level.start_line.rotation_degrees - 90 # ob rotaciji 0 je default je obrnjen navzgor
	new_vehicle.global_position = spawned_position
#	new_vehicle.global_position = start_position_nodes[spawned_position_index].global_position

	new_vehicle.driver_id = driver_id
	new_vehicle.default_vehicle_profile = Pros.vehicle_profiles[vehicle_type].duplicate()
	new_vehicle.driver_profile = Pros.start_driver_profiles[driver_id].duplicate()
	new_vehicle.rank_by = level_profile["rank_by"] # se ga napolnil ob spawnu levela

	# stats
	var new_driver_stats: Dictionary = {}
	var new_weapon_stats: Dictionary = {}
	if level_index > 0:
		new_driver_stats = final_drivers_data[driver_id]["driver_stats"].duplicate()
		new_weapon_stats = final_drivers_data[driver_id]["weapon_stats"].duplicate()
	else:
		# weapon stats se napolnijo ob setanju weaponow
		new_driver_stats = Pros.start_driver_stats.duplicate()

		# reset notranji arrayev ... da so unique
		new_driver_stats[Pros.STATS.WINS] = []
		new_driver_stats[Pros.STATS.LAP_COUNT] = []
		new_driver_stats[Pros.STATS.GOALS_REACHED] = []
	new_vehicle.driver_stats = new_driver_stats
	new_vehicle.weapon_stats = new_weapon_stats

	Refs.node_creation_parent.add_child(new_vehicle)

	# ai navigation
	if Pros.start_driver_profiles[driver_id]["driver_type"] == Pros.DRIVER_TYPE.AI:
		new_vehicle.controller.level_navigation = game_level.level_navigation
	# trackers
	if game_level.race_track.is_enabled:
		new_vehicle.driver_tracker = game_level.race_track.spawn_new_tracker(new_vehicle)
	# goals
	new_vehicle.controller.goals_to_reach = game_level.level_goals.duplicate()
	# connect
	new_vehicle.connect("stat_changed", gui.hud, "_on_driver_stat_changed")
	new_vehicle.connect("vehicle_deactivated", game_reactor, "_on_vehicle_deactivated")

	return new_vehicle


# SIGNALI ---------------------------------------------------------------------------------------------


func _on_level_is_set(rank_by: int, camera_limits: Control, camera_start_position_node: Position2D, level_goals: Array):

	level_profile["rank_by"] = rank_by # do tukaj ga ni v slovarju
	level_profile["level_goals"] = level_goals # do tukaj ga ni v slovarju
	get_tree().call_group(Refs.group_player_cameras, "set_camera", camera_limits, camera_start_position_node)


func _on_views_are_set():

	self.game_stage = GAME_STAGE.READY
