extends Node2D

enum SHAPES {RECT, LINE, CIRCO}
var current_slicing_shape: int = SHAPES.RECT setget _change_slicing_shape

enum TRANSFORMATIONS {SCALE, ROTATE}
var current_trans: int = TRANSFORMATIONS.SCALE setget _change_transformations

enum ACTIONS {CLICK, PAINT}
var current_action: int = ACTIONS.CLICK setget _change_action

enum SLICE_STYLE {BLAST, GRID_SQ, GRID_HEX} # enako kot ima čunk
var current_slice_style: int = SLICE_STYLE.BLAST setget _change_slice_style

var bodies_to_slice: Array
onready var slicer_area: Area2D = $SlicerArea
onready var collision_shape: CollisionPolygon2D = $SlicerArea/CollisionPolygon2D
onready var slicing_shape: Polygon2D = $SlicerArea/SlicingPoly

# hitting
var hit_vector_start: Vector2 = Vector2.ZERO
var hit_vector_end: Vector2 = Vector2.ZERO
var hitting_mode: bool = false
var hitting_line: Line2D

# neu
var action_dir_index = 1
var hitting_tick: float	= 0	


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("left_click"):
		
		if not bodies_to_slice and current_action == ACTIONS.CLICK:
			hit_vector_start = get_global_mouse_position()
			slicer_area.modulate = Color.green
			slicer_area.scale *=0.1
			hitting_line = Line2D.new()
			add_child(hitting_line)
			hitting_line.add_point(hit_vector_start)
			hitting_mode = true
			
		else:
			breakslice()

		
	if Input.is_action_just_released("left_click"):
		on_release()

					
func _ready() -> void:
	
	self.current_slicing_shape = SHAPES.RECT
	self.current_action = ACTIONS.CLICK
	self.current_trans = TRANSFORMATIONS.SCALE
	self.current_slice_style = SLICE_STYLE.BLAST


func _process(delta: float) -> void:
	
	_process_input(delta)
					
	if slicing_shape.rotation_degrees >= 360:
		slicing_shape.rotation = 0
	collision_shape.scale = slicing_shape.scale
	collision_shape.rotation = slicing_shape.rotation
	
	slicer_area.position = get_global_mouse_position()
	
	if hitting_mode:
		hitting(delta)
		
		
func _process_input(delta: float):
	
	if slicing_shape.scale.x > 2 or slicing_shape.scale.x < 0.1:
		action_dir_index *= -1
	
	if Input.is_action_pressed("left_click"):
		match current_action:
			ACTIONS.PAINT:
				for body in bodies_to_slice:
					body.on_hit(slicing_shape, get_global_mouse_position(), -1)

	elif Input.is_action_pressed("right_click"):
		match current_trans:
			TRANSFORMATIONS.SCALE:
				slicing_shape.scale += Vector2.ONE * delta * action_dir_index
			TRANSFORMATIONS.ROTATE:
				slicing_shape.rotation_degrees += delta * 100


func breakslice():
	for body in bodies_to_slice:
		match current_slice_style:
			SLICE_STYLE.BLAST:
				body.on_hit(slicing_shape, get_global_mouse_position(), SLICE_STYLE.BLAST)
			SLICE_STYLE.GRID_SQ:
				body.on_hit(slicing_shape, get_global_mouse_position(), SLICE_STYLE.GRID_SQ)
			SLICE_STYLE.GRID_HEX:
				body.on_hit(slicing_shape, get_global_mouse_position(), SLICE_STYLE.GRID_HEX)
				
				
func on_release():
	
	hit_vector_start = Vector2.ZERO
	hit_vector_end = Vector2.ZERO
	slicer_area.modulate = Color.white
	slicer_area.scale = Vector2.ONE
	if hitting_mode:
		hitting_mode = false
	
		if hitting_line:
			hitting_line.add_point(get_global_mouse_position())
			hitting_line.queue_free()
		
		
func on_hit():
	var hit_force_vector: Vector2 = hit_vector_end - hit_vector_start 
	var hit_force_pool: PoolVector2Array = [hit_vector_start, get_global_mouse_position()]
	
	var new_lines: Array
	for body in bodies_to_slice:
		body.on_hit(slicing_shape, hit_force_pool, SLICE_STYLE.GRID_HEX)
	
	hitting_mode = false
	hit_vector_start = Vector2.ZERO
	hit_vector_end = Vector2.ZERO
	slicer_area.modulate = Color.white
	slicer_area.scale = Vector2.ONE
	breakslice()
	# spawn_indikator(pos: Vector2, rot: float, parent_node: Node2D, clear_spawned_before: bool = false):
	
#	var ind = Met.spawn_indikator(get_global_mouse_position())
#	ind.scale *= 10
	
	if hitting_line:
		var new = hitting_line
		new.add_point(get_global_mouse_position())
		var line_tween = get_tree().create_tween()
		line_tween.tween_property(new, "modulate:a", 0, 0.5).set_delay(1)
		yield(line_tween, "finished")
		new.queue_free()	
	
	
func hitting(delta: float):
	
	hitting_tick += delta
	if hitting_tick >= 0.1:
#		print("dodajam", bodies_to_slice.size())
		hitting_tick = 0
		hitting_line.add_point(get_global_mouse_position())
			

# SEGETS ----------------------------------------------------------------------------


func _change_transformations(new_trans: int):
	
	var btnz = [$UILayer/Button4, $UILayer/Button5]
	for btn in btnz: 
		btn.modulate = Color.white	
		
	current_trans = new_trans
	match new_trans:
		TRANSFORMATIONS.SCALE:
			btnz[0].modulate = Color.pink
		TRANSFORMATIONS.ROTATE:
			btnz[1].modulate = Color.pink


func _change_slicing_shape(new_slicing_shape: int):
	
	var btnz = [$UILayer/Button, $UILayer/Button3, $UILayer/Button2]
	for btn in btnz: 
		btn.modulate = Color.white
		
	current_slicing_shape = new_slicing_shape
	match current_slicing_shape:
		SHAPES.RECT:
			slicing_shape.polygon = $SlicerArea/Shapes/RectPoly.polygon
			btnz[0].modulate = Color.yellow
		SHAPES.LINE:
			slicing_shape.polygon = $SlicerArea/Shapes/LinePoly.polygon
			btnz[1].modulate = Color.yellow
		SHAPES.CIRCO:
			slicing_shape.polygon = $SlicerArea/Shapes/CircoPoly.polygon
			btnz[2].modulate = Color.yellow
	collision_shape.polygon	= slicing_shape.polygon
		
	
func _change_action(new_action: int):
	
	var btnz = [$UILayer/Button6, $UILayer/Button10]
	for btn in btnz: 
		btn.modulate = Color.white	
		
	current_action = new_action
	match new_action:
		ACTIONS.CLICK:
			btnz[1].modulate = Color.orange
		ACTIONS.PAINT:
			btnz[0].modulate = Color.orange


func _change_slice_style(new_style: int):

	var btnz = [$UILayer/Button7, $UILayer/Button8, $UILayer/Button9]
	for btn in btnz: 
		btn.modulate = Color.white
			
	current_slice_style = new_style
	match current_slice_style:
		SLICE_STYLE.BLAST:
			btnz[0].modulate = Color.green
		SLICE_STYLE.GRID_SQ:
			btnz[1].modulate = Color.green
		SLICE_STYLE.GRID_HEX:
			btnz[2].modulate = Color.green
			
			
# SIGNALS ---------------------------------------------------------------------------

				
func _on_MouseArea_body_entered(body: Node) -> void:
	
	if body.has_method("on_hit"):
		bodies_to_slice.append(body)
		if hitting_mode:
			on_hit()

func _on_MouseArea_body_exited(body: Node) -> void:
	
	if body.has_method("on_hit"):
		bodies_to_slice.erase(body)
	

# SLICER SHAPES

	
func _on_Button_button_up() -> void:
	self.current_slicing_shape = SHAPES.RECT


func _on_Button3_button_up() -> void:
	self.current_slicing_shape = SHAPES.LINE
	
	
func _on_Button2_button_up() -> void:
	self.current_slicing_shape = SHAPES.CIRCO


# TRANFORMS


func _on_Button4_button_up() -> void:
	self.current_trans = TRANSFORMATIONS.SCALE


func _on_Button5_button_up() -> void:
	self.current_trans = TRANSFORMATIONS.ROTATE


# ACTIONS


func _on_Button6_button_up() -> void:
	self.current_action = ACTIONS.PAINT


func _on_Button10_button_up() -> void:
	self.current_action = ACTIONS.CLICK



# DEBRY SHAPES


func _on_Button7_button_up() -> void:
	self.current_slice_style = SLICE_STYLE.BLAST


func _on_Button8_button_up() -> void:
	self.current_slice_style = SLICE_STYLE.GRID_SQ


func _on_Button9_button_up() -> void:
	self.current_slice_style = SLICE_STYLE.GRID_HEX


