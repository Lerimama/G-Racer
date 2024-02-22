extends GameManager


func _ready() -> void:

	Global.game_manager = self
	
	StrayPixel = preload("res://game/pixel/stray_patterns.tscn")
	PlayerPixel = preload("res://game/pixel/player_patterns.tscn")
	
	randomize()


func _process(delta: float) -> void:
	# namen: kličem stray step
	
	if get_tree().get_nodes_in_group(Global.group_strays).empty() and all_strays_died_alowed:
		all_strays_died_alowed = false
		emit_signal("all_strays_died")
	
	# position indicators off
	show_position_indicators = false			
	
#	if game_on and not step_in_progress:
#		stray_step()

#func start_game():
#	# namen: stray step
#
#	Global.hud.game_timer.start_timer()
#	Global.sound_manager.play_music("game_music")
#
#	for player in get_tree().get_nodes_in_group(Global.group_players):
#		player.set_physics_process(true)
#
#	yield(get_tree().create_timer(2), "timeout") # čaka na hudov slide in
#
#	game_on = true
#
##	stray_step() # prvi step
	
	
func game_over(gameover_reason: int):
	# namen: adaptacija cleaned gameoverja
	
	if game_on == false: # preprečim double gameover
		return
	game_on = false
	
	Global.hud.game_timer.stop_timer()
	
	if game_data["game"] == Profiles.Games.RUNNER:
		if gameover_reason == GameoverReason.CLEANED: # če zadaneš goal steno
			# animacija indikatorjev
			Global.hud.deactivate_all_indicators()
			# ugasnem goal stene
#			for cell in Global.current_tilemap.get_used_cells_by_id(7):
#				Global.current_tilemap.set_cellv(cell, 3) # menjam za celico stene
#				Global.current_tilemap.set_cellv(cell, 0) # menjam za celico tal
#				var cell_local_position: Vector2 = Global.current_tilemap.map_to_world(cell)
#				var cell_global_position: Vector2 = Global.current_tilemap.to_global(cell_local_position) # pozicija je levo-zgornji vogal celice
#				Global.current_tilemap.floor_global_positions.append(cell_global_position)
			# player white animacija
			var signaling_player: KinematicBody2D
			for player in get_tree().get_nodes_in_group(Global.group_players):
				player.all_cleaned()
				signaling_player = player # da se zgodi na obeh plejerjih istočasno
			yield(signaling_player, "rewarded_on_game_over") # počakam, da je nagrajen
		
	else: # elif Global.game_manager.game_data["game"] == Profiles.Games.RIDDLER:
		if gameover_reason == GameoverReason.CLEANED: # vsi spucani v enem poskusu
			# počaka da so vsi streyi kvefijani
			all_strays_died_alowed = true
			yield(self, "all_strays_died")
			# player white animacija
			var signaling_player: KinematicBody2D
			for player in get_tree().get_nodes_in_group(Global.group_players):
				player.all_cleaned()
				signaling_player = player # da se zgodi na obeh plejerjih istočasno
			yield(signaling_player, "rewarded_on_game_over") # počakam, da je nagrajen
	
	
	get_tree().call_group(Global.group_players, "set_physics_process", false)
	
	yield(get_tree().create_timer(1), "timeout") # za dojet
	
	stop_game_elements()
	
	Global.gameover_menu.open_gameover(gameover_reason)
	
	
func set_game_view():
	
	# viewports
	var viewport_1: Viewport = $"%Viewport1"
	var viewport_2: Viewport = $"%Viewport2"
	var viewport_container_2: ViewportContainer = $"%ViewportContainer2"
	var viewport_separator: VSeparator = $"%ViewportSeparator"
	
	var cell_align_start: Vector2 = Vector2(cell_size_x, cell_size_x/2)
	Global.player1_camera.position = player_start_positions[0] + cell_align_start
	
	if start_players_count == 2:
		viewport_container_2.visible = true
		viewport_2.world_2d = viewport_1.world_2d
		Global.player2_camera.position = player_start_positions[1] + cell_align_start
	else:
		viewport_container_2.visible = false
		viewport_separator.visible = false
	
	# set player camera limits
	var tilemap_edge = Global.current_tilemap.get_used_rect()
	get_tree().call_group(Global.group_player_cameras, "set_camera_limits")
	
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


var step_in_progress: bool = false
var scrolling_pause_time: float = 0.5 # pavza med stepi
var lines_scrolled_count: int = 0 # prištevam v stray_step()
var lines_scroll_per_spawn_round: int = 1 # ob levelu se vleče iz profilov


func stray_step():
	
	step_in_progress = true
	
	var stepping_direction: Vector2
	
	if game_data["game"] == Profiles.Games.SCROLLER:
		stepping_direction = Vector2.DOWN
		lines_scroll_per_spawn_round = 23
		for stray in get_tree().get_nodes_in_group(Global.group_strays):
			if stray.current_state == stray.States.IDLE: 
				stray.step(stepping_direction)
		yield(get_tree().create_timer(game_settings["scrolling_pause_time"]), "timeout")
		lines_scrolled_count += 1
		if lines_scrolled_count > lines_scroll_per_spawn_round:
			lines_scrolled_count = 0
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
#		var random_pause_time_divider: float = randi() % int(game_settings["random_pause_time_divider_range"]) + 1 # višji offset da manjši razpon v random času, +1 je da ni 0
		var random_pause_time_divider: float = randi() % int(5) + 1 # višji offset da manjši razpon v random času, +1 je da ni 0
#		var random_pause_time = game_settings["pause_time"] / random_pause_time_divider
#		var random_pause_time = 0.5 / random_pause_time_divider
#		yield(get_tree().create_timer(random_pause_time), "timeout")
		yield(get_tree().create_timer(0.01), "timeout")
	
	
#	yield(get_tree().create_timer(scrolling_pause_time), "timeout")
	step_in_progress = false
		
#	if game_on:
#		stray_step()
