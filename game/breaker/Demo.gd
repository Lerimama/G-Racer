extends Node2D


enum SLICER_SHAPE {RECT, LINE, CIRCO}
var current_slicing_shape: int = SLICER_SHAPE.RECT setget _change_slicing_shape

enum TRANSFORMATION{SCALE, ROTATE}
var current_trans: int = TRANSFORMATION.SCALE setget _change_transformations

enum TOOL {HAMMER, BOMB, PAINT, KNIFE,}
enum MODE {DROP, PAINT, CUT, SMACK}
var current_mode: int = MODE.CUT setget _change_mode

enum SLICE_STYLE {ERASE, BLAST, GRID_SQ, GRID_HEX, SPIDERWEB, FRAGMENTS} # enako kot ima čunk
var current_slice_style: int = SLICE_STYLE.SPIDERWEB setget _change_slice_style

var transform_dir_index = 1
var bodies_to_slice: Array
onready var slicer: Area2D = $SlicerArea
onready var slicer_shape: Polygon2D = $SlicerArea/SlicingPoly
onready var collision_shape: CollisionPolygon2D = $SlicerArea/CollisionPolygon2D

# action
var smack_in_progress: bool = false
var active_slicing_line: Line2D # zadnja spawnana linija
var slicing_line_delta: float = 0	
var slicing_line_tick: float = 0.1 # gostota ... če je manj, so težave pri zaznavanju reze
var slicing_start_global_position: Vector2 # na klik
	
			
func _input(event: InputEvent) -> void:
	
	
	if Input.is_action_just_pressed("R"):
		_on_Reset_button_up()
	if Input.is_action_just_pressed("left_click"):
		slicing_start_global_position = get_global_mouse_position()
		
		match current_mode:
			MODE.SMACK, MODE.CUT:
#				print ("msak", bodies_to_slice,get_tree().get_nodes_in_group(grupa))
#				if get_tree().get_nodes_in_group(grupa).empty(): # _temp smack with bodies in ... popedenaj tudi area signal
				if not bodies_to_slice: # _temp smack with bodies in ... popedenaj tudi area signal
					start_smack()
			_:
				break_it()
	
	if Input.is_action_pressed("left_click"):
		match current_mode:
			MODE.PAINT:
				for body in bodies_to_slice:
					body.on_hit(slicer_shape, get_global_mouse_position(), 0)
		
	if Input.is_action_just_released("left_click"):
		if smack_in_progress:
			end_smack()

					
func _ready() -> void:
	
	self.current_slicing_shape = current_slicing_shape
	self.current_mode = current_mode
	self.current_trans = current_trans
	self.current_slice_style = current_slice_style


func _process(delta: float) -> void:
	
	if Input.is_action_pressed("right_click"):
		match current_trans:
			TRANSFORMATION.SCALE:
				slicer_shape.scale += Vector2.ONE * delta * transform_dir_index
				if slicer_shape.scale.x > 2 or slicer_shape.scale.x < 0.1:
					transform_dir_index *= -1
			TRANSFORMATION.ROTATE:
				slicer_shape.rotation_degrees += delta * 100
				if slicer_shape.rotation_degrees >= 360:
					slicer_shape.rotation = 0
	
					
	collision_shape.scale = slicer_shape.scale
	collision_shape.rotation = slicer_shape.rotation
	slicer.position = get_global_mouse_position()
	
	# slicing line points
	if smack_in_progress:
		slicing_line_delta += delta
		if slicing_line_delta >= slicing_line_tick:
			slicing_line_delta = 0
			active_slicing_line.add_point(get_global_mouse_position())
		

func break_it():
	
	var break_origin: Vector2 = get_global_mouse_position()

#	get_tree().call_group(grupa, "on_hit", slicer_shape, break_origin, current_slice_style)
#	print (get_tree().get_nodes_in_group(grupa))
#	for body in get_tree().get_nodes_in_group(grupa):
#		body.on_hit(slicer_shape, break_origin, current_slice_style)
	for body in bodies_to_slice:
		body.on_hit(slicer_shape, break_origin, current_slice_style)
	
				
func start_smack():
	
	smack_in_progress = true	
	spawn_slicing_line()


func end_smack(is_successful: bool = false):
	
	var slicing_end_global_position: Vector2 = get_global_mouse_position()
	smack_in_progress = false
	# slicing line editiram po drugim imeno, da lahko med tem manipuliram drugo aktivno linijo
	var fading_slicing_line: Line2D = active_slicing_line
	if fading_slicing_line:
		fading_slicing_line.add_point(slicing_end_global_position)
	
	match current_mode:
		MODE.SMACK:
			if is_successful:
				for body in bodies_to_slice:
					var hit_vector_pool: PoolVector2Array = [slicing_start_global_position, slicing_end_global_position]
					body.on_hit(slicer_shape, hit_vector_pool, SLICE_STYLE.GRID_HEX) 
				
					var fade_tween = get_tree().create_tween()
					fade_tween.tween_property(fading_slicing_line, "modulate:a", 0, 0.5).set_delay(1)
					yield(fade_tween, "finished")
				bodies_to_slice.clear()
			if fading_slicing_line:
				fading_slicing_line.queue_free()
		MODE.CUT:
			for body in bodies_to_slice:
				var hit_vector_pool: PoolVector2Array = [slicing_start_global_position, slicing_end_global_position]
				var cutting_pool: PoolVector2Array = fading_slicing_line.points
				body.on_hit(fading_slicing_line)
			bodies_to_slice.clear()
			if fading_slicing_line:
				fading_slicing_line.queue_free()
	
	
# SET-GET --------------------------------------------------------------------------------------------------------
	
	
func _change_mode(new_mode: int):
	
	var btnz = [$UILayer/Button10, $UILayer/Button6, $UILayer/Button11, $UILayer/Button12]
	for btn in btnz: 
		btn.modulate = Color.white	
		
	current_mode = new_mode
	
	# setam default slicerja, ki ga glede na mode spremenim
	slicer.scale = Vector2.ONE
	match current_mode:
		MODE.DROP:
			btnz[0].modulate = Color.orange
			slicer.modulate = Color.white
		MODE.PAINT:
			btnz[1].modulate = Color.orange
			slicer.scale *= 0.5
			slicer.modulate = Color.yellow
		MODE.CUT:
			btnz[2].modulate = Color.orange
			slicer.modulate = Color.blue
			slicer.scale *= 0.01
			
			slicer.modulate.a = 0
		MODE.SMACK:
			btnz[3].modulate = Color.orange
			slicer.modulate = Color.green
			slicer.scale *= 0.1


func _change_transformations(new_trans: int):
	
	var btnz = [$UILayer/Button4, $UILayer/Button5]
	for btn in btnz: 
		btn.modulate = Color.white	
		
	current_trans = new_trans
	match current_trans:
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
			slicer_shape.polygon = $SlicerArea/Shapes/RectPoly.polygon
			btnz[0].modulate = Color.yellow
		SLICER_SHAPE.LINE:
			slicer_shape.polygon = $SlicerArea/Shapes/LinePoly.polygon
			btnz[1].modulate = Color.yellow
		SLICER_SHAPE.CIRCO:
			slicer_shape.polygon = $SlicerArea/Shapes/CircoPoly.polygon
			btnz[2].modulate = Color.yellow
	collision_shape.polygon	= slicer_shape.polygon
		

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
			
			
# UTILITI --------------------------------------------------------------------------------------------------------

			
func spawn_slicing_line():
	
	# line spawn
	var new_slicing_line = Line2D.new()
	add_child(new_slicing_line)
	new_slicing_line.add_point(slicing_start_global_position)
	
	# postane trenutno aktivna
	active_slicing_line = new_slicing_line
	

# SIGNALS --------------------------------------------------------------------------------------------------------

				
func _on_MouseArea_body_entered(body: Node) -> void:
	
	if body.has_method("on_hit"):
		if not bodies_to_slice.has(body):
			bodies_to_slice.append(body)
		if not body.is_in_group(grupa):
			body.add_to_group(grupa)
		if current_mode == MODE.SMACK and smack_in_progress:
			end_smack(true)

var grupa: String = "grupa"

func _on_MouseArea_body_exited(body: Node) -> void:

	if body.has_method("on_hit") and current_mode == MODE.CUT and smack_in_progress:
		pass
	else:
		bodies_to_slice.erase(body)
		body.remove_from_group(grupa)
		


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
	self.current_mode = MODE.DROP
func _on_Button6_button_up() -> void:
	self.current_mode = MODE.PAINT
func _on_Button11_button_up() -> void:
	self.current_mode = MODE.CUT
func _on_Button12_button_up() -> void:
	self.current_mode = MODE.SMACK

# SLICE_STYLE
func _on_Button7_button_up() -> void:
	self.current_slice_style = SLICE_STYLE.BLAST
func _on_Button8_button_up() -> void:
	self.current_slice_style = SLICE_STYLE.GRID_SQ
func _on_Button9_button_up() -> void:
	self.current_slice_style = SLICE_STYLE.GRID_HEX

# reset
func _on_Reset_button_up() -> void:
	get_tree().reload_current_scene()
