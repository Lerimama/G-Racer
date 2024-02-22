extends GameManager # default game manager


var current_stray_spawning_round: int = 0 # prištevam na koncu spawna

var lines_scrolled_count: int = 0 # prištevam v stray_step()
var lines_scroll_per_spawn_round: int = 1 # ob levelu se vleče iz profilov
var scrolling_pause_time: float # pavza med stepi


var current_stage: int = 0 # na štartu se kliče stage up
var stages_per_level: int # = Profiles.scrolling_level_conditions[1]
var current_level: int = 0 # na štartu se kliče level up
var levels_per_game: int = 10
var level_color_scheme: Dictionary # trenutna barvna shema

var in_level_transition: bool = false
var step_in_progress: bool = false
var wall_spawn_random_range: int


func _unhandled_input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("l"):
		upgrade_level()
			
			
func _ready() -> void:

	Global.game_manager = self
	StrayPixel = preload("res://game/pixel/stray_scrolling.tscn")
	PlayerPixel = preload("res://game/pixel/player_scrolling.tscn")
	randomize()
	
	
func _process(delta: float) -> void:
	# namen: kličem stray step
	
	if get_tree().get_nodes_in_group(Global.group_strays).empty() and all_strays_died_alowed:
		all_strays_died_alowed = false
		emit_signal("all_strays_died")
	
	# position indicators off
	show_position_indicators = false			
	
	if game_on and not step_in_progress:
		stray_step()


func set_game(): 
	# namen: setam level indikatorje in strayse spawnam po štratu igre
	
	# player intro animacija
	var signaling_player: KinematicBody2D
	for player in get_tree().get_nodes_in_group(Global.group_players):
		player.animation_player.play("lose_white_on_start")
		signaling_player = player # da se zgodi na obeh plejerjih istočasno
	yield(signaling_player, "player_pixel_set") # javi player na koncu intro animacije
	
	yield(get_tree().create_timer(1), "timeout") # da si plejer ogleda

	Global.hud.slide_in(start_players_count)
	yield(Global.start_countdown, "countdown_finished") # sproži ga hud po slide-inu

	start_game()
	

func start_game():

	Global.hud.game_timer.start_timer()
	Global.sound_manager.play_music("game_music")

	for player in get_tree().get_nodes_in_group(Global.group_players):
		player.set_physics_process(true)
	
	yield(get_tree().create_timer(2), "timeout") # čaka na hudov slide in
	game_on = true
	
	upgrade_level()
	
	spawn_strays(game_data["strays_start_count"])

	# stray_step() # prvi step ... ne rabim, ker kliče že GM


func game_over(gameover_reason: int):
	
	if game_on == false: # preprečim double gameover
		return
	game_on = false
	
	Global.hud.game_timer.stop_timer()
	
	# ko je na koncu
#	if gameover_reason == GameoverReason.TIME: 
#		return
	if gameover_reason == GameoverReason.CLEANED:
		clean_strays_in_game()
		yield(self, "all_strays_died")
		print("GO cleared")
		var signaling_player: KinematicBody2D
		for player in get_tree().get_nodes_in_group(Global.group_players):
			player.all_cleaned()
			signaling_player = player # da se zgodi na obeh plejerjih istočasno
			clean_strays_in_game()
		yield(signaling_player, "rewarded_on_game_over") # počakam, da je nagrajen
	
	get_tree().call_group(Global.group_players, "set_physics_process", false)
	
	yield(get_tree().create_timer(1), "timeout") # za dojet
	
	stop_game_elements()

	Global.gameover_menu.open_gameover(gameover_reason)
		
		
# SETUP --------------------------------------------------------------------------------------


func set_tilemap():
	# namem: dodam povezavo s signalom  iz aree	
	
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
	
	#namen: ... tudi fiksirana kamera
	
	# viewports
	var viewport_1: Viewport = $"%Viewport1"
	var viewport_2: Viewport = $"%Viewport2"
	var viewport_container_2: ViewportContainer = $"%ViewportContainer2"
	var viewport_separator: VSeparator = $"%ViewportSeparator"

	var cell_align_start: Vector2 = Vector2(cell_size_x, cell_size_x/2)
	# Global.player1_camera.position = player_start_positions[0] + cell_align_start

	viewport_container_2.visible = false
	viewport_separator.visible = false

	# set player camera limits
	var tilemap_edge = Global.current_tilemap.get_used_rect()
	# Global.player1_camera.set_camera_limits()


func set_level_colors():

	var spectrum_image: Image
	var level_indicator_color_offset: float

	# difolt barvna shema ali druge
	if level_color_scheme == Profiles.game_color_schemes["default_color_scheme"]:
		# setam sliko
		var spectrum_texture: Texture = spectrum_rect.texture
		spectrum_image = spectrum_texture.get_data()
		spectrum_image.lock()
		var spectrum_texture_width: float = spectrum_rect.rect_size.x
		level_indicator_color_offset = spectrum_texture_width / stages_per_level

	else:
		# setam gradient
		var gradient: Gradient = $SpectrumGradient.texture.get_gradient()
		gradient.set_color(0, level_color_scheme[1])
		gradient.set_color(1, level_color_scheme[2])
		level_indicator_color_offset = 1.0 / stages_per_level

	var selected_color_position_x: float
	var current_color: Color
	var all_level_colors: Array = [] # za color indikatorje

	for stage in stages_per_level:
		if level_color_scheme == Profiles.game_color_schemes["default_color_scheme"]:
			selected_color_position_x = stage * level_indicator_color_offset # lokacija barve v spektrumu
			current_color = spectrum_image.get_pixel(selected_color_position_x, 0) # barva na lokaciji v spektrumu
		else:
			selected_color_position_x = stage * level_indicator_color_offset # lokacija barve v spektrumu
			current_color = spectrum_gradient.texture.gradient.interpolate(selected_color_position_x) # barva na lokaciji v spektrumu
		all_level_colors.append(current_color)

	Global.hud.spawn_color_indicators(all_level_colors) # barve pokažem v hudu	

	
func set_players():
	# namen: podajanje dobljenih točk v GM
	
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
		if spawned_player_index == 1:
			new_player_pixel.player_camera = Global.player1_camera
			# new_player_pixel.player_camera.camera_target = new_player_pixel
		elif spawned_player_index == 2:
			new_player_pixel.player_camera = Global.player2_camera
			# new_player_pixel.player_camera.camera_target = new_player_pixel
		

# STRAYS -----------------------------------------------------------------------------


func spawn_strays(strays_to_spawn_count: int):
	
#	if not game_on:
#		return
		
	# split colors
	strays_to_spawn_count = clamp(strays_to_spawn_count, 1, strays_to_spawn_count) # za vsak slučaj klempam, da ne more biti nikoli 0 ...  ker je error			

	var spectrum_image: Image
	var color_offset: float
	var level_indicator_color_offset: float

	# difolt barvna shema ali druge
	if level_color_scheme == Profiles.game_color_schemes["default_color_scheme"]:
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
		gradient.set_color(0, level_color_scheme[1])
		gradient.set_color(1, level_color_scheme[2])
		# razmak med barvami za strayse
		color_offset = 1.0 / strays_to_spawn_count

	var available_required_spawn_positions = required_spawn_positions.duplicate() # dupliciram, da ostanejo "shranjene"
	var available_random_spawn_positions = random_spawn_positions.duplicate() # dupliciram, da ostanejo "shranjene"

	var all_colors: Array = [] # za color indikatorje
	var realy_spawned_strays_count: int = 0 # za štetje zares spawnanih
	
	# preverim prepovedane pozicije ... zasedene in podobno
	var current_strays_on_top: Array = Global.current_tilemap.strays_in_top_area
	var forbiden_positions: Array = []
	for stray_on_top in current_strays_on_top:
		var adapted_stray_position: Vector2 = stray_on_top.position - Vector2.ONE * cell_size_x / 2 # za središče
		if game_data["game"] == Profiles.Games.SLIDER:
			adapted_stray_position.x += 64 # za pozicijo zaznanega straya (zamik spawn lokacije glede na detektor)  
		elif game_data["game"] == Profiles.Games.SCROLLER:
			adapted_stray_position.y -= 32 # za pozicijo zaznanega straya (zamik spawn lokacije glede na detektor)
		forbiden_positions.append(adapted_stray_position)
	# printt ("prepovedane", forbiden_positions)
	
	for stray_index in strays_to_spawn_count:
		# barva
		var current_color: Color
		var selected_color_position_x: float
		if level_color_scheme == Profiles.game_color_schemes["default_color_scheme"]:
			selected_color_position_x = stray_index * color_offset # lokacija barve v spektrumu
			current_color = spectrum_image.get_pixel(selected_color_position_x, 0) # barva na lokaciji v spektrumu
		else:
			selected_color_position_x = stray_index * color_offset # lokacija barve v spektrumu
			current_color = spectrum_gradient.texture.gradient.interpolate(selected_color_position_x) # barva na lokaciji v spektrumu

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
		var selected_cell_index: int = randi() % int(random_range)# + 1		
		var selected_position = current_spawn_positions[selected_cell_index]

		# primerjam spawn pozicijo s prepovedanimi
		# if not forbiden_positions.empty():
		#	print("curr position ", selected_position)
		if not forbiden_positions.has(selected_position):
			# spawn stray
			var new_stray_pixel = StrayPixel.instance()
			new_stray_pixel.name = "S%s" % str(stray_index)
			new_stray_pixel.global_position = selected_position + Vector2(cell_size_x/2, cell_size_x/2) # dodana adaptacija zaradi središča pixla
			new_stray_pixel.z_index = 2 # višje od plejerja
			
			# naj postane wall ali ne
			if game_data["game"] == Profiles.Games.SLIDER:
				# stray becomes wall
				var random_wall_count: int = randi() % wall_spawn_random_range + 1
				if random_wall_count == 1 or random_wall_count == 2:
					new_stray_pixel.current_state = new_stray_pixel.States.WALL	
				else:
					new_stray_pixel.stray_color = current_color
			else:
				new_stray_pixel.stray_color = current_color
			
			Global.node_creation_parent.add_child(new_stray_pixel)
			
			new_stray_pixel.show_stray()
			realy_spawned_strays_count += 1
		
		# print("realy ", realy_spawned_strays_count)
		
		# odstranim uporabljeno pozicijo ne glede na al je bila spawnana al ne
		current_spawn_positions.remove(selected_cell_index)

	self.strays_in_game_count = realy_spawned_strays_count # setget sprememba
	current_stray_spawning_round += 1


func stray_step():
	
	# if get_tree().paused:
	#	return

	step_in_progress = true
		
	check_top_for_gameover() 
	
	var stepping_direction: Vector2
	
	if game_data["game"] == Profiles.Games.SLIDER and not in_level_transition:
		
#		upgrade_stage()
		stepping_direction = Vector2.LEFT
		for stray in get_tree().get_nodes_in_group(Global.group_strays):
			stray.step(stepping_direction)
		# Global.sound_manager.play_sfx("stray_step") # ulomek je za pitch zvoka
		lines_scrolled_count += 1
		if lines_scrolled_count % lines_scroll_per_spawn_round == 0: # tukaj, da ne spawna če  je konec
			spawn_strays(game_data["strays_start_count"])
	
		
	elif game_data["game"] == Profiles.Games.SCROLLER and not in_level_transition: # and not strays_on_wall_edge_connected:
		
		stepping_direction = Vector2.DOWN
		
		# kdo stepa, kličem step in preverim kolajderja 
		for stray in get_tree().get_nodes_in_group(Global.group_strays):
			if not wall_strays.has(stray) and not all_strays_on_wall.has(stray): # če stray ni del stene in ni naložen na steni
				var current_collider = stray.step(stepping_direction)
				if current_collider:
					check_stray_wall_collisions(stray, current_collider) # brez povezanosti na robu
		# Global.sound_manager.play_sfx("stray_step") # ulomek je za pitch zvoka
		lines_scrolled_count += 1
		if lines_scrolled_count % lines_scroll_per_spawn_round == 0: # tukaj, da ne spawna če  je konec
			spawn_strays(game_data["strays_start_count"])
			
	yield(get_tree().create_timer(scrolling_pause_time), "timeout")
	
	step_in_progress = false

		
func play_stepping_sound(current_player_energy_part: float):

	if Global.sound_manager.game_sfx_set_to_off:
		return		

	var random_step_index = randi() % $Sounds/Stepping.get_child_count()
	var selected_step_sound = $Sounds/Stepping.get_child(random_step_index)
	selected_step_sound.pitch_scale = clamp(current_player_energy_part, 0.6, 1)
	selected_step_sound.play()
	
		
# LEVELING --------------------------------------------------------------------------------------


func upgrade_stage():
	# kliče stray na die
	
	# stage up na vsak klic ... tudi ob apgrejdanju level
	current_stage += 1
	Global.hud.update_indicator_on_stage_up(current_stage) # povdari indikator
	
	# če je dosežen level se izvede tudi upgrade levela (ima pavzo)
	if current_stage > stages_per_level:
		upgrade_level()


func upgrade_level():
	
	current_level += 1 # številka novega levela 
	
	# če presega max levele ... game over
	if current_level > levels_per_game:
		game_over(GameoverReason.CLEANED)
	else:
		in_level_transition = true
			
		# pogoji novega levela
		set_level_conditions() 
		# spraznem in indkatorje
		Global.hud.empty_color_indicators() # novi indkatorji
		# naštimam nove barve
		set_level_colors()
		
		# razen level 1
		if not current_level == 1:
			
			current_stage = 1 # ker se šteje pobite strayse je na začetku 0
			Global.hud.level_up_popup_in(current_level)
			Global.hud.update_indicator_on_stage_up(current_stage) # obarvaj prvega
			
			# pavza pri prehoud lavela .... za pedenanjem indikatorjev in pucanje ekrana
			get_tree().call_group(Global.group_players, "set_physics_process", false)
#			yield(get_tree().create_timer(2), "timeout")
			clean_strays_in_game() #puca vse v igri
			yield(self, "all_strays_died") # ko so vsi iz igre grem naprej
#			yield(get_tree().create_timer(2), "timeout")
#			yield(self, "all_strays_died")
			
			Global.hud.level_up_popup_out()
			get_tree().call_group(Global.group_players, "set_physics_process", true)
		else:
			current_stage = 0 # ker se šteje pobite strayse je na začetku 0
		
		in_level_transition = false		


func set_level_conditions():
	
	var leveling_conditions: Dictionary
	
	if Global.game_manager.game_data["game"] == Profiles.Games.SLIDER:
		leveling_conditions = Profiles.slider_level_conditions
	elif Global.game_manager.game_data["game"] == Profiles.Games.SCROLLER:
		leveling_conditions = Profiles.scrolling_level_conditions
		
	if current_level > 0:
		lines_scroll_per_spawn_round = leveling_conditions[current_level].lines_scroll_per_spawn_round
		stages_per_level = leveling_conditions[current_level].stages_per_level
		level_color_scheme = leveling_conditions[current_level].color_scheme
		scrolling_pause_time = leveling_conditions[current_level].scrolling_pause_time
		game_data["strays_start_count"] = leveling_conditions[current_level].strays_spawn_count
		if Global.game_manager.game_data["game"] == Profiles.Games.SLIDER:
			wall_spawn_random_range = leveling_conditions[current_level].wall_spawn_random_range
			print(wall_spawn_random_range)

# UTILITI -------------------------------------------------------------------------------------------------------------------------------


func clean_strays_in_game():
	
	var all_strays_alive: Array = get_tree().get_nodes_in_group(Global.group_strays)
	
	# javim število, ki se bo pucalo ... to pomeni, da se tudi teli štejejo v spucane od plejjerja
	# self.strays_in_game_count = all_strays_alive.size() # setget sprememba
	
	for stray in all_strays_alive:
		# najprej setam STATIC ... tudi DYING postanejo static, da lahko kličem die()
		
		# tiste, ki so že tla spremenim v static ... ne pa tudi umrlih od trenutnega hita
		if wall_strays.has(stray):
			stray.current_state = stray.States.STATIC
			wall_strays.erase(stray)
		# cela tla
		var stray_index: int = all_strays_alive.find(stray)
		var all_strays_alive_count: int = all_strays_alive.size()
		stray.die(stray_index, all_strays_alive_count)
	
	self.strays_in_game_count = all_strays_alive.size() # setget sprememba
	
	all_strays_died_alowed = true # javi signal, ko so vsi spucani 
	
	return true
	
	
func check_top_for_gameover():
	# preverim stanje na vrhu
			
	var current_strays_on_top: Array = Global.current_tilemap.strays_in_top_area
	var wall_strays_on_top_count: int = 0
	
	 # GO na stolpec full
	var spawn_line_cells_count: int
	
	if game_data["game"] == Profiles.Games.SCROLLER:
		spawn_line_cells_count = 40
	if game_data["game"] == Profiles.Games.SLIDER:
		spawn_line_cells_count = 20
	
	# GO na prvi stopec full	
	if current_strays_on_top.size() < spawn_line_cells_count:
	# if current_strays_on_top.size() < 40:
		for stray_on_top in current_strays_on_top:
			if wall_strays.has(stray_on_top):
				print("GAME OVER - TOP")
				game_over(GameoverReason.TIME)
				return # da ne falsam game filled
	
	# GO na top full
	# štejejo samo spremenjeni v wall
	# for stray in current_strays_on_top:
	# 	if wall_strays.has(stray):
	# 		wall_strays_on_top_count += 1
			
	# if wall_strays_on_top_count >= spawn_line_cells_count:
	# 	print("GAME OVER - FILLED ", wall_strays_on_top_count)
	# 	game_over(GameoverReason.TIME)


# POLNENJE TAL -----------------------------------------------------------------------------


# nikoli ne restiram
var wall_strays: Array = [] # vsi straysi,ki so celotna tla
var first_wall_round: bool = true


# DOTIK STENE --------------------------------------------------------------------------------------------------------------------


func check_stray_wall_collisions(current_stray: KinematicBody2D, current_collider: Node): # preverjanje, ko ne iščeš polnosti tal
	
	# prva runda ... kolajder tilemap (tla)
	if current_collider.is_in_group(Global.group_tilemap):
		wall_strays.append(current_stray)
		current_stray.turn_to_wall(1)
	# druge runde ... kolajder stray in je rob tal
	elif current_collider.is_in_group(Global.group_strays) and wall_strays.has(current_collider):
		wall_strays.append(current_stray)
		current_stray.turn_to_wall(1)
	
# obst_		
func turn_strays_to_wall():
	
	print("napačna funkcija: ", "turn_strays_to_wall")
	
	# VER 1 ... vsak, ki se je v koraku dotaknil tal
	for stray in all_strays_on_wall:
		Global.sound_manager.play_sfx("thunder_strike")
		# samo en stray
		wall_strays.append(stray)
		stray.turn_to_wall(1)
			
	all_strays_on_wall.clear() # reset vrednosti, ki ji rabim do konca spremembe ... ne briše arraya sredi njegovega preverjanja
			
	# preverim, če je vrh zafilan z wall straysi ... game over
	check_top_for_gameover()
	

# POVEZANOST NA STENI --------------------------------------------------------------------------------------------------------------------


# resetiram na floor filled
var wall_edge_strays: Array = [] # straysi ki predstavljajo rob tal
var strays_on_wall_edge: Array = [] # strays, ki se dotikajo robnih tiletov tal ... se resetira na vsako polnitev
var all_strays_on_wall: Array = [] # vsi strays, ki so ustavljeni ker so spodaj tla

# resetira se na vsak korak
var connected_strays_on_wall_edge: Array = [] # straysi na robu tal, ki so povezani
var strays_on_wall_edge_connected: bool = false


func check_stray_all_wall_collisions(current_stray: KinematicBody2D, current_collider: Node): # preverjanje, ko iščeš polna tla
	print("napačna funkcija: ", "check_stray_all_wall_collisions")
	# VER ko preverjam filanje cele stene	
	
	# prva runda ... kolajder tilemap (tla)
	if current_collider.is_in_group(Global.group_tilemap):
		# current_stray.color_poly.color = Color.red
		strays_on_wall_edge.append(current_stray)
		all_strays_on_wall.append(current_stray)
	# druge runde ... kolajder stray in je rob tal
	elif current_collider.is_in_group(Global.group_strays) and wall_edge_strays.has(current_collider):
		# current_stray.color_poly.color = Color.yellow
		strays_on_wall_edge.append(current_stray)
		all_strays_on_wall.append(current_stray)
	# druge runde ... kolajder stray je del bodočih tal ... stray postane bodoča tla ... se umiri
	elif current_collider.is_in_group(Global.group_strays) and all_strays_on_wall.has(current_collider):
		all_strays_on_wall.append(current_stray)


func check_strays_on_wall_edge_connection():
	print("napačna funkcija: ", "check_strays_on_wall_edge_connection")
	
	# VER 2 ... glede na povezanost podna
	
	if strays_on_wall_edge.size() == 40:
		if first_wall_round: # prva runda
			first_wall_round = false
			turn_all_on_wall_to_wall()
		else: # druge runde preverjam še za povezanost
			# preverim povezanost straysov na robu
			connected_strays_on_wall_edge.clear() # spucam, ker vedno znova pregledam vse na tleh
			for stray in strays_on_wall_edge:
#				if not stray.current_state == stray.States.DYING: # eror varovalka
				if stray: # eror varovalka
					var stray_neighbors: Array = stray.get_all_neighbors_in_directions([Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]) # nepomembna smer
					if stray_neighbors.size() == 4: # sosedi so straysi ali tilemap
						# stray.color_poly.color = Color.green
						connected_strays_on_wall_edge.append(stray)
			if connected_strays_on_wall_edge.size() >= 40: # vse so povezane
				turn_all_on_wall_to_wall()
	

func turn_all_on_wall_to_wall():
	print("napačna funkcija: ", "turn_all_on_wall_to_wall")
	
	get_tree().call_group(Global.group_players, "set_physics_process", false)
	
	strays_on_wall_edge_connected = true
	
	Global.hud.game_timer.pause_timer()
	Global.sound_manager.play_sfx("thunder_strike")
	
	# resetiram na začetku funkcije
	strays_on_wall_edge.clear()
	#resetiram stare na robu tal ... nove robne strayse razbiram iz bodočih talnih straysov
	wall_edge_strays.clear()
	# vse ki so trenutno na tleh preverjam, da ugotovim status v naslednji rundi
	for stray in all_strays_on_wall:
		# cela tla
		var stray_index = all_strays_on_wall.find(stray)
		wall_strays.append(stray)
		stray.turn_to_wall(stray_index)
		# rob tal
		var stray_neighbors: Array = stray.get_all_neighbors_in_directions([Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]) # nepomembna smer
		if stray_neighbors.size() < 4:
			wall_edge_strays.append(stray)
	
	
	var total_turning_time: float = 0.2 + all_strays_on_wall.size() * 0.03 # cirka
	
	all_strays_on_wall.clear() # reset vrednosti, ki ji rabim do konca spremembe
			
	# pavza za celotno spremembo v tla
	print ("total_turning_time " ,total_turning_time)
	yield(get_tree().create_timer(total_turning_time), "timeout")

	Global.hud.game_timer.unpause_timer()
	strays_on_wall_edge_connected = false
	get_tree().call_group(Global.group_players, "set_physics_process", true)


