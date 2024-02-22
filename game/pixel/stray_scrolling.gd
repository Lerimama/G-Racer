extends Stray


func show_stray(): # kliče GM
	
	modulate.a = 1
	
	if current_state == States.WALL:
		stray_color.s = 0.0
		color_poly.modulate = Global.color_gray_dark


func die(stray_in_stack_index: int, strays_in_stack: int):
	# namen: stage upgrade in die, camera shake in vibra off, collisions enabled, die off, če je DYING (walled)
	
	if current_state == States.DYING:
		return
		
	current_state = States.DYING
	global_position = Global.snap_to_nearest_grid(global_position) 
	
	# čakalni čas
	var wait_to_destroy_time: float = sqrt(0.07 * (stray_in_stack_index)) # -1 je, da hitan stray ne čaka
	yield(get_tree().create_timer(wait_to_destroy_time), "timeout")
	
	# animacije
	if strays_in_stack <= 3: # žrebam
		var random_animation_index = randi() % 5 + 1
		var random_animation_name: String = "die_stray_%s" % random_animation_index
		animation_player.play(random_animation_name) 
	else: # ne žrebam
		animation_player.play("die_stray")

	position_indicator.modulate.a = 0	
#	collision_shape.disabled = true
#	collision_shape_ext.disabled = true
	
	# color vanish
	var vanish_time = animation_player.get_current_animation_length()
	var vanish: SceneTreeTween = get_tree().create_tween()
	vanish.tween_property(self, "color_poly:modulate:a", 0, vanish_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)

	if not Global.game_manager.in_level_transition:
#	if Global.game_manager.game_data["game"] == Profiles.Games.SCROLLER and not Global.game_manager.in_level_transition:
		Global.game_manager.upgrade_stage()	
		
	# KVEFRI je v animaciji


func step(step_direction: Vector2):
	# namen: nerandom smer, pošiljanje collisiona za prepoznavanje stene, wall se lahko premika
	
	if not current_state == States.WALL: # wall se lahko premika
		if not current_state == States.IDLE:
			return
		
	var current_collider = detect_collision_in_direction(step_direction)
	
	if current_collider:
		return current_collider
	
	if not current_state == States.WALL: # wall je vedno wall
		current_state = States.MOVING
	
	collision_shape_ext.position = step_direction * cell_size_x # vržem koližn v smer premika

	var step_time: float = 0.2
		
	var step_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
	step_tween.tween_property(self, "position", global_position + step_direction * cell_size_x, step_time)
	step_tween.parallel().tween_property(collision_shape_ext, "position", Vector2.ZERO, step_time)
	step_tween.tween_callback(self, "end_move")
#	step_tween.tween_callback(Global, "snap_to_nearest_grid", [global_position + step_direction * cell_size_x])
#	step_tween.tween_property(self, "current_state", States.IDLE, 0)

	
# ON FLOOR --------------------------------------------------------------------------------------------


func get_all_neighbors_in_directions(directions_to_check: Array): # kliče player on hit
	# namen: preverjanje vseh_sosedov, tudi tilemapa
	
	var current_cell_neighbors: Array
	for direction in directions_to_check:
		var neighbor = detect_collision_in_direction(direction)
		if neighbor and neighbor.is_in_group(Global.group_strays) and not neighbor == self: # če je kolajder, je stray in ni self
			current_cell_neighbors.append(neighbor)
		if neighbor and neighbor.is_in_group(Global.group_tilemap): # če je kolajder, je tilemap
			current_cell_neighbors.append(neighbor)
		
	return current_cell_neighbors # uporaba v stalnem čekiranj sosedov


func turn_to_wall(stray_in_stack_index: int):
	
	current_state = States.WALL # takoj je izločen iz igre. po pavzi pa efekt
	
	# čakalni čas
	var wait_to_destroy_time: float = sqrt(0.07 * (stray_in_stack_index)) # -1 je, da hitan stray ne čaka
	yield(get_tree().create_timer(wait_to_destroy_time), "timeout")
	
	# efekti
	# Input.start_joy_vibration(0, 0.5, 0.6, 0.2)
	# play_sound("turning_color")
	play_sound("blinking")
	
	var shake_power: float = 0.2
	var shake_time: float = 0.3
	var shake_decay: float = 0.7
	Global.player1_camera.shake_camera(shake_power, shake_time, shake_decay)	

	# turn to color
	stray_color.s = 0.0
	
	var color_tween: SceneTreeTween = get_tree().create_tween()
	color_tween.tween_property(self, "color_poly:modulate", stray_color, 0.2) # barva straysa
	color_tween.parallel().tween_property(self, "modulate", Global.color_gray_dark, 0.2) # siva stena
	
	# povzroča error, ker hoče vrnit funkciji ki ne obstaja več ... nekaj takega
	# color_tween.tween_callback(self, "return", [true])#.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
