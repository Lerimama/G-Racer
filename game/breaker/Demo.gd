extends Node2D


enum SLICER_SHAPE {RECT, LINE, CIRCO}
var current_slicing_shape: int = SLICER_SHAPE.RECT setget _change_slicing_shape

enum TRANSFORMATION{SCALE, ROTATE}
var current_trans: int = TRANSFORMATION.SCALE setget _change_transformations

enum MODE {CLICK, PAINT, CUT, HIT}
var current_mode: int = MODE.CLICK setget _change_mode

enum SLICE_STYLE {ERASE, BLAST, GRID_SQ, GRID_HEX, SPIDERWEB, FRAGMENTS} # enako kot ima čunk
var current_slice_style: int = SLICE_STYLE.SPIDERWEB setget _change_slice_style

var bodies_to_slice: Array
onready var slicer_area: Area2D = $SlicerArea
onready var collision_shape: CollisionPolygon2D = $SlicerArea/CollisionPolygon2D
onready var slicing_shape: Polygon2D = $SlicerArea/SlicingPoly

# hitting
var hit_vector_start: Vector2 = Vector2.ZERO
var hit_vector_end: Vector2 = Vector2.ZERO
var hitting_mode: bool = false
var hitting_line: Line2D
var active_hitting_line: Line2D

# neu
var action_dir_index = 1
var hitting_tick: float	= 0	
var cut_vector_start: Vector2
var slicer_active: bool = true


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("left_click"):

		match current_mode:
			MODE.HIT:
				if not bodies_to_slice:
					hit_vector_start = get_global_mouse_position()
					slicer_area.modulate = Color.green
					slicer_area.scale *=0.1
					hitting_line = Line2D.new()
					add_child(hitting_line)
					hitting_line.add_point(hit_vector_start)
					hitting_mode = true
			_:
				break_it()
	
	if Input.is_action_pressed("left_click"):

		match current_mode:
			MODE.PAINT:
				for body in bodies_to_slice:
					body.on_drop(slicing_shape, get_global_mouse_position(), 0)
		
	if Input.is_action_just_released("left_click"):
		hit_vector_start = Vector2.ZERO
		hit_vector_end = Vector2.ZERO
		slicer_area.modulate = Color.white
		slicer_area.scale = Vector2.ONE
		if hitting_mode:
			hitting_mode = false
		
			if hitting_line:
				hitting_line.add_point(get_global_mouse_position())
				hitting_line.queue_free()

		
func _input_in_proces(delta: float):
	
	if Input.is_action_pressed("right_click"):
		
		match current_trans:
			TRANSFORMATION.SCALE:
				slicing_shape.scale += Vector2.ONE * delta * action_dir_index
				if slicing_shape.scale.x > 2 or slicing_shape.scale.x < 0.1:
					action_dir_index *= -1
			TRANSFORMATION.ROTATE:
				slicing_shape.rotation_degrees += delta * 100
				if slicing_shape.rotation_degrees >= 360:
					slicing_shape.rotation = 0

					
func _ready() -> void:
	
	self.current_slicing_shape = SLICER_SHAPE.RECT
	self.current_mode = MODE.CLICK
	self.current_trans = TRANSFORMATION.SCALE
	self.current_slice_style = SLICE_STYLE.BLAST


func _process(delta: float) -> void:
	
	_input_in_proces(delta)
					
	collision_shape.scale = slicing_shape.scale
	collision_shape.rotation = slicing_shape.rotation
	
	# ne follova, če je cutting acti
	if slicer_active:
		slicer_area.monitoring = true
		slicer_area.position = get_global_mouse_position()
	else:
		slicer_area.modulate.a = 0
		slicer_area.monitoring = false
		
	if hitting_mode:
		hitting_tick += delta
		if hitting_tick >= 0.1:
			hitting_tick = 0
			hitting_line.add_point(get_global_mouse_position())
		

func break_it():
	
	var break_origin: Vector2 = get_global_mouse_position()
	
	for body in bodies_to_slice:
		# adapt slicer to scale and rotation
		match current_slice_style:
			SLICE_STYLE.BLAST:
				body.on_drop(slicing_shape, break_origin, SLICE_STYLE.BLAST)
			SLICE_STYLE.GRID_SQ:
				body.on_drop(slicing_shape, break_origin, SLICE_STYLE.GRID_SQ)
			SLICE_STYLE.GRID_HEX:
				body.on_drop(slicing_shape, break_origin, SLICE_STYLE.GRID_HEX)
				
				
		
func on_hit():
	
	hit_vector_end = get_global_mouse_position()
	for body in bodies_to_slice:
		var hit_vector_pool: PoolVector2Array = [hit_vector_start, hit_vector_end]
		printt("on_hit", slicing_shape, hit_vector_pool, SLICE_STYLE.GRID_HEX)
		body.on_hit(slicing_shape, hit_vector_pool, SLICE_STYLE.GRID_HEX)
	
	
	hitting_mode = false
	
	hit_vector_start = Vector2.ZERO
	hit_vector_end = Vector2.ZERO
	slicer_area.modulate = Color.white
	slicer_area.scale = Vector2.ONE
	
	if hitting_line:
		var new = hitting_line
		new.add_point(get_global_mouse_position())
		var line_tween = get_tree().create_tween()
		line_tween.tween_property(new, "modulate:a", 0, 0.5).set_delay(1)
		yield(line_tween, "finished")
		new.queue_free()	
	
	
# SET-GET --------------------------------------------------------------------------------------------------------


func _change_transformations(new_trans: int):
	
	var btnz = [$UILayer/Button4, $UILayer/Button5]
	for btn in btnz: 
		btn.modulate = Color.white	
		
	current_trans = new_trans
	match new_trans:
		TRANSFORMATION.SCALE:
			btnz[0].modulate = Color.pink
		TRANSFORMATION.ROTATE:
			btnz[1].modulate = Color.pink


func _change_slicing_shape(new_slicing_shape: int):
	
	var btnz = [$UILayer/Button, $UILayer/Button3, $UILayer/Button2]
	for btn in btnz: 
		btn.modulate = Color.white
		
	current_slicing_shape = new_slicing_shape
	match current_slicing_shape:
		SLICER_SHAPE.RECT:
			slicing_shape.polygon = $SlicerArea/Shapes/RectPoly.polygon
			btnz[0].modulate = Color.yellow
		SLICER_SHAPE.LINE:
			slicing_shape.polygon = $SlicerArea/Shapes/LinePoly.polygon
			btnz[1].modulate = Color.yellow
		SLICER_SHAPE.CIRCO:
			slicing_shape.polygon = $SlicerArea/Shapes/CircoPoly.polygon
			btnz[2].modulate = Color.yellow
	collision_shape.polygon	= slicing_shape.polygon
		
	
func _change_mode(new_action: int):
	
	var btnz = [$UILayer/Button10, $UILayer/Button6, $UILayer/Button11, $UILayer/Button12]
	for btn in btnz: 
		btn.modulate = Color.white	
		
	current_mode = new_action
	match new_action:
		MODE.CLICK:
			btnz[0].modulate = Color.orange
		MODE.PAINT:
			btnz[1].modulate = Color.orange
		MODE.CUT:
			btnz[2].modulate = Color.orange
		MODE.HIT:
			btnz[3].modulate = Color.orange


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
			
			
# SIGNALS --------------------------------------------------------------------------------------------------------

				
func _on_MouseArea_body_entered(body: Node) -> void:
	
	if body.has_method("on_hit"):
		bodies_to_slice.append(body)
		if hitting_mode:
			on_hit()

func _on_MouseArea_body_exited(body: Node) -> void:
	
	bodies_to_slice.erase(body)


# BTNS --------------------------------------------------------------------------------------------------------
	

# SLICER SHAPES
func _on_Button_button_up() -> void:
	self.current_slicing_shape = SLICER_SHAPE.RECT
func _on_Button3_button_up() -> void:
	self.current_slicing_shape = SLICER_SHAPE.LINE
func _on_Button2_button_up() -> void:
	self.current_slicing_shape = SLICER_SHAPE.CIRCO

# TRANFORMS
func _on_Button4_button_up() -> void:
	self.current_trans = TRANSFORMATION.SCALE
func _on_Button5_button_up() -> void:
	self.current_trans = TRANSFORMATION.ROTATE

# MODE
func _on_Button10_button_up() -> void:
	self.current_mode = MODE.CLICK
func _on_Button6_button_up() -> void:
	self.current_mode = MODE.PAINT
func _on_Button11_button_up() -> void:
	self.current_mode = MODE.CUT
func _on_Button12_button_up() -> void:
	self.current_mode = MODE.HIT

# SLICE_STYLE
func _on_Button7_button_up() -> void:
	self.current_slice_style = SLICE_STYLE.BLAST
func _on_Button8_button_up() -> void:
	self.current_slice_style = SLICE_STYLE.GRID_SQ
func _on_Button9_button_up() -> void:
	self.current_slice_style = SLICE_STYLE.GRID_HEX
