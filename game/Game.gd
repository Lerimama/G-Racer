extends Node2D
class_name Game


signal game_stage_changed (game_manager)


enum GAME_STAGE {LOADING, SETUP, READY, INTRO, FAST_START, PLAYING, PAUSED, END_SUCCESS, END_FAIL}
var game_stage: int = GAME_STAGE.LOADING setget _change_game_stage

export (Array, NodePath) var main_signal_connecting_paths: Array = []
var main_signal_connecting_nodes: Array = []

enum VIEW_TILE {ONE, TWO_VER, THREE_LEFT, THREE_RIGHT, FOUR }

var game_on: bool
var fast_start_window_on: bool = false # agent ga čekira in reagira
var goals_to_reach: Array = []
var game_views: Dictionary = {}

# agents
var activated_drivers: Array # naslednji leveli se tole adaptira, glede na to kdo je še v igri
var agents_in_game: Array # live data ... tekom igre so v ranked zaporedju (glede na distanco)
var players_in_game: Array # live data ... tekom igre so v ranked zaporedju (glede na distanco)
var ais_in_game: Array # live data ... tekom igre so v ranked zaporedju (glede na distanco)
var agents_finished: Array # agenti v cilju
var players_qualified: Array # obstaja za prenos med leveloma
var camera_leader: Node2D setget _change_camera_leader # trenutno vodilni igralec ... lahko tudi kakšen drug pogoj

# level
var current_level: Level
var level_stats: Dictionary = {} # napolnem na spawn agent
var level_profile: Dictionary # set_level seta iz profilov
var current_level_index = 0
var available_pickable_positions: Array # za random spawn
var navigation_positions: Array # pozicije vseh navigation tiletov
var current_pull_positions: Array # že zasedene pozicije za preventanje nalaganja agento druga na drugega
var start_position_nodes: Array # dobi od levela

# shadows
onready var game_shadows_length_factor: float = Sts.game_shadows_length_factor # set_game seta iz profilov
onready var game_shadows_alpha: float = Sts.game_shadows_alpha # set_game seta iz profilov
onready var game_shadows_color: Color = Sts.game_shadows_color # set_game seta iz profilov
onready var game_shadows_rotation_deg: float = Sts.game_shadows_rotation_deg # set_game seta iz profilov

onready var game_views_holder: VFlowContainer = $GameViewFlow
onready var GameView: PackedScene = preload("res://game/GameView.tscn")
onready var hud: Hud = $Gui/Hud


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

	for path in main_signal_connecting_paths:
		main_signal_connecting_nodes.append(get_node(path))

	call_deferred("_set_game")


func _process(delta: float) -> void:

	# beleženje prisotnosti
	agents_in_game = get_tree().get_nodes_in_group(Rfs.group_agents)
	for agent in get_tree().get_nodes_in_group(Rfs.group_agents):
		if is_instance_valid(agent):
			if get_tree().get_nodes_in_group(Rfs.group_players).has(agent):
				if not players_in_game.has(agent):
					players_in_game.append(agent)
			if get_tree().get_nodes_in_group(Rfs.group_ai).has(agent):
				if not ais_in_game.has(agent):
					ais_in_game.append(agent)
		else:
			agents_in_game.erase(agent)

	_update_ranking()

	# camera leader
	for agent in agents_in_game:
		if agent.is_in_group(Rfs.group_players) and agent.is_active:
			self.camera_leader = agent
			break
		self.camera_leader = null


func _set_game():

	self.game_stage = GAME_STAGE.SETUP

	_spawn_level()

	yield(get_tree(), "idle_frame") # zazih ... na levelu bazira vse ostalo

	# camera start positions
	get_tree().set_group(Rfs.group_player_cameras, "follow_target", current_level.start_camera_position_node)

	# drivers on level start
	if current_level_index == 0: # prvi level so aktivirani dodani v meniju
		activated_drivers = Sts.drivers_on_game_start
	else: # drugi leveli dodam kvalificirane driver_id
		for agent in players_qualified:
			activated_drivers.append(agent.driver_index)
	players_qualified.clear()
	# spawn drivers ... po vrsti aktivacije
	var spawned_position_index = 0
	for driver_index in activated_drivers: # so v ranking zaporedju
		_spawn_agent(driver_index, spawned_position_index) # scena, pozicija, profile id (barva, ...)
		spawned_position_index += 1


	yield(get_tree(), "idle_frame")

	# camera
	if Sts.all_agents_on_screen_mode:
		var main_camera: Camera2D = get_tree().get_nodes_in_group(Rfs.group_player_cameras)[0]
		# prižgem playing field
		main_camera.playing_field.connect( "body_exited_playing_field", self, "_on_body_exited_playing_field")
		if level_profile["level_type"] == Pfs.BASE_TYPE.TIMED:
			main_camera.playing_field.enable_playing_field(true)
		else:
			main_camera.playing_field.enable_playing_field(true, true) # z edgom
		# pripišem plejer kamere
		for player_agent in get_tree().get_nodes_in_group(Rfs.group_players):
			player_agent.agent_camera = main_camera
		# set default view dodam med game viewe
		game_views[game_views_holder.get_child(0)] = get_tree().get_nodes_in_group(Rfs.group_players)[0]
		_set_game_views(1)
	else:
		# debug ... ai solo postane plejer
		if get_tree().get_nodes_in_group(Rfs.group_players).empty():
			get_tree().get_nodes_in_group(Rfs.group_ai)[0].add_to_group(Rfs.group_players)

		# default view dodam med game viewe
		game_views[game_views_holder.get_child(0)] = get_tree().get_nodes_in_group(Rfs.group_players)[0]
		# pripišem default kamero
		var player_agent_in_first_view: Agent = game_views.values().front()
		player_agent_in_first_view.agent_camera = get_tree().get_nodes_in_group(Rfs.group_player_cameras)[0]
		# ugasnem playing field
		get_tree().get_nodes_in_group(Rfs.group_player_cameras)[0].get_node("PlayingField").enable_playing_field(false)
		# spawnam viewe še za preostale plejerje
		_spawn_new_game_views()
		# set views
		var players_count: int = get_tree().get_nodes_in_group(Rfs.group_players).size()
		_set_game_views(players_count)

#		yield(get_tree(), "idle_frame") # ker je tudi znotraj _set_game_views

	self.game_stage = GAME_STAGE.READY

#	hud.set_hud(level_profile, game_views) # kliče GM

	Rfs.ultimate_popup.hide() # skrijem pregame

	_game_intro()


func _game_intro():

	self.game_stage = GAME_STAGE.INTRO

	# pokažem sceno
	var fade_time: float = 1
	var setup_delay: float = 0 # delay, da se kamera naštima
	var fade_tween = get_tree().create_tween()
#	fade_tween.tween_property(get_parent(), "modulate", Color.white, fade_time).from(Color.black).set_delay(setup_delay)
	fade_tween.tween_property(self, "modulate", Color.white, fade_time).from(Color.black).set_delay(setup_delay)
	yield(fade_tween, "finished")

	# agents drive-in
	var drive_in_time: float = 2
	for agent in agents_in_game:
		var drive_in_vector: Vector2 = Vector2.ZERO
		if current_level.drive_in_position:
			drive_in_vector = current_level.drive_in_position.rotated(current_level.level_start.global_rotation)
		agent.drive_in(drive_in_vector, drive_in_time)

	# počakam, da odpelje
	yield(get_tree().create_timer(drive_in_time),"timeout")

	_start_game()


func _start_game():

	# start countdown
	if Sts.start_countdown and level_profile["level_type"] == Pfs.BASE_TYPE.TIMED:
		current_level.start_lights.start_countdown() # če je skrit, pošlje signal takoj
		yield(current_level.start_lights, "countdown_finished")

	# fast start
	game_on = true
	self.game_stage = GAME_STAGE.FAST_START
	yield(get_tree().create_timer(Sts.fast_start_window_time), "timeout")
	self.game_stage = GAME_STAGE.PLAYING

	Rfs.sound_manager.play_music()


func _change_game_stage(new_game_stage: int):
	print("GAME_STAGE: ", GAME_STAGE.keys()[new_game_stage])

#	if not new_game_stage == game_stage:
	game_stage = new_game_stage
#	call_deferred("_rect_to_change")
	_rect_to_change()


func _rect_to_change():

	match game_stage:
		# najprej povežem s s signalom
		GAME_STAGE.SETUP:
			for connecting_node in main_signal_connecting_nodes:
				if not self.is_connected("game_stage_changed", connecting_node, "_on_game_stage_changed"):
					self.connect("game_stage_changed", connecting_node, "_on_game_stage_changed")
		GAME_STAGE.READY:
			emit_signal("game_stage_changed", self)
		GAME_STAGE.FAST_START: # samo kar ni samo na štartu
			emit_signal("game_stage_changed", self)
		GAME_STAGE.PLAYING: # samo kar ni samo na štartu
			if level_profile["level_type"] == Pfs.BASE_TYPE.UNTIMED: # zaženem vsakič, tudi po pavzi
				_spawn_random_pickables()
			emit_signal("game_stage_changed", self)
		GAME_STAGE.PAUSED:
			emit_signal("game_stage_changed", self)
		GAME_STAGE.END_SUCCESS, GAME_STAGE.END_FAIL:
			game_on = false
			get_tree().set_group(Rfs.group_player_cameras, "follow_target", null)
			emit_signal("game_stage_changed", self)
#			yield(get_tree().create_timer(Sts.get_it_time), "timeout")
#			# ustavi elemente
#				# best lap stats reset
#				# looping sounds stop
#				# navigacija AI
#				# kvefri elementov, ki so v areni
			Rfs.sound_manager.stop_music()
			var bus_index: int = AudioServer.get_bus_index("GameSfx")
			AudioServer.set_bus_mute(bus_index, true)
		_:
			emit_signal("game_stage_changed", self)


func set_next_level():

	current_level_index += 1

	agents_finished = [] # resetiram šele tukaj, ker ga rabim tudi v GO

	# unmute sfx
	if not Rfs.sound_manager.sfx_set_to_mute:
		var bus_index: int = AudioServer.get_bus_index("GameSfx")
		AudioServer.set_bus_mute(bus_index, false)

	# zbrišem vse otroke v NCP (agenti, orožja, efekti, ...)
	var all_children: Array = Rfs.node_creation_parent.get_children()
	for child in all_children:
		child.queue_free()

	# reset level values
	self.camera_leader = null # trenutno vodilni igralec (rabim za camera target in pull target)

	call_deferred("_set_game")


func _set_game_views(players_count: int = 1):

	# flow separation
	var v_sep: float = game_views_holder.get_constant("vseparation")
	var h_sep: float = game_views_holder.get_constant("hseparation")

	# view size
	var full_size: Vector2 = get_viewport_rect().size
	var view_tile: int = VIEW_TILE.ONE
	match players_count:
		1:
			view_tile = VIEW_TILE.ONE
			game_views.keys()[0].get_node("Viewport").size = full_size
		2:
			view_tile = VIEW_TILE.TWO_VER
			if view_tile == VIEW_TILE.TWO_VER:
				# view size
				game_views.keys()[0].get_node("Viewport").size = full_size * Vector2(0.5, 1)
				game_views.keys()[1].get_node("Viewport").size = full_size * Vector2(0.5, 1)
				# adapt for separation
				game_views.keys()[0].get_node("Viewport").size.x -= h_sep/2
				game_views.keys()[1].get_node("Viewport").size.x -= h_sep/2
		3:
			view_tile = VIEW_TILE.THREE_LEFT
			if view_tile == VIEW_TILE.THREE_LEFT:
				game_views.keys()[0].get_node("Viewport").size = full_size * Vector2(0.5, 1)
				game_views.keys()[1].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
				game_views.keys()[2].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
				game_views.keys()[0].get_node("Viewport").size.y -= v_sep/2
				game_views.keys()[1].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
				game_views.keys()[2].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
			elif view_tile == VIEW_TILE.THREE_RIGHT:
				game_views.keys()[0].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
				game_views.keys()[2].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
				game_views.keys()[2].get_node("Viewport").size = full_size * Vector2(0.5, 1)
				game_views.keys()[0].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
				game_views.keys()[1].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
				game_views.keys()[2].get_node("Viewport").size.y -= v_sep/2
			game_views.keys()[2].get_node("Viewport").size.y -= v_sep/2
		4:
			view_tile = VIEW_TILE.FOUR
			game_views.keys()[0].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
			game_views.keys()[1].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
			game_views.keys()[3].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
			game_views.keys()[2].get_node("Viewport").size = full_size * Vector2(0.5, 0.5)
			game_views.keys()[0].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
			game_views.keys()[1].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
			game_views.keys()[2].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2
			game_views.keys()[3].get_node("Viewport").size -= Vector2(h_sep, v_sep)/2


# TRACKING ---------------------------------------------------------------------------------------------


func _update_ranking():
	# najprej po poziciji znotraj kroga, potem po številu krogov

	if level_profile["level_type"] == Pfs.BASE_TYPE.TIMED and current_level.level_track:
		var agents_ranked: Array = []
		var all_agent_trackers: Array = current_level.level_track.get_children()
		all_agent_trackers.sort_custom(self, "_sort_trackers_by_offset")
		for agent_tracker in all_agent_trackers:
			agents_ranked.append(agent_tracker.tracking_target)
		if agents_in_game.size() > 1:
			agents_ranked.sort_custom(self, "_sort_agents_by_laps")
		agents_in_game = agents_ranked
	else:
		if agents_in_game.size() > 1:
			agents_in_game.sort_custom(self, "_sort_trackers_by_points")

	for agent in agents_in_game:
		var current_agent_rank: int = agents_in_game.find(agent) + 1
		if not current_agent_rank == level_stats[agent.driver_index][Pfs.STATS.LEVEL_RANK]:
			level_stats[agent.driver_index][Pfs.STATS.LEVEL_RANK] = current_agent_rank
			hud.update_agent_level_stats(agent.driver_index, Pfs.STATS.LEVEL_RANK, current_agent_rank) # OPT prepogosto


func _pull_agent_on_field(agent_to_pull: Node2D): # temp ... Vechile class

	if game_on and Sts.all_agents_on_screen_mode:

		if agent_to_pull.is_active:

			var agent_pull_position: Vector2 = _get_agent_pull_position(agent_to_pull)
			agent_to_pull.call_deferred("pull_on_screen", agent_pull_position)

			# če preskoči ciljno črto jo dodaj, če jo je leader prevozil
			var pulled_agent_level_stats: Dictionary = level_stats[agent_to_pull.driver_index]
			var leader_agent_level_stats: Dictionary = level_stats[camera_leader.driver_index]

			# poenotim level goals/laps stats ... če ni pulan točno preko cilja, pa bi moral bit
			if pulled_agent_level_stats[Pfs.STATS.LAPS_FINISHED].size() < leader_agent_level_stats[Pfs.STATS.LAPS_FINISHED].size():
				pulled_agent_level_stats[Pfs.STATS.LAPS_FINISHED] = leader_agent_level_stats[Pfs.STATS.LAPS_FINISHED]
			# mogoče tega spodej nebi mel ... bomo videlo po testu
			if pulled_agent_level_stats[Pfs.STATS.GOALS_REACHED].size() < leader_agent_level_stats[Pfs.STATS.GOALS_REACHED].size():
				pulled_agent_level_stats[Pfs.STATS.GOALS_REACHED] = leader_agent_level_stats[Pfs.STATS.GOALS_REACHED]


func _get_agent_pull_position(agent_to_pull: Node2D): # temp ... Vechile class
	# na koncu izbrana pull pozicija:
	# - je na območju navigacije
	# - upošteva razdaljo do vodilnega
	# - se ne pokriva z drugim plejerjem
	#	printt ("current_pull_positions",current_pull_positions.size())
	if game_on:

		# pull pozicija brez omejitev
		var pull_position_distance_from_leader: float = agent_to_pull.near_radius # pull razdalja od vodilnega plejerja

		var vector_to_leading_player: Vector2 = camera_leader.global_position - agent_to_pull.global_position
		var vector_to_pull_position: Vector2 = vector_to_leading_player - vector_to_leading_player.normalized() * pull_position_distance_from_leader
		var agent_pull_position: Vector2 = agent_to_pull.global_position + vector_to_pull_position

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
				if cell_position.distance_to(agent_pull_position) < navigation_position_as_pull_position.distance_to(agent_pull_position):
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


func _spawn_new_game_views():

	for player_agent in get_tree().get_nodes_in_group(Rfs.group_players):
		# def view je že setan
		if not player_agent == get_tree().get_nodes_in_group(Rfs.group_players)[0]:
			var new_game_view: ViewportContainer = GameView.instance()
			game_views_holder.add_child(new_game_view)
			game_views[new_game_view] = player_agent
			player_agent.agent_camera = new_game_view.get_node("Viewport/GameCamera")

	# viewport world
	var world_to_inherit: World2D = game_views.keys()[0].get_node("Viewport").world_2d
	var current_game_views: Dictionary = game_views
	for view_index in game_views.size():
		if view_index > 0:
			game_views.keys()[view_index].get_node("Viewport").world_2d = world_to_inherit


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
		new_level.get_node(node_path).connect("reached_by", self, "_on_agent_reached_goal")
		goals_to_reach.append(new_level.get_node(node_path))
	if new_level.level_finish_path:
		new_level.get_node(new_level.level_finish_path).connect("reached_by", self, "_on_finish_line_crossed")

	new_level.setup()

	current_level = new_level


func _spawn_agent(agent_driver_index: int, spawned_position_index: int):

	var scene_name: String = "agent_scene"
	var agent_type: int = Pfs.AGENT.values()[0]
	var NewAgentInstance: PackedScene = Pfs.agent_profiles[agent_type][scene_name]

	var new_agent = NewAgentInstance.instance()
	new_agent.driver_index = agent_driver_index
	new_agent.modulate.a = 0 # za intro
	new_agent.rotation_degrees = current_level.level_start.rotation_degrees - 90 # ob rotaciji 0 je default je obrnjen navzgor
	new_agent.global_position = start_position_nodes[spawned_position_index].global_position

	# profili ... iz njih podatke povleče sam na rea dy
	new_agent.driver_profile = Pfs.driver_profiles[agent_driver_index].duplicate()
	new_agent.driver_stats = Pfs.start_agent_stats.duplicate()
	new_agent.agent_profile = Pfs.agent_profiles[agent_type].duplicate()

	Rfs.node_creation_parent.add_child(new_agent)

	# ai navigation
	if Pfs.driver_profiles[agent_driver_index]["driver_type"] == Pfs.DRIVER_TYPE.AI:
		new_agent.controller.level_navigation = current_level.level_navigation
	# trackers
	if current_level.level_track:
		new_agent.tracker = current_level.level_track.set_new_tracker(new_agent)
	# goals
	new_agent.controller.goals_to_reach = level_profile["level_goals"].duplicate()
	# level stats
	level_stats[agent_driver_index] = Pfs.start_gent_level_stats.duplicate()
	level_stats[agent_driver_index][Pfs.STATS.LAPS_FINISHED] = [] # prepišem array v slovarju, da je tudi ta unique
	level_stats[agent_driver_index][Pfs.STATS.GOALS_REACHED] = []

	# connect
	self.connect("game_stage_changed", new_agent.controller, "_on_game_stage_change")
	new_agent.connect("activity_changed", self, "_on_agent_activity_change")
	new_agent.connect("stat_changed", hud, "_on_agent_stat_changed")


func _spawn_random_pickables():

	if game_stage == GAME_STAGE.PLAYING:

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


func _sort_agents_by_laps(agent_1, agent_2): # desc
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	var agent_1_lap_count = level_stats[agent_1.driver_index][Pfs.STATS.LAPS_FINISHED].size()
	var agent_2_lap_count = level_stats[agent_2.driver_index][Pfs.STATS.LAPS_FINISHED].size()
	if agent_1_lap_count > agent_2_lap_count:
	    return true
	return false


func _sort_trackers_by_offset(agent_tracker_1, agent_tracker_2):# desc
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	if agent_tracker_1.offset > agent_tracker_2.offset:
	    return true
	return false


func _sort_trackers_by_points(agent_1, agent_2):# desc
	# For two elements a and b, if the given method returns true, element b will be after element a in the array.

	var agent_1_points = agent_1.driver_stats[Pfs.STATS.POINTS]
	var agent_2_points = agent_2.driver_stats[Pfs.STATS.POINTS]
	if agent_1_points > agent_2_points:
	    return true
	return false


func _sort_trackers_by_speed(agent_1, agent_2): # desc ... ne uporabljam

	if agent_1.velocity.length() > agent_2.velocity.length():
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
		if Sts.all_agents_on_screen_mode:
			get_tree().set_group(Rfs.group_player_cameras, "follow_target", camera_leader)


# SIGNALI ----------------------------------------------------------------------------------------------------


func _on_fx_finished(finished_fx: Node): # Node, ker je lahko audio

	if is_instance_valid(finished_fx):
		finished_fx.queue_free()


func _on_agent_reached_goal(current_goal: Node, agent_reaching: Node2D): # level poveže  # temp ... Vechile class
	# reagirata agent in igra

	if game_on:

		# če je zaporedje, more bit goal enak prvemu v vrsti
		if not current_level.reach_goals_in_sequence or current_goal == agent_reaching.goals_to_reach[0]:

			# dodam med dosežene
			var agent_level_stats: Dictionary = level_stats[agent_reaching.driver_index]
			agent_level_stats[Pfs.STATS.GOALS_REACHED].append(current_goal)

			# next ...
			var reached_goals_count: int = agent_level_stats[Pfs.STATS.GOALS_REACHED].size()
			if reached_goals_count < level_profile["level_goals"].size():
				agent_reaching.controller.goal_reached(current_goal)
				Rfs.sound_manager.play_sfx("little_horn")
			elif current_level.level_finish:
				agent_reaching.controller.goal_reached(current_goal, current_level.level_finish)
				Rfs.sound_manager.play_sfx("little_horn")
			else:
				agent_reaching.controller.goal_reached(current_goal)
				Rfs.sound_manager.play_sfx("finish_horn")
				agents_finished.append(agent_reaching)

		_check_for_game_end()


func _on_finish_line_crossed(agent_across: Node2D): # sproži finish line  # temp ... Vechile class

	if game_on:

		var agent_level_data: Dictionary = level_stats[agent_across.driver_index]
		var agent_goals_reached: Array = agent_level_data[Pfs.STATS.GOALS_REACHED].duplicate()

		# ne registriram, če niso izpolnjeni pogoji v krogu oz dirki
		if level_profile["level_goals"].empty() or agent_goals_reached == level_profile["level_goals"]:
#		if level_profile["level_goals"].size() > 0:
#			if not agent_goals_reached == level_profile["level_goals"]:
#				return

			# stat level time
			var prev_lap_level_time: float = agent_level_data[Pfs.STATS.LEVEL_TIME]
			agent_level_data[Pfs.STATS.LEVEL_TIME] = hud.game_timer.game_time_hunds

			var has_finished_level: bool = false
			# WITH LAPS ... lap finished če so vsi čekpointi
			if level_profile["lap_limit"] > 1:
				var lap_time: float = agent_level_data[Pfs.STATS.LEVEL_TIME] - prev_lap_level_time
				agent_level_data[Pfs.STATS.LAPS_FINISHED].append(lap_time)
				if agent_level_data[Pfs.STATS.LAPS_FINISHED].size() >= level_profile["lap_limit"]:
					has_finished_level = true
			else:
				has_finished_level = true

			if has_finished_level:
				var drive_out_time: float = 1
				var drive_out_vector: Vector2 = Vector2.ZERO
				if current_level.drive_out_position:
					drive_out_vector = current_level.drive_out_position.rotated(current_level.level_finish.global_rotation)
				agent_across.drive_out(drive_out_vector, drive_out_time)
				agents_finished.append(agent_across)
				Rfs.sound_manager.play_sfx("finish_horn")
			else:
				Rfs.sound_manager.play_sfx("little_horn")


			# hud update
			for stat_key in [Pfs.STATS.LAPS_FINISHED, Pfs.STATS.BEST_LAP_TIME, Pfs.STATS.LEVEL_TIME, Pfs.STATS.GOALS_REACHED]:
				hud.update_agent_level_stats(agent_across.driver_index, stat_key, agent_level_data[stat_key])

			_check_for_game_end()


func _check_for_game_end():
	# igre je konec, ko so v cilju vsi plejerji, ki so še aktivni
	# SUCCES je, če je vsaj en plejer v cilju
	# FAIL je če ni nobenega

	var all_players_finished_or_deactivated: bool = true

	# preverim, če kakšen plejer še dirka
	for player in players_in_game:
		if player.is_active and not agents_finished.has(player):
			all_players_finished_or_deactivated = false
			break

	# če je konec, preverim succes
	var is_success: bool = false
	if all_players_finished_or_deactivated:
		for player in players_in_game:
			if agents_finished.has(player):
				players_qualified.append(player) # temp qualif
				is_success = true
		# apliciram stage ... pošlje signal
		if is_success:
			self.game_stage = GAME_STAGE.END_SUCCESS
		else:
			self.game_stage = GAME_STAGE.END_FAIL


func _on_level_is_set(level_type: int, start_positions: Array, camera_nodes: Array, nav_positions: Array, level_goals: Array):

	level_profile["level_type"] = level_type
	level_profile["level_goals"] = level_goals.duplicate()
	# navigacija za AI
	navigation_positions = nav_positions
	# random pickable pozicije
	available_pickable_positions = nav_positions.duplicate()
	# spawn poz
	start_position_nodes = start_positions.duplicate()
	# kamera
	var camera_limits: Control = camera_nodes[0]
	var camera_start_position: Vector2 = camera_nodes[1].global_position
	get_tree().call_group(Rfs.group_player_cameras, "set_camera", camera_limits, camera_start_position)

	#	printt("GM level goals", level_profile["level_goals"])


func _on_agent_activity_change(changed_agent: Node2D): # temp ... Vechile class

	# preverja, če je še kakšen player aktiven ... za GO
	if changed_agent.is_active == false:

		if Sts.hide_view_on_player_deactivated and not Sts.all_agents_on_screen_mode: # ne uporabljam, ker ne smem zbrisat original viewa
			# skrijem view
			var hide_view_time: float
			yield(get_tree().create_timer(Sts.get_it_time), "timeout")
			var removed_game_view: ViewportContainer = game_views.find_key(changed_agent)
			# odstranim, če ni zadnji view
			if removed_game_view and game_views.size() > 1:
				removed_game_view.queue_free()
				game_views.erase(removed_game_view)
				# setam preostale
				_set_game_views(game_views.size())
				# odstranim imitatorja ... more bit za setanje game_views
				hud.agent_huds_holder.remove_view_imitator(game_views)

		# preverim, če je bil zadnji plejer da končam igro ... za primer, če ni nobe
		if game_stage == GAME_STAGE.PLAYING:
			var still_playing: bool = false
			for player in players_in_game:
				if player.is_active:
					still_playing = true
			if not still_playing:
				self.game_stage = GAME_STAGE.END_FAIL
				# _on_change preverja, če je igra že končana (tole ne poveozi morebitnega uspeha


func _on_body_exited_playing_field(body: Node) -> void:

	#	if body.is_in_group(Rfs.group_agents):
	if body.is_in_group(Rfs.group_players):
		_pull_agent_on_field(body)
	elif body is Projectile:
		body.on_out_of_playing_field() # ta funkcija zakasni učinek

