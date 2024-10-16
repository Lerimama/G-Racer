extends Node2D

enum SHAPES {RECT, LINE, CIRCO}
export (SHAPES) var current_slicing_shape: int = SHAPES.RECT setget _change_slicing_shape

enum ACTIONS {SCALE, ROTATE, PAINT}
export (ACTIONS) var current_action: int = ACTIONS.ROTATE setget _change_action

enum SPLIT_STYLE {SHAPE, GRID, STAR, PAINT}
export (SPLIT_STYLE) var current_split_style: int = SPLIT_STYLE.SHAPE setget _change_split_style

var bodies_to_slice: Array
onready var slicer_area: Area2D = $SlicerArea
onready var collision_shape: CollisionPolygon2D = $SlicerArea/CollisionPolygon2D
onready var slicing_shape: Polygon2D = $SlicerArea/SlicingPoly


func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_released("left_click"):
		var odl = slicing_shape.transform
		for body in bodies_to_slice:
			body.on_hit(slicing_shape, get_global_mouse_position())
	elif Input.is_action_just_released("right_click"):
		for body in bodies_to_slice:
			body.on_hit(slicing_shape, get_global_mouse_position())
					
					
func _ready() -> void:
	
	self.current_slicing_shape = SHAPES.RECT
	self.current_action = ACTIONS.SCALE
	self.current_split_style = SPLIT_STYLE.SHAPE
	pass


func _process(delta: float) -> void:
	
	_process_input(delta)
					
	if slicing_shape.rotation_degrees >= 360:
		slicing_shape.rotation = 0
	collision_shape.scale = slicing_shape.scale
	collision_shape.rotation = slicing_shape.rotation
	
	slicer_area.position = get_global_mouse_position()
	

func _process_input(delta: float):
	if Input.is_action_pressed("left_click"):
		match current_action:
			ACTIONS.SCALE:
				slicing_shape.scale += Vector2.ONE * delta
			ACTIONS.ROTATE:
				slicing_shape.rotation_degrees += delta * 100
			ACTIONS.PAINT:
				for body in bodies_to_slice:
					body.on_hit(slicing_shape, get_global_mouse_position())	
								
	elif Input.is_action_pressed("right_click"):
		match current_action:
			ACTIONS.SCALE:
				slicing_shape.scale -= Vector2.ONE * delta
			ACTIONS.ROTATE:
				slicing_shape.rotation_degrees += delta * 100
			ACTIONS.PAINT:
				for body in bodies_to_slice:
					body.on_hit(slicing_shape, get_global_mouse_position())	


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

func _change_split_style(new_style: int):

	var btnz = [$Button7, $Button8, $Button9]
	for btn in btnz: 
		btn.modulate = Color.white
			
	current_split_style = new_style
	match current_slicing_shape:
		SHAPES.RECT:
			slicing_shape.polygon = $SlicerArea/Shapes/RectPoly.polygon
			btnz[0].modulate = Color.green
		SHAPES.LINE:
			slicing_shape.polygon = $SlicerArea/Shapes/LinePoly.polygon
			btnz[1].modulate = Color.green
		SHAPES.CIRCO:
			slicing_shape.polygon = $SlicerArea/Shapes/CircoPoly.polygon
			btnz[2].modulate = Color.green
			
			
# SIGNALS ---------------------------------------------------------------------------

				
func _on_MouseArea_body_entered(body: Node) -> void:
	
	if body.has_method("on_hit"):
		bodies_to_slice.append(body)


func _on_MouseArea_body_exited(body: Node) -> void:
	
	if body.has_method("on_hit"):
		bodies_to_slice.erase(body)
	
	
func _on_Button_button_up() -> void:
	self.current_slicing_shape = SHAPES.RECT


func _on_Button3_button_up() -> void:
	self.current_slicing_shape = SHAPES.LINE
	
	
func _on_Button2_button_up() -> void:
	self.current_slicing_shape = SHAPES.CIRCO


func _on_Button4_button_up() -> void:
	self.current_action = ACTIONS.SCALE


func _on_Button5_button_up() -> void:
	self.current_action = ACTIONS.ROTATE
	pass # Replace with function body.


func _on_Button6_button_up() -> void:
	self.current_action = ACTIONS.PAINT
	pass # Replace with function body.
