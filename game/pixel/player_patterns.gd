extends Player


func _physics_process(delta: float) -> void:
	# namen: detect touch
	
	color_poly.modulate = pixel_color # povezava med variablo in barvo mora obstajati non-stop
	
	# glow light setup
	if pixel_color == Global.game_manager.game_settings["player_start_color"]:
		glow_light.color = Color.white
		glow_light.energy = 1.7
	else:
		glow_light.color = pixel_color
		glow_light.energy = 1.5 # če spremeniš, je treba spremenit tudi v animacijah
	
	detect_touch()	
	state_machine()
	manage_heartbeat()
	
	
func on_hit_stray(hit_stray: KinematicBody2D):
	# namen: full burst power
	# namen: ob prve zadetku je game over (samo en posus za uničenje vseh)
	
	Input.start_joy_vibration(0, 0.5, 0.6, 0.2)
	play_sound("hit_stray")	
	spawn_collision_particles()
	shake_player_camera(burst_speed)			
	
	if hit_stray.current_state == hit_stray.States.DYING or hit_stray.current_state == hit_stray.States.WALL: # če je že v umiranju, samo kolajdaš
	# if hit_stray.current_state == hit_stray.States.DYING: # če je že v umiranju, samo kolajdaš
		end_move()
		return
	
	tween_color_change(hit_stray.stray_color)

	# preverim sosede
	var hit_stray_neighbors = check_strays_neighbors(hit_stray)
	# naberem strayse za destrojat
	var burst_speed_units_count = burst_speed / cock_ghost_speed_addon
	var strays_to_destroy: Array = []
	strays_to_destroy.append(hit_stray)
	if not hit_stray_neighbors.empty():
		for neighboring_stray in hit_stray_neighbors: # še sosedi glede na moč bursta
			strays_to_destroy.append(neighboring_stray)
	
	# jih destrojam
	for stray in strays_to_destroy:
		var stray_index = strays_to_destroy.find(stray)
		stray.die(stray_index, strays_to_destroy.size()) # podatek o velikosti rabi za izbor animacije
		Global.hud.show_color_indicator(stray.stray_color) # če je scroller se returna na fuknciji
	
	end_move() # more bit za collision partikli zaradi smeri
	
	change_stat("hit_stray", strays_to_destroy.size()) # štetje, točke in energija glede na število uničenih straysov	
	
	# GO - so spucani vsi?
	if not Global.game_manager.game_data["game"] == Profiles.Games.RUNNER:
		if strays_to_destroy.size() < Global.game_manager.strays_in_game_count:
			yield(get_tree().create_timer(3), "timeout") # pavza za pucanje zadetih
			Global.game_manager.game_over(Global.game_manager.GameoverReason.LIFE)
		else:
			Global.game_manager.game_over(Global.game_manager.GameoverReason.CLEANED)
		
		
func on_hit_wall():
	# namen: dodam ciljno steno (GO)
	
	# if goal wall hit
	var goal_wall_id = 7
	var current_collider: Node = detect_collision_in_direction(direction)
	if current_collider.is_in_group(Global.group_tilemap):
		if current_collider.get_collision_tile_id(self, direction) == goal_wall_id:
			Input.start_joy_vibration(0, 0.5, 0.6, 0.7)
			play_sound("hit_stray")
			spawn_collision_particles()
			shake_player_camera(burst_speed)
			end_move()
			for cell in current_collider.get_used_cells_by_id(7):
				current_collider.set_cellv(cell, 3)
			Global.game_manager.game_over(Global.game_manager.GameoverReason.CLEANED)
			return
	
	# če ne je standardni zadetek
	Input.start_joy_vibration(0, 0.5, 0.6, 0.7)
	play_sound("hit_wall")
	spawn_dizzy_particles()
	spawn_collision_particles()
	shake_player_camera(burst_speed)
	
	got_hit = true # da heartbeat animacija ne povozi die animacije
	
	if player_stats["player_energy"] <= 1: # more bit pred statistiko
		stop_heart()
	
	
	change_stat("hit_wall", 1) # točke in energija glede na delež v settingsih, energija na 0 in izguba lajfa, če je "lose_life_on_hit"
	
	die() # vedno sledi statistiki


func detect_touch():
	
	var touch_rays: Array = [$Touch/TouchRay1, $Touch/TouchRay2, $Touch/TouchRay3, $Touch/TouchRay4]	
	var collider: Node
	var touching_objects: Array
	 
	for ray in touch_rays:
		ray.add_exception(self)
		ray.force_raycast_update()
		if ray.is_colliding():
			collider = ray.get_collider()
			touching_objects.append(collider)
	
	# posledice dotilka
	if not touching_objects.empty():
#		print("touching_objects ", touching_objects.size())
		for object in touching_objects:
			if object.is_in_group(Global.group_strays):
				if not object.current_state == object.States.DYING and not object.current_state == object.States.WALL:
					change_stat("touching_stray", 1) # točke in energija kot je določeno v settingsih
	
	if player_stats["player_energy"] == 0:
		die()
