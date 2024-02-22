extends Stray

var static_stray: bool


func _ready() -> void:
	# namen: static stray selector
	
	add_to_group(Global.group_strays)

	randomize() # za random die animacije
	
	color_poly.modulate = stray_color
	modulate.a = 0
	position_indicator.get_node("PositionPoly").color = stray_color
	count_label.text = name
	position_indicator.visible = false
	
	# moving stray? ... ?% šans
	var random_selector: float = randi() % int(2)
	if random_selector == 0:
		static_stray = false
	else:
		static_stray = true
	
func _process(delta: float) -> void:
	# namen: self step, indikatorji ven
	position_indicator.visible = false
	
	if not static_stray:
		if Global.game_manager.game_on and not step_in_progress and visible_on_screen:
			step(Vector2.DOWN)

		
func get_step_direction():
	
	# random dir
	var stepping_direction: Vector2
	var random_direction_index: int = randi() % int(4)
	match random_direction_index:
		0: stepping_direction = Vector2.LEFT
		1: stepping_direction = Vector2.UP
		2: stepping_direction = Vector2.RIGHT
		3: stepping_direction = Vector2.DOWN	
	
	return stepping_direction
	
var step_in_progress: bool = false


func step(step_direction: Vector2): # smer je nepomebna v tem primeru
	# namen: random pavza in self step (kliče sam sebe)
	
	if not current_state == States.IDLE:
		return
	
	step_in_progress = true
	
	step_direction = get_step_direction()
	var current_collider = detect_collision_in_direction(step_direction)
	
	if current_collider:
		# če še ni poskusil v vse smeri, naj proba v preostale smeri
		step_attempt += 1
		if step_attempt < 5:
			var new_direction = step_direction.rotated(deg2rad(90))
			step(new_direction)
		# če je že probal v vse smeri in koajder še zmeraj je ne poskuša več
		else: 
			step_attempt = 1 # reset za poovni step klic po random pavzi
		return
	
	current_state = States.MOVING
	
	collision_shape_ext.position = step_direction * cell_size_x # vržem koližn v smer premika

	var step_time: float = 0.2
	
	var random_pause_time_divider: float = randi() % int(5) + 1 # višji offset da manjši razpon v random času, +1 je da ni 0
	var random_pause_time = 1 / random_pause_time_divider
	var step_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		
	step_tween.tween_property(self, "position", global_position + step_direction * cell_size_x, step_time)
	step_tween.parallel().tween_property(collision_shape_ext, "position", Vector2.ZERO, step_time)
	step_tween.tween_callback(self, "end_move").set_delay(random_pause_time)


func end_move():
	
	if current_state == States.MOVING: # da se stanje resetira samo če ni STATIC al pa DYING al pa WALL
		current_state = States.IDLE
		# modulate = Color.red
	global_position = Global.snap_to_nearest_grid(global_position)
#	yield(get_tree().create_timer(1), "timeout")
	step_in_progress = false


func get_player_direction():
	pass
