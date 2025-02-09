extends Node2D


signal bolt_spawned (name, other)
signal game_state_changed (game_on, level_profile)

var game_on: bool

var bolts_in_game: Array # live data ... tekom igre so v ranked zaporedju (glede na distanco)
var bolts_finished: Array # bolti v cilju
var players_qualified: Array # obstaja za prenos med leveloma
var camera_leader: Node2D setget _change_camera_leader # trenutno vodilni igralec ... lahko tudi kakšen drug pogoj

# game
var activated_drivers: Array # naslednji leveli se tole adaptira, glede na to kdo je še v igri
var fast_start_window: bool = false # bolt ga čekira in reagira
var start_bolt_position_nodes: Array # dobi od tilemapa
var current_pull_positions: Array # že zasedene pozicije za preventanje nalaganja bolto druga na drugega

# level
var level_profile: Dictionary # set_level seta iz profilov
var current_level_index = 0
var available_pickable_positions: Array # za random spawn
var navigation_positions: Array # pozicije vseh navigation tiletov

# shadows
onready var game_shadows_length_factor: float = Sts.game_shadows_length_factor # set_game seta iz profilov
onready var game_shadows_alpha: float = Sts.game_shadows_alpha # set_game seta iz profilov
onready var game_shadows_color: Color = Sts.game_shadows_color # set_game seta iz profilov
onready var game_shadows_rotation_deg: float = Sts.game_shadows_rotation_deg # set_game seta iz profilov

# neu
onready var level_finished_ui: Control = $"UI/LevelFinished"
onready var game_over_ui: Control = $"UI/GameOver"
onready var hud: Control = $"UI/Hud"
onready var pause_game: Control = $"UI/PauseGame"
onready var level_finished: Control = $"UI/LevelFinished"
onready var game_over: Control = $"UI/GameOver"
onready var game_view: ViewportContainer = $"GameViewFlow/GameView"
var level_stats: Dictionary = {} # napolnem na spawn bolt
var goals_to_reach: Array = []
onready var current_level: Level
onready var GameView: PackedScene = preload("res://game/camera/GameView.tscn")
enum VIEW_TILE {ONE, TWO_VER, THREE_LEFT, THREE_RIGHT, FOUR }
onready var game_views_holder: VFlowContainer = $GameViewFlow
var active_game_views: Dictionary = {}


func _input(event: InputEvent) -> void:


	if Input.is_action_just_pressed("no1"):
		get_tree().set_group(Rfs.group_shadows, "imitate_3d", true)
	elif Input.is_action_just_pressed("no2"):
		get_tree().set_group(Rfs.group_shadows, "imitate_3d", false)
	elif Input.is_action_just_pressed("no3"):
		_animate_day_night()


func _ready() -> void:
#	printt("GM")

	Rfs.game_manager = self
	modulate = Color.black

	# debug reset views
	for view in game_views_holder.get_children():
		if not view == game_views_holder.get_child(0):
			view.queue_free()

	call_deferred("_set_game")


func _process(delta: float) -> void:

	bolts_in_game = get_tree().get_nodes_in_group(Rfs.group_bolts)

	_update_ranking()

	# camera leader
	for bolt in bolts_in_game:
		if bolt.is_in_group(Rfs.group_players) and bolt.is_active:
			self.camera_leader = bolt
			break
		self.camera_leader = null
#		printt ("LS", level_stats[bolt.driver_index][Pfs.STATS.GOALS_REACHED])


func _set_game():

#	_spawn_game_views(Sts.drivers_on_game_start)
	_spawn_level()

	yield(get_tree(), "idle_frame") # zazih ... na levelu bazira vse ostalo

	hud.setup(level_profile) # kliče GM

	# camera
	if Sts.all_bolts_on_screen_mode:
		var playing_field_node: Node2D = get_tree().get_nodes_in_group(Rfs.group_player_cameras)[0].playing_field
		playing_field_node.connect( "body_exited_playing_field", self, "_on_body_exited_playing_field")
		if level_profile["level_type"] == Pfs.BASE_TYPE.TIMED:
			playing_field_node.enable_playing_field(true)
		else:
			playing_field_node.enable_playing_field(true, true) # z edgom
	else:
		for bolt in bolts_in_game:
			bolt.vehicle_camera.playing_field.enable_playing_field(false)

	get_tree().set_group(Rfs.group_player_cameras, "follow_target", current_level.start_camera_position_node)

	# get_drivers
	if current_level_index == 0: # prvi level so aktivirani dodani v meniju
		activated_drivers = Sts.drivers_on_game_start
	else: # drugi leveli dodam kvalificirane driver_id
		for bolt in players_qualified:
			activated_drivers.append(bolt.driver_index)
	players_qualified.clear()

	# spawn bolts ... po vrsti aktivacije
	var spawned_position_index = 0
	for driver_index in activated_drivers: # so v ranking zaporedju
		_spawn_bolt(driver_index, spawned_position_index) # scena, pozicija, profile id (barva, ...)
		spawned_position_index += 1

	Rfs.ultimate_popup.hide()
	yield(get_tree(), "idle_frame") # zazih ... na levelu bazira vse ostalo

	_spawn_game_views()
	_game_intro()
#	_spawn_game_views(Sts.drivers_on_game_start)


func _game_intro():

	# pokažem sceno
	var fade_time: float = 1
	var setup_delay: float = 0 # delay, da se kamera naštima
	var fade_tween = get_tree().create_tween()
#	fade_tween.tween_property(get_parent(), "modulate", Color.white, fade_time).from(Color.black).set_delay(setup_delay)
	fade_tween.tween_property(self, "modulate", Color.white, fade_time).from(Color.black).set_delay(setup_delay)
	yield(fade_tween, "finished")

	# bolts drive-in
	var drive_in_time: float = 2
	for bolt in bolts_in_game:
		var drive_in_vector: Vector2 = current_level.drive_in_position.rotated(current_level.level_start.global_rotation)
		bolt.drive_in(drive_in_time, drive_in_vector)
	yield(get_tree().create_timer(drive_in_time),"timeout")

	_start_game()


func _start_game():


	# start countdown
	if Sts.start_countdown and level_profile["level_type"] == Pfs.BASE_TYPE.TIMED:
		current_level.start_lights.start_countdown() # če je skrit, pošlje signal takoj
		yield(current_level.start_lights, "countdown_finished")

	Rfs.sound_manager.play_music()
	hud.on_game_start()

	# random pickables spawn
	if level_profile["level_type"] == Pfs.BASE_TYPE.UNTIMED:
		_spawn_random_pickables()

	game_on = true

	for ai_bolt in get_tree().get_nodes_in_group(Rfs.group_ai):
		ai_bolt.controller._on_game_state_change(game_on, level_profile)
	for player_bolt in get_tree().get_nodes_in_group(Rfs.group_players):
		player_bolt.vehicle_camera.follow_target = bolts_in_game[bolts_in_game.find(player_bolt)]

	# fast start
	fast_start_window = true
	yield(get_tree().create_timer(Sts.fast_start_window_time), "timeout")
	fast_start_window = false


func end_level():

	# kamera
	get_tree().set_group(Rfs.group_player_cameras, "follow_target", null)

	if game_on:

		game_on = false
		emit_signal("game_state_changed", game_on, level_profile) #  poslušajo drajverji,  hud3 "signal dobijo"

		hud.on_level_finished()

		yield(get_tree().create_timer(Sts.get_it_time), "timeout")

		# preverim, če je kakšen človek kvalificiran
		if bolts_finished.empty():
			pass
		else:
			# SUCCESS če je vsaj en plejer bil čez ciljno črto
			for bolt in bolts_finished:
				if bolt.is_in_group(Rfs.group_players):
					players_qualified.append(bolt)
			# FAIL, če ni nobenega plejerja v cilju

		var level_goal_reached: bool
		if players_qualified.empty():
			level_goal_reached = false

		if level_goal_reached:
			# ranking ob koncu levela
			var bolts_ranked_on_level_finished: Array = []
			# najprej dodam bolts finished, ki je že pravilno rangiran
			bolts_ranked_on_level_finished.append_array(bolts_finished)
			# potem dodam še not finished ... po vrsti gre čez array in upošteva pogoje > vrstni red je po prevoženi distanci
			for bolt in bolts_in_game:
				if not bolts_finished.has(bolt):
					bolts_ranked_on_level_finished.append(bolt)
					if bolt.is_in_group(Rfs.group_ai):
						# AI se vedno uvrsti in dobi nekaj časa glede na zadnjega v cilju
						var worst_time_among_finished: float = bolts_finished[bolts_finished.size() - 1].driver_stats[Pfs.STATS.LEVEL_TIME]
						bolt.driver_stats[Pfs.STATS.LEVEL_TIME] = worst_time_among_finished + worst_time_among_finished / 5
						bolts_finished.append(bolt)
					elif bolt.is_in_group(Rfs.group_players):
						# plejer se na Easy_mode uvrsti brez časa
						if Sts.easy_mode:
							bolts_finished.append(bolt)

			# je level zadnji?
			if current_level_index < (Sts.current_game_levels.size() - 1):
				level_finished_ui.open_level_finished(bolts_finished, bolts_in_game)
			else:
				game_over_ui.open_gameover(bolts_finished, bolts_in_game)
				print("bolts_finished", bolts_finished)

		else:
			print("bolts_finished else ", bolts_finished)
			game_over_ui.open_gameover(bolts_finished, bolts_in_game)
			#		var fade_time = 1
			#		var fade_in_tween = get_tree().create_tween()
			#		fade_in_tween.tween_property(get_parent(), "modulate", Color.black, fade_time)
			#		yield(fade_in_tween, "finished")


		for bolt in bolts_in_game: # zazih
			# driver se deaktivira, ko mu zmanjka bencina (in ko gre čez cilj)
			# AI se deaktivira, ko gre čez cilj
			if bolt.is_active: # zazih
				bolt.is_active = false
			bolt.set_physics_process(false)

		# music stop
		Rfs.sound_manager.stop_music()
		# sfx mute
		var bus_index: int = AudioServer.get_bus_index("GameSfx")
		AudioServer.set_bus_mute(bus_index, true)

		# best lap stats reset
		# looping sounds stop
		# navigacija AI
		# kvefri elementov, ki so v areni


func set_next_level():

	current_level_index += 1

	bolts_finished = [] # resetiram šele tukaj, ker ga rabim tudi v GO

	# unmute sfx
	if not Rfs.sound_manager.sfx_set_to_mute:
		var bus_index: int = AudioServer.get_bus_index("GameSfx")
		AudioServer.set_bus_mute(bus_index, false)

	# zbrišem vse otroke v NCP (bolti, orožja, efekti, ...)
	var all_children: Array = Rfs.node_creation_parent.get_children()
	for child in all_children:
		child.queue_free()

	# reset level values
	self.camera_leader = null # trenutno vodilni igralec (rabim za camera target in pull target)

	call_deferred("_set_game")


# TRACKING ---------------------------------------------------------------------------------------------


func _update_ranking():
	# najprej po poziciji znotraj kroga, potem po številu krogov

	if level_profile["level_type"] == Pfs.BASE_TYPE.TIMED and current_level.level_track:
		var bolts_ranked: Array = []
		var all_bolt_trackers: Array = current_level.level_track.get_children()
		all_bolt_trackers.sort_custom(self, "_sort_trackers_by_offset")
		for bolt_tracker in all_bolt_trackers:
			bolts_ranked.append(bolt_tracker.tracking_target)
		bolts_ranked.sort_custom(self, "_sort_bolts_by_laps")
		bolts_in_game = bolts_ranked
	else:
		bolts_in_game.sort_custom(self, "_sort_trackers_by_points")

	for bolt in bolts_in_game:
		var current_bolt_rank: int = bolts_in_game.find(bolt) + 1
		if not current_bolt_rank == level_stats[bolt.driver_index][Pfs.STATS.LEVEL_RANK]:
			level_stats[bolt.driver_index][Pfs.STATS.LEVEL_RANK] = current_bolt_rank
			hud.update_bolt_level_stats(bolt.driver_index, Pfs.STATS.LEVEL_RANK, current_bolt_rank) # OPT prepogosto


func _pull_bolt_on_field(bolt_to_pull: Node2D): # temp ... Vechile class

	if game_on and Sts.all_bolts_on_screen_mode:

		if bolt_to_pull.is_active:

			var bolt_pull_position: Vector2 = _get_bolt_pull_position(bolt_to_pull)
			bolt_to_pull.call_deferred("pull_on_screen", bolt_pull_position)

			# če preskoči ciljno črto jo dodaj, če jo je leader prevozil
			var pulled_bolt_level_stats: Dictionary = level_stats[bolt_to_pull.driver_index]
			var leader_bolt_level_stats: Dictionary = level_stats[camera_leader.driver_index]

			# poenotim level goals/laps stats ... če ni pulan točno preko cilja, pa bi moral bit
			if pulled_bolt_level_stats[Pfs.STATS.LAPS_FINISHED].size() < leader_bolt_level_stats[Pfs.STATS.LAPS_FINISHED].size():
				pulled_bolt_level_stats[Pfs.STATS.LAPS_FINISHED] = leader_bolt_level_stats[Pfs.STATS.LAPS_FINISHED]
			# mogoče tega spodej nebi mel ... bomo videlo po testu
			if pulled_bolt_level_stats[Pfs.STATS.GOALS_REACHED].size() < leader_bolt_level_stats[Pfs.STATS.GOALS_REACHED].size():
				pulled_bolt_level_stats[Pfs.STATS.GOALS_REACHED] = leader_bolt_level_stats[Pfs.STATS.GOALS_REACHED]


func _get_bolt_pull_position(bolt_to_pull: Node2D): # temp ... Vechile class
	# na koncu izbrana pull pozicija:
	# - je na območju navigacije
	# - upošteva razdaljo do vodilnega
	# - se ne pokriva z drugim plejerjem
	#	printt ("current_pull_positions",current_pull_positions.size())
	if game_on:

		# pull pozicija brez omejitev
		var pull_position_distance_from_leader: float = bolt_to_pull.near_radius # pull razdalja od vodilnega plejerja
#		var pull_position_distance_from_leader_correction: float = bolt_to_pull.near_area_radius.get_node("BoltScale").rect_size.x * 2 # 18 ... 20 # pull razdalja od vodilnega plejerja glede na index med trenutno pulanimi
#		var pull_position_distance_from_leader_correction: float = bolt_to_pull.chassis.get_node("BoltScale").rect_size.x * 2 # 18 ... 20 # pull razdalja od vodilnega plejerja glede na index med trenutno pulanimi

		var vector_to_leading_player: Vector2 = camera_leader.global_position - bolt_to_pull.global_position
		var vector_to_pull_position: Vector2 = vector_to_leading_player - vector_to_leading_player.normalized() * pull_position_distance_from_leader
		var bolt_pull_position: Vector2 = bolt_to_pull.global_position + vector_to_pull_position

		# implementacija omejitev, da ni na steni ali elementu ali drugemu plejerju
		var navigation_position_as_pull_position: Vector2
		var available_navigation_pull_positions: Array

		# poiščem navigacijsko celico, ki je najbližje določeni pull poziciji
		for cell_position in navigation_positions:
			# prva nav celica v preverjanju se opredeli kot trenutno najbližja
			if navigation_position_as_pull_position == Vector2.ZERO:
				navigation_position_as_pull_position = cell_position
			# ostale nav celice ... če je boljša, jo določim za novo opredeljeno
			else:
				# preverim, če je bližja od trenutno opredeljene ... itak da je
				if cell_position.distance_to(bolt_pull_position) < navigation_position_as_pull_position.distance_to(bolt_pull_position):
					# pozicija je dovolj stran od vodilnega
					if cell_position.distance_to(camera_leader.global_position) > pull_position_distance_from_leader:
						# če je pozicija zasedena
						if current_pull_positions.has(cell_position):
							var pull_pos_index: int = current_pull_positions.find(cell_position)
							var corrected_pull_position = pull_position_distance_from_leader + pull_pos_index
							if cell_position.distance_to(camera_leader.global_position) > corrected_pull_position:
								navigation_position_as_pull_position = cell_position
						else: # če je poza zasedena dobim njen in dex med zasedenimi dodam korekcijo na zahtevani razdalji od vodilnega
							navigation_position_as_pull_position = cell_position

		current_pull_positions.append(navigation_position_as_pull_position) # OBS trenutno ne rabim

		return navigation_position_as_pull_position


# SPAWNING ---------------------------------------------------------------------------------------------


func _spawn_game_views():

	# debug ... ai solo postane plejer
	if get_tree().get_nodes_in_group(Rfs.group_players).empty():
		get_tree().get_nodes_in_group(Rfs.group_ai)[0].add_to_group(Rfs.group_players)

	# prvi view
	active_game_views[game_views_holder.get_child(0)] = get_tree().get_nodes_in_group(Rfs.group_players)[0]

	# prva kamera za vse plejerje
	for player_bolt in get_tree().get_nodes_in_group(Rfs.group_players):
		player_bolt.vehicle_camera = get_tree().get_nodes_in_group(Rfs.group_player_cameras)[0]

	if not Sts.all_bolts_on_screen_mode:

		# spawn xtra views
		for player_bolt in get_tree().get_nodes_in_group(Rfs.group_players):
			if not player_bolt == get_tree().get_nodes_in_group(Rfs.group_players)[0]:
				var new_game_view: ViewportContainer = GameView.instance()
				game_views_holder.add_child(new_game_view)
				active_game_views[new_game_view] = player_bolt
				player_bolt.vehicle_camera = new_game_view.get_node("Viewport/GameCamera")

		# viewport world
		var world_to_inherit: World2D = active_game_views.keys()[0].get_node("Viewport").world_2d
		var current_game_views: Dictionary = active_game_views
		for view_index in active_game_views.size():
			if view_index > 0:
				active_game_views.keys()[view_index].get_node("Viewport").world_2d = world_to_inherit

		# flow separation
		var v_sep: float = game_views_holder.get_constant("vseparation")
		var h_sep: float = game_views_holder.get_constant("hseparation")

		# view size
		var full_size: Vector2 = get_viewport_rect().size
		var view_tile: int = VIEW_TILE.ONE
		match get_tree().get_nodes_in_group(Rfs.group_players).size():
			1:
				view_tile = VIEW_TILE.ONE
			2:
				view_tile = VIEW_TILE.TWO_VER
				if view_tile == VIEW_TILE.TWO_VER:
					# view size
					active_game_views.keys()[0].get_node("Viewport").size = full_size * Vector2(0.5, 1)
					# adapt for separation
					active_game_views.keys()[0].get_node("Viewport").size.x -= h_sep/2
					active_game_views.keys()[1].get_node("Viewport").size = full_size * Vector2(0.5, 1)
					active_game_views.keys()[1].get_node("Viewport").size.x -= h_sep/2
			3:
				view_tile = VIEW_TILE.THREE_LEFT
				if view_tile == VIEW_TILE.THREE_LEFT:
					active_game_views.keys()[0].get_node("Viewport").size = full_size * Vector2(0.5, 1)
					active_game_views.keys()[0].get_node("Viewport").size.y -= v_sep/2
					active_game_views.keys()[1].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
					active_game_views.keys()[1].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
					active_game_views.keys()[2].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
					active_game_views.keys()[2].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
				elif view_tile == VIEW_TILE.THREE_RIGHT:
					active_game_views.keys()[0].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
					active_game_views.keys()[0].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
					active_game_views.keys()[1].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
					active_game_views.keys()[1].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
					active_game_views.keys()[2].get_node("Viewport").size = full_size * Vector2(0.5, 1)
					active_game_views.keys()[2].get_node("Viewport").size.y -= v_sep/2
			4:
				view_tile = VIEW_TILE.FOUR
				active_game_views.keys()[0].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
				active_game_views.keys()[0].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
				active_game_views.keys()[1].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
				active_game_views.keys()[1].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
				active_game_views.keys()[2].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
				active_game_views.keys()[2].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
				active_game_views.keys()[3].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
				active_game_views.keys()[3].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2


func _spawn_level(scene = preload("res://game/levels/LevelFirstDrive.tscn")):

	if current_level: # če level že obstaja, ga najprej moram zbrisat
		current_level.set_physics_process(false)
		current_level.queue_free()

	var new_level_key: int = Sts.current_game_levels[current_level_index]
	level_profile = Pfs.level_profiles[new_level_key]

	# spawn
	var level_spawn_parent: Node = game_views_holder.get_child(0).get_node("Viewport") # VP node
	var NewLevel: PackedScene = level_profile["level_scene"]
	var new_level = NewLevel.instance()
	level_spawn_parent.add_child(new_level)
	level_spawn_parent.move_child(new_level, 0)

	# setup
	new_level.connect("level_is_set", self, "_on_level_is_set") # nujno pred add child, ker ga level sproži že na ready
	for node_path in new_level.level_goals_paths:
		new_level.get_node(node_path).connect("reached_by", self, "_on_bolt_reached_goal")
		goals_to_reach.append(new_level.get_node(node_path))
	if new_level.level_finish_path:
		new_level.get_node(new_level.level_finish_path).connect("reached_by", self, "_on_finish_line_crossed")

	new_level.setup()

	current_level = new_level


func _spawn_bolt(bolt_driver_index: int, spawned_position_index: int):

#	var bolt_type: int = Pfs.driver_profiles[bolt_driver_index]["bolt_type"]
	var bolt_type: int = Pfs.VECHICLE.values()[0]


	# debug ... ai spawn
	var scene_name: String = "bolt_scene"
#	if Pfs.driver_profiles[bolt_driver_index]["controller_type"] == Pfs.CONTROLLER_TYPE.AI:
#		scene_name = "bolt_scene_ai"
	var NewBoltInstance: PackedScene = Pfs.bolt_profiles[bolt_type][scene_name]
#	if bolt_driver_index == 0:
	NewBoltInstance = Pfs.vechicle_profiles[bolt_type][scene_name]

	var new_bolt = NewBoltInstance.instance()
	new_bolt.driver_index = bolt_driver_index
	new_bolt.modulate.a = 0 # za intro
	new_bolt.rotation_degrees = current_level.level_start.rotation_degrees - 90 # ob rotaciji 0 je default je obrnjen navzgor
	new_bolt.global_position = start_bolt_position_nodes[spawned_position_index].global_position

	# profili ... iz njih podatke povleče sam na ready
	new_bolt.driver_profile = Pfs.driver_profiles[bolt_driver_index].duplicate()
	new_bolt.driver_stats = Pfs.start_bolt_stats.duplicate()
#	if bolt_driver_index == 0:
#		new_bolt.vehicle_profile = Pfs.vechicle_profiles[Pfs.VECHICLE.values()[0]].duplicate()
#	else:
	new_bolt.vehicle_profile = Pfs.vechicle_profiles[bolt_type].duplicate()

	Rfs.node_creation_parent.add_child(new_bolt)

	# ai navigation
	if Pfs.driver_profiles[bolt_driver_index]["driver_type"] == Pfs.DRIVER_TYPE.AI:
		new_bolt.controller.level_navigation = current_level.level_navigation
		self.connect("game_state_changed", new_bolt.controller, "_on_game_state_change") # _temp _on_game_state_change signal na ai
	# trackers
	if current_level.level_track:
		new_bolt.tracker = current_level.level_track.set_new_bolt_tracker(new_bolt)
	# goals
	new_bolt.controller.goals_to_reach = level_profile["level_goals"].duplicate()

	# signali
	new_bolt.connect("activity_changed", self, "_on_bolt_activity_change")
	new_bolt.connect("stat_changed", hud, "_on_bolt_stat_changed")

	# level stats
	level_stats[bolt_driver_index] = Pfs.start_bolt_level_stats.duplicate()
	level_stats[bolt_driver_index][Pfs.STATS.LAPS_FINISHED] = [] # prepišem array v slovarju, da je tudi ta unique
	level_stats[bolt_driver_index][Pfs.STATS.GOALS_REACHED] = []

	# hud stats
	hud.set_bolt_statbox(new_bolt, level_stats[bolt_driver_index])


func _spawn_random_pickables():

	if available_pickable_positions.empty():
		return

	if get_tree().get_nodes_in_group(Rfs.group_pickables).size() <= Sts.pickables_count_limit - 1:

		# žrebanje tipa
		var random_pickable_key = Pfs.pickable_profiles.keys().pick_random()
		var random_cell_position: Vector2 = navigation_positions.pick_random()
		current_level.spawn_pickable(random_cell_position, "random_pickable_key", random_pickable_key)

		# odstranim celico iz arraya tistih na voljo
		var random_cell_position_index: int = available_pickable_positions.find(random_cell_position)
		available_pickable_positions.remove(random_cell_position_index)

	# random timer reštart
	var random_pickable_spawn_time: int = [1, 2, 3].pick_random()
	yield(get_tree().create_timer(random_pickable_spawn_time), "timeout") # OPT ... uvedi node timer

	_spawn_random_pickables()


# UTILITI ---------------------------------------------------------------------------------------------


func _animate_day_night():

	var day_length: float = 10
	var day_start_direction: Vector2 = Vector2.LEFT

	var day_night_tween = get_tree().create_tween()
	for shadow in get_tree().get_nodes_in_group(Rfs.group_shadows):
		if shadow is Polygon2D:
			day_night_tween.parallel().tween_property(shadow, "shadow_rotation_deg", 0, day_length).from(-180).set_ease(Tween.EASE_IN_OUT)


func _sort_bolts_by_laps(bolt_1, bolt_2): # desc
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	var bolt_1_lap_count = level_stats[bolt_1.driver_index][Pfs.STATS.LAPS_FINISHED].size()
	var bolt_2_lap_count = level_stats[bolt_2.driver_index][Pfs.STATS.LAPS_FINISHED].size()
	if bolt_1_lap_count > bolt_2_lap_count:
	    return true
	return false


func _sort_trackers_by_offset(bolt_tracker_1, bolt_tracker_2):# desc
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	if bolt_tracker_1.offset > bolt_tracker_2.offset:
	    return true
	return false


func _sort_trackers_by_points(bolt_1, bolt_2):# desc
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	var bolt_1_points = bolt_1.driver_stats[Pfs.STATS.POINTS]
	var bolt_2_points = bolt_2.driver_stats[Pfs.STATS.POINTS]
	if bolt_1_points > bolt_2_points:
	    return true
	return false


func _sort_trackers_by_speed(bolt_1, bolt_2): # desc ... ne uporabljam

	if bolt_1.velocity.length() > bolt_2.velocity.length():
	    return true
	return false


func _change_camera_leader(new_camera_leader: Node2D):

	if new_camera_leader == camera_leader:
		pass
	elif new_camera_leader == null:
		pass
	else:
		camera_leader = new_camera_leader
		# zaenrkat samo cam target
		if Sts.all_bolts_on_screen_mode:
			get_tree().set_group(Rfs.group_player_cameras, "follow_target", camera_leader)


# SIGNALI ----------------------------------------------------------------------------------------------------


func _on_bolt_reached_goal(current_goal: Node, bolt_reaching: Node2D): # level poveže  # temp ... Vechile class
	# reagirata bolt in igra

	if game_on:

		# če je zaporedje, more bit goal enak prvemu v vrsti
		if not current_level.reach_goals_in_sequence or current_goal == bolt_reaching.goals_to_reach[0]:

			# dodam med dosežene
			var bolt_level_stats: Dictionary = level_stats[bolt_reaching.driver_index]
			bolt_level_stats[Pfs.STATS.GOALS_REACHED].append(current_goal)

			# next ...
			var reached_goals_count: int = bolt_level_stats[Pfs.STATS.GOALS_REACHED].size()
			if reached_goals_count < level_profile["level_goals"].size():
				bolt_reaching.controller.goal_reached(current_goal)
				Rfs.sound_manager.play_sfx("little_horn")
			elif current_level.level_finish:
				bolt_reaching.controller.goal_reached(current_goal, current_level.level_finish)
				Rfs.sound_manager.play_sfx("little_horn")
			else:
				bolt_reaching.controller.goal_reached(current_goal)
				Rfs.sound_manager.play_sfx("finish_horn")
				bolts_finished.append(bolt_reaching)


func _on_finish_line_crossed(bolt_across: Node2D): # sproži finish line  # temp ... Vechile class

	if not game_on:
		return

	var bolt_level_data: Dictionary = level_stats[bolt_across.driver_index]
	var bolt_goals_reached: Array = bolt_level_data[Pfs.STATS.GOALS_REACHED].duplicate()

	# ne registriram, če niso izpolnjeni pogoji v krogu oz dirki
#	printt("stats", bolt_level_data[Pfs.STATS.GOALS_REACHED])
#	printt("level_goals", bolt_goals_reached, level_profile["level_goals"])
	if level_profile["level_goals"].size() > 0:
		if not bolt_goals_reached == level_profile["level_goals"]:
			return


		# najprej preverjam, če level_finish še edini cilj ali pa ni nobenega
#		var goals_reached_size: int = bolt_level_data[Pfs.STATS.GOALS_REACHED].size()
#		printt ("finish_crosed", goals_reached_size)

#		if bolt_level_data[Pfs.STATS.GOALS_REACHED] == level_profile["level_goals"]:


	# stat level time
	print("SDFSDFDFDFSsdf")
#	var current_level_time: float = hud.game_timer.game_time_hunds
	var prev_lap_level_time: float = bolt_level_data[Pfs.STATS.LEVEL_TIME]
	bolt_level_data[Pfs.STATS.LEVEL_TIME] = hud.game_timer.game_time_hunds

	var has_finished_level: bool = false
	# WITH LAPS ... lap finished če so vsi čekpointi
	if level_profile["lap_limit"] > 1:
		var lap_time: float = bolt_level_data[Pfs.STATS.LEVEL_TIME] - prev_lap_level_time
		bolt_level_data[Pfs.STATS.LAPS_FINISHED].append(lap_time)
		if bolt_level_data[Pfs.STATS.LAPS_FINISHED].size() >= level_profile["lap_limit"]:
			has_finished_level = true
	else:
		has_finished_level = true

	if has_finished_level:
		var drive_out_time: float = 1
		var drive_out_vector: Vector2 = current_level.drive_out_position.rotated(current_level.level_finish.global_rotation)
		bolt_across.drive_out(drive_out_time, drive_out_vector)
		bolts_finished.append(bolt_across)
		Rfs.sound_manager.play_sfx("finish_horn")
	else:
		Rfs.sound_manager.play_sfx("little_horn")


	# hud update
	for stat_key in [Pfs.STATS.LAPS_FINISHED, Pfs.STATS.BEST_LAP_TIME, Pfs.STATS.LEVEL_TIME, Pfs.STATS.GOALS_REACHED]:
		hud.update_bolt_level_stats(bolt_across.driver_index, stat_key, bolt_level_data[stat_key])


func _on_level_is_set(level_type: int, start_positions: Array, camera_nodes: Array, nav_positions: Array, level_goals: Array):

	level_profile["level_type"] = level_type
	level_profile["level_goals"] = level_goals.duplicate()
	# navigacija za AI
	navigation_positions = nav_positions
	# random pickable pozicije
	available_pickable_positions = nav_positions.duplicate()
	# spawn poz
	start_bolt_position_nodes = start_positions.duplicate()
	# kamera
	var camera_limits: Control = camera_nodes[0]
	var camera_start_position: Vector2 = camera_nodes[1].global_position
	get_tree().call_group(Rfs.group_player_cameras, "setup", camera_limits, camera_start_position)

	printt("GM level goals", level_profile["level_goals"])


func _on_body_exited_playing_field(body: Node) -> void:

	#	if body.is_in_group(Rfs.group_bolts):
	if body.is_in_group(Rfs.group_players):
		_pull_bolt_on_field(body)
	elif body is Projectile:
		body.on_out_of_playing_field() # ta funkcija zakasni učinek


func _on_bolt_activity_change(changed_bolt: Node2D): # temp ... Vechile class

	# preverja, če je še kakšen player aktiven ... za GO
	if changed_bolt.is_active == false:
		for bolt in bolts_in_game:
			if bolt.is_active and bolt.is_in_group(Rfs.group_players):
				return
		end_level()
