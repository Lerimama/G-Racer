extends Node2D

enum SHAPES {RECT, LINE, CIRCO}
var current_slicing_shape: int = SHAPES.RECT setget _change_slicing_shape

enum ACTIONS {SCALE, ROTATE, PAINT}
var current_action: int = ACTIONS.ROTATE setget _change_action

enum SLICE_STYLE {BLAST, GRID_SQ, GRID_HEX} # enako kot ima čunk
var current_slice_style: int = SLICE_STYLE.BLAST setget _change_slice_style

var bodies_to_slice: Array
onready var slicer_area: Area2D = $SlicerArea
onready var collision_shape: CollisionPolygon2D = $SlicerArea/CollisionPolygon2D
onready var slicing_shape: Polygon2D = $SlicerArea/SlicingPoly


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_released("left_click"):
		var odl = slicing_shape.transform
		for body in bodies_to_slice:
			match current_slice_style:
				SLICE_STYLE.BLAST:
					body.on_hit(slicing_shape, get_global_mouse_position(), SLICE_STYLE.BLAST)
				SLICE_STYLE.GRID_SQ:
					body.on_hit(slicing_shape, get_global_mouse_position(), SLICE_STYLE.GRID_SQ)
				SLICE_STYLE.GRID_HEX:
					body.on_hit(slicing_shape, get_global_mouse_position(), SLICE_STYLE.GRID_HEX)
		
		
#	elif Input.is_action_just_released("right_click"):
#		for body in bodies_to_slice:
#			body.on_hit(slicing_shape, 2get_global_mouse_position())
					
					
func _ready() -> void:
	
	self.current_slicing_shape = SHAPES.RECT
	self.current_action = ACTIONS.SCALE
	self.current_slice_style = SLICE_STYLE.BLAST


func _process(delta: float) -> void:
	
	_process_input(delta)
					
	if slicing_shape.rotation_degrees >= 360:
		slicing_shape.rotation = 0
	collision_shape.scale = slicing_shape.scale
	collision_shape.rotation = slicing_shape.rotation
	
	slicer_area.position = get_global_mouse_position()
	

func _process_input(delta: float):
	var dir_index = 1
	if Input.is_action_pressed("left_click"):
		match current_action:
			ACTIONS.SCALE:
				slicing_shape.scale += Vector2.ONE * delta * dir_index
				if slicing_shape.scale.x > 3:
					dir_index = -1
			ACTIONS.ROTATE:
				slicing_shape.rotation_degrees += delta * 100
			ACTIONS.PAINT:
				for body in bodies_to_slice:
					body.on_hit(slicing_shape, get_global_mouse_position(), SLICE_STYLE.BLAST)
#					body.on_hit(slicing_shape, get_global_mouse_position())	
	elif Input.is_action_pressed("right_click"):
		match current_action:
			ACTIONS.SCALE:
				slicing_shape.scale -= Vector2.ONE * delta * dir_index
				if slicing_shape.scale.x < 0.5:
					dir_index = -1
			ACTIONS.ROTATE:
				slicing_shape.rotation_degrees += delta * 100
			ACTIONS.PAINT:
				for body in bodies_to_slice:
					body.on_hit(slicing_shape, get_global_mouse_position(), SLICE_STYLE.BLAST)


func _change_slicing_shape(new_slicing_shape: int):
	
	var btnz = [$Button, $Button3, $Button2]
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
	
	var btnz = [$Button4, $Button5, $Button6]
	for btn in btnz: 
		btn.modulate = Color.white	
		
	current_action = new_action
	match new_action:
		ACTIONS.SCALE:
			btnz[0].modulate = Color.orange
		ACTIONS.ROTATE:
			btnz[1].modulate = Color.orange
		ACTIONS.PAINT:
			btnz[2].modulate = Color.orange

func _change_slice_style(new_style: int):

	var btnz = [$Button7, $Button8, $Button9]
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


# ACTIONS


func _on_Button4_button_up() -> void:
	self.current_action = ACTIONS.SCALE


func _on_Button5_button_up() -> void:
	self.current_action = ACTIONS.ROTATE


func _on_Button6_button_up() -> void:
	self.current_action = ACTIONS.PAINT


# DEBRY SHAPES


func _on_Button7_button_up() -> void:
	self.current_slice_style = SLICE_STYLE.BLAST


func _on_Button8_button_up() -> void:
	self.current_slice_style = SLICE_STYLE.GRID_SQ


func _on_Button9_button_up() -> void:
	self.current_slice_style = SLICE_STYLE.GRID_HEX
