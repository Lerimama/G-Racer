extends Node2D
#class_name Game


signal game_stage_changed(game_manager)

#enum GAME_STAGE {SETTING_UP, READY, PLAYING, END_SUCCESS, FINISHED_FAIL}
enum GAME_STAGE {SETTING_UP, READY, PLAYING, FINISHED_FAIL, FINISHED_SUCCESS}
var game_stage: int = GAME_STAGE.SETTING_UP # setget _change_game_stage

var fast_start_window_on: bool = false # driver ga čekira in reagira

# level
var game_level: Level
var level_profile: Dictionary # set_level seta iz profilov
var level_index: int = -1

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
onready var game_views: Control = $GameViews
onready var game_sound: Node = $Sound

var game_drivers_data: Dictionary = {
	#	"xavier": {
	#		"vehicle_profile": {}
	#		"driver_profile": {}
	#		"tournament_stats": {}, # med igro se ne spreminja
	#		"driver_stats": {}, # delni reset na level
	#		"weapon_stats": {}, # napolne se ob prvem levelu
	#		},
	#	"john": ...
	}


func _input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("no1"):
		get_tree().set_group(Refs.group_shadows, "imit1ate_3d", true)
	elif Input.is_action_just_pressed("no2"):
		get_tree().set_group(Refs.group_shadows, "imitate_3d", false)
	elif Input.is_action_just_pressed("no3"):
		game_tracker.animate_day_night()

	var zoom_delta: float = 0.1
	if Input.is_action_just_pressed("plus"):
		for cam in get_tree().get_nodes_in_group(Refs.group_player_cameras):
			cam.zoom += Vector2.ONE * zoom_delta
	elif Input.is_action_just_pressed("minus"):
		for cam in get_tree().get_nodes_in_group(Refs.group_player_cameras):
			cam.zoom -= Vector2.ONE * zoom_delta


func _ready() -> void:
#	printt("game in", Time.get_ticks_msec())

	modulate = Color.black

	gui.game = self
	game_tracker.game = self
	game_sound.game = self

	call_deferred("set_game")


func set_game():
	# čez set_game gre tudi next level

#	self.game_stage = GAME_STAGE.SETTING_UP
	game_stage = GAME_STAGE.SETTING_UP
	game_sound.intro_jingle.play()
	if not game_views.is_connected("views_are_set", self, "_on_views_are_set"):
		game_views.connect("views_are_set", self, "_on_views_are_set")
	# reset
	game_views.reset_views()
	game_tracker.drivers_finished.clear()

	# level
	level_index += 1 # na vsak klic znotraj ene igre gre en level višje
	yield(_spawn_level(level_index, Pros.start_driver_profiles.size()), "completed")
	game_tracker.game_level = game_level

	# drivers
	var drivers_on_start: Array = []
	var level_start_positions: Dictionary = {}

	# PRVI LEVEL ... postavim driverjev game data
	if level_index == 0:
		level_start_positions = game_level.level_start_positions
		for new_driver_id in Pros.start_driver_profiles:
			# driver data - prvi setup
			game_drivers_data[new_driver_id] = {}
			var vehicle_type: int = Pros.start_driver_profiles[new_driver_id]["vehicle_type"]
			game_drivers_data[new_driver_id]["vehicle_profile"] = Pros.vehicle_profiles[vehicle_type].duplicate()
			game_drivers_data[new_driver_id]["driver_profile"] = Pros.start_driver_profiles[new_driver_id].duplicate()
			game_drivers_data[new_driver_id]["driver_stats"] = Pros.start_driver_stats.duplicate()
			game_drivers_data[new_driver_id]["tournament_stats"] = Pros.driver_tournament_stats.duplicate()
			game_drivers_data[new_driver_id]["weapon_stats"] = {}
			# unique arrays
			game_drivers_data[new_driver_id]["tournament_stats"][Pros.STAT.TOURNAMENT_WINS] = []
			game_drivers_data[new_driver_id]["driver_stats"][Pros.STAT.LAP_COUNT] = []
			game_drivers_data[new_driver_id]["driver_stats"][Pros.STAT.GOALS_REACHED] = []
			game_drivers_data[new_driver_id]["driver_stats"][Pros.STAT.SCALPS] = []

			# spawn + zapis driver data v driverja
			var profile_index: int = Pros.start_driver_profiles.keys().find(new_driver_id)
			var new_driver: Vehicle = _spawn_vehicle(new_driver_id, level_start_positions[profile_index])
			drivers_on_start.append(new_driver)

	# DRUGI LEVELI
	else:
		# filter disq drivers
		var starting_driver_ids: Array = []
		for driver_id in game_drivers_data:
			if not game_drivers_data[driver_id]["driver_stats"][Pros.STAT.LEVEL_RANK] == -1:
				starting_driver_ids.append(driver_id)
		# spawn + zapis driver data v driverja
		level_start_positions = game_level.level_start_positions
		for driver_id in starting_driver_ids:
			var new_driver: Vehicle = _spawn_vehicle(driver_id, level_start_positions[starting_driver_ids.find(driver_id)])
			drivers_on_start.append(new_driver)
		# reset stats ... na start_driver_stats
		for driver in drivers_on_start:
			for stat in game_drivers_data[driver.driver_id]["driver_stats"]:
				if not stat in [Pros.STAT.HEALTH, Pros.STAT.GAS, Pros.STAT.CASH]:
					game_drivers_data[driver.driver_id]["driver_stats"][stat] = Pros.start_driver_stats[stat]

	yield(get_tree(), "idle_frame")

	# game views
	var drivers_with_views: Array = []
	for driver in drivers_on_start:
		if driver.is_in_group(Refs.group_players):
			drivers_with_views.append(driver)
	game_views.set_game_views(drivers_with_views, Sets.mono_view_mode)

	# kamere
	get_tree().call_group(Refs.group_player_cameras, "set_camera", game_level.camera_limits, game_level.camera_position_2d)
	for camera in get_tree().get_nodes_in_group(Refs.group_player_cameras):
		camera.zoom.x = Sets.camera_start_zoom
		camera.zoom.y = Sets.camera_start_zoom
		if Sets.mono_view_mode:
			camera.set_camera(game_level.camera_limits, game_level.camera_position_2d, true, Sets.camera_start_zoom)
			if not camera.playing_field.is_connected( "body_exited_playing_field", game_tracker, "_on_player_exited_playing_field"):
				camera.playing_field.connect( "body_exited_playing_field", game_tracker, "_on_player_exited_playing_field")
		else:
			camera.set_camera(game_level.camera_limits, game_level.camera_position_2d, false, Sets.camera_start_zoom)
	# senčke
	get_tree().call_group(Refs.group_shadows, "update_shadow_parameters", self)

	# gui
	gui.set_gui(drivers_on_start)

	_game_intro(drivers_on_start, level_start_positions)


func _game_intro(starting_drivers: Array, driver_start_positions: Dictionary):

#	self.game_stage = GAME_STAGE.READY
	game_stage = GAME_STAGE.READY
	if not game_sound.intro_jingle.is_playing(): # _temp
		game_sound.intro_jingle.play()
	Refs.ultimate_popup.hide() # skrijem pregame
	# camera targets
	if not Sets.mono_view_mode:
		for player in get_tree().get_nodes_in_group(Refs.group_players):
			player.vehicle_camera.follow_target = player

	# pokažem sceno
	#	var fade_time: float = 1
	#	var setup_delay: float = 0 # delay, da se kamera naštima
	#	var fade_tween = get_tree().create_tween()
	#	fade_tween.tween_property(self, "modulate", Color.white, fade_time).from(Color.black).set_delay(setup_delay)
	#	yield(fade_tween, "finished")
	modulate = Color.white

	# drivers drive-in
	var drive_in_time: float = 2
	for driver in starting_drivers: # alt ... če bi čakal gameviews signal ... get_tree().get_nodes_in_group(Refs.group_drivers):
		var driver_start_position: Vector2 = driver_start_positions[starting_drivers.find(driver)][0]
		driver_start_position = Vector2.ZERO
#		var drive_in_rotation: float = drive_in_positions[starting_drivers.find(driver)][1]
#		driver.motion_manager.drive_in(drive_in_position, drive_in_rotation, 5)
#		driver.motion_manager.drive_in(Vector2.ZERO, 0, drive_in_time)
		driver.motion_manager.drive_in(driver_start_position, 0, drive_in_time)

	# počakam, da odpelje
	yield(get_tree().create_timer(drive_in_time),"timeout")

	_start_game()


func _start_game():

	# start countdown
	if game_level.start_line.is_enabled:
		game_level.start_line.start_lights.start_countdown()
		var semaphore_lights_count: int = 3
		yield(get_tree().create_timer(semaphore_lights_count), "timeout") # neodvisen od countdown signala

#	self.game_stage = GAME_STAGE.PLAYING
	game_stage = GAME_STAGE.PLAYING
	if game_sound.intro_jingle.is_playing(): # če je pavza pred začetkom igre ... ob zapiranju zapleja gejm musko
		game_sound.fade_sounds(game_sound.intro_jingle, game_sound.game_music)
	gui.on_game_start()
	for driver in get_tree().get_nodes_in_group(Refs.group_drivers):
		driver.controller.on_game_start(game_level)


func end_game():

	# preverjam success ... če je vsaj en plejer med finished

	game_stage = GAME_STAGE.FINISHED_FAIL
#	game_stage = GAME_STAGE.FINISHED_SUCCESS
	for driver in game_tracker.drivers_finished:
		if driver in get_tree().get_nodes_in_group(Refs.group_players):
			game_stage = GAME_STAGE.FINISHED_SUCCESS

	if game_stage == GAME_STAGE.FINISHED_SUCCESS:
		game_sound.fade_sounds(game_sound.game_music, game_sound.win_jingle)
	else:
		game_sound.fade_sounds(game_sound.game_music, game_sound.lose_jingle)

	gui.on_level_finished()

	# ustavi elemente
		# best lap stats reset
		# looping sounds stop
		# navigacija AI
		# kvefri elementov, ki so v areni
	get_tree().set_group(Refs.group_player_cameras, "follow_target", null)
	game_tracker._update_camera_leader(null)
	#			var bus_index: int = AudioServer.get_bus_index("GameSfx")
	#			AudioServer.set_bus_mute(bus_index, true)


var different_level
func _spawn_level(new_level_index: int, drivers_count: int):
	# more bit index, če je level key, je problem, če se leveli ponavljajo

	# curr level off
	if new_level_index > 0:
		if not game_sound.sfx_set_to_mute: # unmute sfx
			var bus_index: int = AudioServer.get_bus_index("GameSfx")
			AudioServer.set_bus_mute(bus_index, false)
	if game_level: # če level že obstaja, ga najprej moram zbrisat
		game_level.set_process(false)
		game_level.set_physics_process(false)
		game_level.queue_free()

	level_profile = Levs.level_profiles[Sets.game_levels[new_level_index]]

	# spawn
	var level_spawn_parent: Node = game_views.get_child(0).get_node("Viewport") # VP node
	var NewLevel: PackedScene = level_profile["level_scene"]
	var new_level = NewLevel.instance()
	level_spawn_parent.add_child(new_level)
	level_spawn_parent.move_child(new_level, 0)

	yield(new_level.set_level(drivers_count), "completed")

	# setup

	# če so goali je lahko med njimi finish line
	level_profile["level_goals"] = []
	for goal in new_level.level_goals:
		if goal.has_signal("reached_by"):
			if not goal == new_level.finish_line:
				goal.connect("reached_by", game_tracker, "_on_goal_reached")
				goal.connect("tree_exiting", game_tracker, "_on_goal_exiting_tree", [goal])
				# dodam tudi finish line rabim max pri statsih
				# za prepoznavanje ali je v uporabi ali ne je bolje da je notri ali ni
				level_profile["level_goals"].append(goal.name)

	# finish line povežem posebej, da ima posebej funkcijo
	if new_level.finish_line.is_enabled:
		new_level.finish_line.connect("reached_by", game_tracker, "_on_finish_crossed")

	#	prints("3 ... _spawn_levele finished", level_profile)
	game_level = new_level



func _spawn_next_level(new_level_index:int, drivers_count: int):


	# curr level off
	if new_level_index > 0:
		if not game_sound.sfx_set_to_mute: # unmute sfx
			var bus_index: int = AudioServer.get_bus_index("GameSfx")
			AudioServer.set_bus_mute(bus_index, false)
	if game_level: # če level že obstaja, ga najprej moram zbrisat
		game_level.set_process(false)
		game_level.set_physics_process(false)
		game_level.queue_free()

	level_profile = Levs.level_profiles[Sets.game_levels[new_level_index]]

	# spawn
	var level_spawn_parent: Node = game_views.get_child(0).get_node("Viewport") # VP node
	var NewLevel: PackedScene = level_profile["level_scene"]
	var new_level = NewLevel.instance()
	level_spawn_parent.add_child(new_level)
	level_spawn_parent.move_child(new_level, 0)

	yield(new_level.set_level(drivers_count), "completed")

	# setup

	# če so goali je lahko med njimi finish line
	level_profile["level_goals"] = []
	for goal in new_level.level_goals:
		if goal.has_signal("reached_by"):
			if not goal == new_level.finish_line:
				goal.connect("reached_by", game_tracker, "_on_goal_reached")
				goal.connect("tree_exiting", game_tracker, "_on_goal_exiting_tree", [goal])
				# dodam tudi finish line rabim max pri statsih
				# za prepoznavanje ali je v uporabi ali ne je bolje da je notri ali ni
				level_profile["level_goals"].append(goal.name)

	# finish line povežem posebej, da ima posebej funkcijo
	if new_level.finish_line.is_enabled:
		new_level.finish_line.connect("reached_by", game_tracker, "_on_finish_crossed")

	#	prints("3 ... _spawn_levele finished", level_profile)
	game_level = new_level


func _spawn_vehicle(driver_id: String, start_position: Array):

	var scene_name: String = "vehicle_scene"
	var spawn_position: Vector2 = start_position[0]
	var spawn_rotation: float = start_position[1]

	var vehicle_type: int = game_drivers_data[driver_id]["driver_profile"]["vehicle_type"]
	var NewVehicleInstance: PackedScene = Pros.vehicle_profiles[vehicle_type][scene_name]
	var new_vehicle = NewVehicleInstance.instance()

	new_vehicle.modulate.a = 0 # za intro
	new_vehicle.global_position = spawn_position
	new_vehicle.global_rotation = spawn_rotation# - deg2rad(90) # ob rotaciji 0 je default je obrnjen navzgor

	new_vehicle.driver_id = driver_id
	new_vehicle.vehicle_profile = game_drivers_data[driver_id]["vehicle_profile"].duplicate()
	new_vehicle.driver_profile = game_drivers_data[driver_id]["driver_profile"].duplicate()
	new_vehicle.driver_stats = game_drivers_data[driver_id]["driver_stats"].duplicate()
	new_vehicle.weapon_stats = game_drivers_data[driver_id]["weapon_stats"].duplicate()

	Refs.node_creation_parent.add_child(new_vehicle)

	# ai navigation
	if Pros.start_driver_profiles[driver_id]["controller_type"] == -1:
		new_vehicle.controller.level_navigation = game_level.level_navigation
	# trackers
	if game_level.tracking_line.is_enabled:
		new_vehicle.driver_tracker = game_level.tracking_line.spawn_new_tracker(new_vehicle)

	new_vehicle.connect("vehicle_deactivated", game_tracker, "_on_vehicle_deactivated")

	return new_vehicle


# SIGNALI ---------------------------------------------------------------------------------------------


func _on_views_are_set():

#	self.game_stage = GAME_STAGE.READY
	pass
