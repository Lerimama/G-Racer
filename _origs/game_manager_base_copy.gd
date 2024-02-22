extends Node

# original kopija class_name

# default game manager
# tutorial GM ima drugače
# scroller GM ima drugače
# sprinter GM ima drugače
# cleaner GM ima drugače

signal all_strays_died # signal za sebe, počaka, da se vsi kvefrijajo

enum GameoverReason {LIFE, TIME, CLEANED}

var game_on: bool = false
var show_position_indicators: bool

# players
var spawned_player_index: int = 0
var player_start_positions: Array
var start_players_count: int

# strays
var strays_shown: Array = []
var strays_in_game_count: int setget _change_strays_in_game_count # spremlja spremembo količine aktivnih in uničenih straysov
var strays_cleaned_count: int # za statistiko na hudu
var all_strays_died_alowed: bool = false # za omejevnje signala iz FP

# tilemap data
var cell_size_x: int # napolne se na koncu setanju tilemapa
var random_spawn_positions: Array
var required_spawn_positions: Array

# scroller
var lines_scroll_counter: int = 0 
var stray_spawning_round: int = 0
var level_stage_count: int = 1

onready var game_settings: Dictionary = Profiles.game_settings # ga med igro ne spreminjaš
onready var game_data: Dictionary = Profiles.current_game_data # .duplicate() # duplikat default profila, ker ga me igro spreminjaš
onready var spectrum_rect: TextureRect = $Spectrum
onready var spectrum_gradient: TextureRect = $SpectrumGradient
onready var StrayPixel: PackedScene = preload("res://game/pixel/stray_class.tscn")
onready var PlayerPixel: PackedScene = preload("res://game/pixel/player_class.tscn")


func _ready() -> void:
	
	Global.game_manager = self
	randomize()
	
func _process(delta: float) -> void:
	
	if get_tree().get_nodes_in_group(Global.group_strays).empty() and all_strays_died_alowed:
		all_strays_died_alowed = false
		emit_signal("all_strays_died")
	
	# position indicators	
	if Global.strays_on_screen.size() <= game_settings["show_position_indicators_stray_count"] and game_settings["position_indicators_mode"]:
		show_position_indicators = true
	else:
		show_position_indicators = false
	
	
# GAME LOOP ----------------------------------------------------------------------------------


func set_game(): 
	
	if game_data["game"] == Profiles.Games.SCROLLER:
		set_scrolling_stage_indicator()
	
	# set_players() # kliče M (main.gd), da je plejer viden že na fejdin
	
	# player intro animacija
	var signaling_player: KinematicBody2D
	for player in get_tree().get_nodes_in_group(Global.group_players):
		player.animation_player.play("lose_white_on_start")
		signaling_player = player # da se zgodi na obeh plejerjih istočasno
	yield(signaling_player, "player_pixel_set") # javi player na koncu intro animacije
		
	if not game_data["game"] == Profiles.Games.TUTORIAL: 
		set_strays()
		yield(get_tree().create_timer(1), "timeout") # da si plejer ogleda
	
	Global.hud.slide_in(start_players_count)
	yield(Global.start_countdown, "countdown_finished") # sproži ga hud po slide-inu
	
	start_game()
	
	
func start_game():
	
	if game_data["game"] == Profiles.Games.TUTORIAL:
		Global.tutorial_gui.open_tutorial()
	else:
		Global.hud.game_timer.start_timer()
		Global.sound_manager.play_music("game_music")
		
		for player in get_tree().get_nodes_in_group(Global.group_players):
			player.set_physics_process(true)
		
		game_on = true
		
		if game_settings["stray_step_mode"]:
			stray_step()

	
func game_over(gameover_reason: int):
	
	if game_on == false: # preprečim double gameover
		return
	game_on = false
	
	Global.hud.game_timer.stop_timer()
	
	if gameover_reason == GameoverReason.CLEANED:
		all_strays_died_alowed = true
		yield(self, "all_strays_died")
		var signaling_player: KinematicBody2D
		for player in get_tree().get_nodes_in_group(Global.group_players):
			player.all_cleaned()
			signaling_player = player # da se zgodi na obeh plejerjih istočasno
		yield(signaling_player, "rewarded_on_game_over") # počakam, da je nagrajen
	
	get_tree().call_group(Global.group_players, "set_physics_process", false)
	
	yield(get_tree().create_timer(2), "timeout") # za dojet
	
	
	stop_game_elements()
	
	Global.gameover_menu.open_gameover(gameover_reason)
	
	
# SETUP --------------------------------------------------------------------------------------


func set_tilemap():
	
	var tilemap_to_release: TileMap = Global.current_tilemap # trenutno naložen v areni
	var tilemap_to_load_path: String = game_data["tilemap_path"]
	
	# release default tilemap	
	tilemap_to_release.set_physics_process(false)
	tilemap_to_release.free()
	
	# spawn new tilemap
	var GameTilemap = ResourceLoader.load(tilemap_to_load_path)
	var new_tilemap = GameTilemap.instance()
	Global.node_creation_parent.add_child(new_tilemap) # direct child of root
	
	# povežem s signalom	
	Global.current_tilemap.connect("tilemap_completed", self, "_on_tilemap_completed")
	
	# grab tilemap tiles
	Global.current_tilemap.get_tiles()
	cell_size_x = Global.current_tilemap.cell_size.x 

	
func set_game_view():
	
	# viewports
	var viewport_1: Viewport = $"%Viewport1"
	var viewport_2: Viewport = $"%Viewport2"
	var viewport_container_2: ViewportContainer = $"%ViewportContainer2"
	var viewport_separator: VSeparator = $"%ViewportSeparator"
	
	var cell_align_start: Vector2 = Vector2(cell_size_x, cell_size_x/2)
	Global.player1_camera.position = player_start_positions[0] + cell_align_start
	
	if start_players_count == 2 and not game_data["game"] == Profiles.Games.SCROLLER:
		viewport_container_2.visible = true
		viewport_2.world_2d = viewport_1.world_2d
		Global.player2_camera.position = player_start_positions[1] + cell_align_start
	else:
		viewport_container_2.visible = false
		viewport_separator.visible = false
	
	# set player camera limits
	var tilemap_edge = Global.current_tilemap.get_used_rect()
	Global.player1_camera.set_camera_limits()
	
	# minimap
	var minimap_container: ViewportContainer = $"../Minimap"
	var minimap_viewport: Viewport = $"../Minimap/MinimapViewport"
	var minimap_camera: Camera2D = $"../Minimap/MinimapViewport/MinimapCam"	
	if Global.game_manager.game_settings["minimap_on"]:
		minimap_container.visible = true
		minimap_viewport.world_2d = viewport_1.world_2d
		minimap_viewport.size.y = minimap_viewport.size.x * tilemap_edge.size.y / tilemap_edge.size.x # višina minimape v razmerju s formatom tilemapa
		minimap_camera.set_camera(tilemap_edge, cell_size_x, minimap_viewport.size)
	else:
		minimap_container.visible = false
	
	
func set_players():
	
	for player_position in player_start_positions: # glavni parameter, ki opredeli število igralcev
		spawned_player_index += 1 # torej začnem z 1
		
		# spawn
		var new_player_pixel: KinematicBody2D
		new_player_pixel = PlayerPixel.instance()
		new_player_pixel.name = "p%s" % str(spawned_player_index)
		new_player_pixel.global_position = player_position + Vector2(cell_size_x/2, cell_size_x/2) # ... ne rabim snepat ker se v pixlu na ready funkciji
		new_player_pixel.modulate = Global.color_white
		new_player_pixel.z_index = 1 # nižje od straysa
		Global.node_creation_parent.add_child(new_player_pixel)
		
		# stats
		new_player_pixel.player_stats = Profiles.default_player_stats.duplicate() # tukaj se postavijo prazne vrednosti, ki se nafilajo kasneje
		new_player_pixel.player_stats["player_energy"] = game_settings["player_start_energy"]
		new_player_pixel.player_stats["player_life"] = game_settings["player_start_life"]
		
		# povežem s hudom
		new_player_pixel.connect("stat_changed", Global.hud, "_on_stat_changed")
		new_player_pixel.emit_signal("stat_changed", new_player_pixel, new_player_pixel.player_stats) # štartno statistiko tako javim 
		
		# pregame setup
		new_player_pixel.set_physics_process(false)
		
		# players camera
		if game_data["game"] == Profiles.Games.SCROLLER:
			new_player_pixel.player_camera = Global.player1_camera
		else:
			if spawned_player_index == 1:
				new_player_pixel.player_camera = Global.player1_camera
				new_player_pixel.player_camera.camera_target = new_player_pixel
			elif spawned_player_index == 2:
				new_player_pixel.player_camera = Global.player2_camera
				new_player_pixel.player_camera.camera_target = new_player_pixel
			
		
func set_strays():
	
	if game_data["game"] == Profiles.Games.SCROLLER:
		spawn_strays(game_data["strays_start_count"])
	else:
		spawn_strays(game_data["strays_start_count"])
		
		yield(get_tree().create_timer(0.01), "timeout") # da se vsi straysi spawnajo
		
		var show_strays_loop: int = 0
		while strays_shown.size() < game_data["strays_start_count"]:
			show_strays_loop += 1 # zazih
			show_strays_on_start(show_strays_loop)
			yield(get_tree().create_timer(0.1), "timeout")
		
		strays_shown.clear() # resetiram, da je mogoč in-game spawn


func spawn_strays(strays_to_spawn_count: int):
	
	# split colors
	strays_to_spawn_count = clamp(strays_to_spawn_count, 1, strays_to_spawn_count) # za vsak slučaj klempam, da ne more biti nikoli 0 ...  ker je error			

	var spectrum_image: Image
	var color_offset: float
	var level_indicator_color_offset: float
	
	# difolt barvna shema ali druge
	if Profiles.current_color_scheme == Profiles.game_color_schemes["default_color_scheme"]:
		# setam sliko
		var spectrum_texture: Texture = spectrum_rect.texture
		spectrum_image = spectrum_texture.get_data()
		spectrum_image.lock()
		# razmak med barvami za strayse
		var spectrum_texture_width: float = spectrum_rect.rect_size.x
		color_offset = spectrum_texture_width / strays_to_spawn_count # razmak barv po spektru ... - 1 je zato ker je razmakov za 1 manj kot barv
	else:
		# setam gradient
		var gradient: Gradient = $SpectrumGradient.texture.get_gradient()
		gradient.set_color(0, Profiles.current_color_scheme[1])
		gradient.set_color(1, Profiles.current_color_scheme[2])
		# razmak med barvami za strayse
		color_offset = 1.0 / strays_to_spawn_count
		
	var available_required_spawn_positions = required_spawn_positions.duplicate() # dupliciram, da ostanejo "shranjene"
	var available_random_spawn_positions = random_spawn_positions.duplicate() # dupliciram, da ostanejo "shranjene"
	
	var all_colors: Array = [] # za color indikatorje

	printt ("pozicije pred spawnom", available_random_spawn_positions.size(), available_required_spawn_positions.size())
	printt ("pozicije pred spawnom def", random_spawn_positions.size(), required_spawn_positions.size())
	
	for stray_index in strays_to_spawn_count:
		
		# barva
		var current_color: Color
		var selected_color_position_x: float
		if Profiles.current_color_scheme == Profiles.game_color_schemes["default_color_scheme"]:
			selected_color_position_x = stray_index * color_offset # lokacija barve v spektrumu
			current_color = spectrum_image.get_pixel(selected_color_position_x, 0) # barva na lokaciji v spektrumu
		else:
			selected_color_position_x = stray_index * color_offset # lokacija barve v spektrumu
			current_color = spectrum_gradient.texture.gradient.interpolate(selected_color_position_x) # barva na lokaciji v spektrumu
		
		if not game_data["game"] == Profiles.Games.SCROLLER:
			all_colors.append(current_color)
		
		# možne spawn pozicije
		var current_spawn_positions: Array
		if not available_required_spawn_positions.empty(): # najprej obvezne
			current_spawn_positions = available_required_spawn_positions
		elif available_required_spawn_positions.empty(): # potem random
			current_spawn_positions = available_random_spawn_positions
		elif available_required_spawn_positions.empty() and available_random_spawn_positions.empty(): # STOP, če ni prostora, straysi pa so še na voljo
			print ("No available spawn positions")
			return
		
		# random pozicija med možnimi
		var random_range = current_spawn_positions.size()
		var selected_cell_index: int = randi() % int(random_range)		
		var selected_position = current_spawn_positions[selected_cell_index]

		# spawn stray
		var new_stray_pixel = StrayPixel.instance()
		new_stray_pixel.name = "S%s" % str(stray_index)
		new_stray_pixel.stray_color = current_color
		new_stray_pixel.global_position = selected_position + Vector2(cell_size_x/2, cell_size_x/2) # dodana adaptacija zaradi središča pixla
		new_stray_pixel.z_index = 2 # višje od plejerja
		Global.node_creation_parent.add_child(new_stray_pixel)
		
		if game_data["game"] == Profiles.Games.SCROLLER:
			new_stray_pixel.show_stray()
			current_spawn_positions.remove(selected_cell_index)
		else:		
			# odstranim uporabljeno pozicijo
			current_spawn_positions.remove(selected_cell_index)
	
	if not game_data["game"] == Profiles.Games.SCROLLER:
		Global.hud.spawn_color_indicators(all_colors) # barve pokažem v hudu		
	else:
		stray_spawning_round += 1
		Global.hud.show_stage_indicator(stray_spawning_round)
		
	self.strays_in_game_count = strays_to_spawn_count # setget sprememba

	printt ("pozicije po spawnu", available_random_spawn_positions.size(), available_required_spawn_positions.size())
	printt ("pozicije po spawnu def", random_spawn_positions.size(), required_spawn_positions.size())


func set_scrolling_stage_indicator():
	
	var spectrum_image: Image
	var level_indicator_color_offset: float
	
	# difolt barvna shema ali druge
	if Profiles.current_color_scheme == Profiles.game_color_schemes["default_color_scheme"]:
		# setam sliko
		var spectrum_texture: Texture = spectrum_rect.texture
		spectrum_image = spectrum_texture.get_data()
		spectrum_image.lock()
		var spectrum_texture_width: float = spectrum_rect.rect_size.x
		level_indicator_color_offset = spectrum_texture_width / level_stage_count
		
	else:
		# setam gradient
		var gradient: Gradient = $SpectrumGradient.texture.get_gradient()
		gradient.set_color(0, Profiles.current_color_scheme[1])
		gradient.set_color(1, Profiles.current_color_scheme[2])
		level_indicator_color_offset = 1.0 / level_stage_count
		
	var selected_color_position_x: float
	var current_color: Color
	var all_stage_colors: Array = [] # za color indikatorje
	
	for stage in level_stage_count:
		if Profiles.current_color_scheme == Profiles.game_color_schemes["default_color_scheme"]:
			selected_color_position_x = stage * level_indicator_color_offset # lokacija barve v spektrumu
			current_color = spectrum_image.get_pixel(selected_color_position_x, 0) # barva na lokaciji v spektrumu
		else:
			selected_color_position_x = stage * level_indicator_color_offset # lokacija barve v spektrumu
			current_color = spectrum_gradient.texture.gradient.interpolate(selected_color_position_x) # barva na lokaciji v spektrumu
		all_stage_colors.append(current_color)
		
	Global.hud.spawn_color_indicators(all_stage_colors) # barve pokažem v hudu	
	
	
# UTILITI ----------------------------------------------------------------------------------


func show_strays_on_start(show_strays_loop: int):

	var spawn_shake_power: float = 0.30
	var spawn_shake_time: float = 0.7
	var spawn_shake_decay: float = 0.2		
	get_tree().call_group(Global.group_player_cameras, "shake_camera", spawn_shake_power, spawn_shake_time, spawn_shake_decay)
		
	var strays_to_show_count: int # količina strejsov se more ujemat s številom spawnanih
	
	match show_strays_loop:
		1:
			Global.sound_manager.play_sfx("thunder_strike")
			Global.sound_manager.play_sfx("blinking")
			strays_to_show_count = round(strays_in_game_count/10)
		2:
			Global.sound_manager.play_sfx("thunder_strike")
			Global.sound_manager.play_sfx("blinking")
			strays_to_show_count = round(strays_in_game_count/8)
		3:
			Global.sound_manager.play_sfx("blinking")
			strays_to_show_count = round(strays_in_game_count/4)
		4:
			Global.sound_manager.play_sfx("thunder_strike")
			Global.sound_manager.play_sfx("blinking")
			strays_to_show_count = round(strays_in_game_count/2)
		5: # še preostale
			Global.sound_manager.play_sfx("blinking")
			strays_to_show_count = strays_in_game_count - strays_shown.size()
	
	# stray fade-in
	var spawned_strays = get_tree().get_nodes_in_group(Global.group_strays)
	var loop_count = 0
	for stray in spawned_strays:
		if not strays_shown.has(stray): # če stray še ni pokazan, ga pokažem in dodam med pokazane
			stray.show_stray()
			strays_shown.append(stray)
			loop_count += 1 # štejem tukaj, ker se šteje samo če se pixel pokaže
		if loop_count >= strays_to_show_count:
			break


func stray_step():
	
	var stepping_direction: Vector2
	
	if game_data["game"] == Profiles.Games.SCROLLER:
		stepping_direction = Vector2.DOWN
		var lines_scroll_limit: int = 23
		for stray in get_tree().get_nodes_in_group(Global.group_strays):
			if stray.current_state == stray.States.IDLE: 
				stray.step(stepping_direction)
		yield(get_tree().create_timer(game_settings["scrolling_pause_time"]), "timeout")
		lines_scroll_counter += 1
		if lines_scroll_counter > lines_scroll_limit:
			lines_scroll_counter = 0
			set_strays()
	else:
		# random dir
		var random_direction_index: int = randi() % int(4)
		match random_direction_index:
			0: stepping_direction = Vector2.LEFT
			1: stepping_direction = Vector2.UP
			2: stepping_direction = Vector2.RIGHT
			3: stepping_direction = Vector2.DOWN
	
		# random stray	
		var random_stray_no: int = randi() % int(get_tree().get_nodes_in_group(Global.group_strays).size())# + 1
		var stray_to_move = get_tree().get_nodes_in_group(Global.group_strays)[random_stray_no]
		if stray_to_move.current_state == stray_to_move.States.IDLE: 
			stray_to_move.step(stepping_direction)
		
		# next step random time
		var random_pause_time_divider: float = randi() % int(game_settings["random_pause_time_divider_range"]) + 1 # višji offset da manjši razpon v random času, +1 je da ni 0
		var random_pause_time = game_settings["pause_time"] / random_pause_time_divider
		yield(get_tree().create_timer(random_pause_time), "timeout")
		
	if game_on:
		stray_step()
	
	
func stop_game_elements():
	
	# včasih nujno
	Global.hud.popups_out()
	get_tree().call_group(Global.group_players, "empty_cocking_ghosts")
	for player in get_tree().get_nodes_in_group(Global.group_players):
		player.stop_sound("teleport")
		player.stop_sound("heartbeat")
	for stray in get_tree().get_nodes_in_group(Global.group_strays):
		stray.current_state = stray.States.STATIC

	
func _change_strays_in_game_count(strays_count_change: int):
	
	strays_in_game_count += strays_count_change # in_game št. upošteva spawnanje in čiščenje (+ in -)
	
	if strays_count_change < 0: # cleaned št. upošteva samo čiščenje (+)
		strays_cleaned_count += abs(strays_count_change)
	
	if strays_in_game_count == 0 and not game_data["game"] == Profiles.Games.TUTORIAL: # tutorial sam ve kdaj je gameover
		game_over(GameoverReason.CLEANED)
		

# SIGNALI ----------------------------------------------------------------------------------


func _on_tilemap_completed(random_spawn_floor_positions: Array, stray_cells_positions: Array, no_stray_cells_positions: Array, player_cells_positions: Array) -> void:
	
	# opredelim tipe pozicij
	random_spawn_positions = random_spawn_floor_positions
	required_spawn_positions = stray_cells_positions
	player_start_positions = player_cells_positions
	
	# start strays count setup
	if not stray_cells_positions.empty() and no_stray_cells_positions.empty(): # št. straysov enako številu "required" tiletov
		game_data["strays_start_count"] = required_spawn_positions.size()
	
	# preventam preveč straysov (več kot je možnih pozicij)
	if game_data["strays_start_count"] > random_spawn_positions.size() + required_spawn_positions.size():
		game_data["strays_start_count"] = random_spawn_positions.size()/2 + required_spawn_positions.size()

	# če ni pozicij, je en player ... random pozicija
	if player_start_positions.empty():
		var random_range = random_spawn_positions.size() 
		var p1_selected_cell_index: int = randi() % int(random_range)
		player_start_positions.append(random_spawn_positions[p1_selected_cell_index])
		random_spawn_positions.remove(p1_selected_cell_index)
	
	start_players_count = player_start_positions.size() # tukaj določeno se uporabi za game view setup
