extends Node2D

# menu
enum SLICER_SHAPE {RECT, LINE, CIRCO}
var current_slicing_shape: int = SLICER_SHAPE.RECT setget _change_slicing_shape

enum TRANSFORMATION{SCALE, ROTATE}
var current_trans: int = TRANSFORMATION.ROTATE setget _change_transformations

enum TOOL {KNIFE, HAMMER, PAINT, ROCKET}
var current_tool: int = TOOL.HAMMER setget _change_tool

var transform_dir_index = 1
var bodies_to_slice: Array = []
onready var slicer: Area2D = $Slicer
onready var slicer_shape: Polygon2D = $Slicer/SlicingPoly
onready var collision_shape: CollisionPolygon2D = $Slicer/CollisionPolygon2D

# action
var swipe_in_progress: bool = false
var swipe_start_global_position: Vector2 # na klik
var active_swiping_line: Line2D # zadnja spawnana linija
var swiping_line_delta: float = 0	
var swiping_line_tick: float = 0.1 # gostota ... če je manj, so težave pri zaznavanju reze
	
# power
var loading_power: bool = false

# scaling
var default_slicer_scale = Vector2.ONE
var max_slicer_scale = Vector2.ONE * 3
var min_slicer_scale = Vector2.ONE * 0.1

var swipe_scale = 0.1
var scale_max = 3
var breakers_count: int = 0


func _input(event: InputEvent) -> void:
	
	
	if Input.is_action_just_pressed("R"):
		_on_Reset_button_up()
	if Input.is_action_just_pressed("no4"):
		print (bodies_to_slice)
	elif Input.is_action_just_pressed("left_click"):
		on_click()
	elif Input.is_action_pressed("left_click"):
		match current_tool:
			TOOL.PAINT:
				for body in bodies_to_slice:
					body.on_hit(get_global_mouse_position(), slicer)
	elif Input.is_action_just_released("left_click"):
		on_release()
		
					
func _ready() -> void:
	
	self.current_slicing_shape = current_slicing_shape
	self.current_tool = current_tool
	self.current_trans = current_trans
#	self.current_slice_style = current_slice_style


func _process(delta: float) -> void:
	
	breakers_count = get_tree().get_nodes_in_group("Breakers").size()
	$UILayer/Count.text = "SHAPES COUNT: %s" % str(breakers_count)
	
	if Input.is_action_pressed("right_click"):
		if current_tool != TOOL.HAMMER:
			transform_slicer(delta)
	collision_shape.scale = slicer_shape.scale
	collision_shape.rotation = slicer_shape.rotation	
	
	slicer.position = get_global_mouse_position()
	
	# slicing line points
	if swipe_in_progress and current_tool == TOOL.KNIFE:
		swiping_line_delta += delta
		if swiping_line_delta >= swiping_line_tick:
			swiping_line_delta = 0
			active_swiping_line.add_point(get_global_mouse_position())
	
		
func on_release():
	
	if swipe_in_progress:
		slicer.show()
		slicer_shape.scale = Vector2.ONE	
		finish_swipe()
	
			
func on_click():
		
	swipe_start_global_position = get_global_mouse_position()
	
	match current_tool:
		TOOL.HAMMER:
			if not bodies_to_slice:
				start_swipe()
		TOOL.KNIFE:
			if not bodies_to_slice:
				start_swipe()
			else:
				var break_origin: Vector2 = get_global_mouse_position()
				for body in bodies_to_slice:
					body.on_hit(break_origin, slicer)
		_:
			var break_origin: Vector2 = get_global_mouse_position()
			for body in bodies_to_slice:
				body.on_hit(break_origin, slicer)
	
	# collision transform ... če tega dela ni se koližn resiza neusklajeno
	collision_shape.polygon = slicer_shape.polygon
	collision_shape.scale = slicer_shape.scale
	collision_shape.rotation = slicer_shape.rotation
	
				
func start_swipe():
	
	if current_tool == TOOL.KNIFE:
		slicer_shape.scale = default_slicer_scale * 0.01	
		slicer.hide()
	swipe_in_progress = true	
	spawn_slicing_line()


func finish_swipe(is_successful: bool = false):

	swipe_in_progress = false
	var swiping_line_last_point: Vector2 = get_global_mouse_position()
	# slicing line editiram po drugim imeno, da lahko med tem manipuliram drugo aktivno linijo
	var fading_slicing_line: Line2D = active_swiping_line
	if fading_slicing_line:
		fading_slicing_line.add_point(swiping_line_last_point)
	
	match current_tool:
		TOOL.HAMMER:
			if is_successful:
				is_successful = false
				slicer_shape.scale = default_slicer_scale # da lažje izračunam moč
				for body in bodies_to_slice:
					var hit_vector_pool: PoolVector2Array = [swipe_start_global_position, swiping_line_last_point]
					body.on_hit(hit_vector_pool, slicer) 
				slicer_shape.scale = min_slicer_scale
				var fade_tween = get_tree().create_tween()
				fade_tween.tween_property(fading_slicing_line, "modulate:a", 0, 0.5).set_delay(1)
				yield(fade_tween, "finished")
			if fading_slicing_line:
				fading_slicing_line.queue_free()
				
		TOOL.KNIFE:
			for body in bodies_to_slice:
				var hit_vector_pool: PoolVector2Array = [swipe_start_global_position, swiping_line_last_point]
				var cutting_pool: PoolVector2Array = fading_slicing_line.points
				body.on_hit(fading_slicing_line)
#				body.on_cut(fading_slicing_line)
			if fading_slicing_line:
				fading_slicing_line.queue_free()
#			slicer_shape.scale = default_slicer_scale
			
			
# UTILITI --------------------------------------------------------------------------------------------------------


func transform_slicer(delta: float):

		match current_trans:
			TRANSFORMATION.SCALE:
				if slicer_shape.scale > max_slicer_scale:
					transform_dir_index = -1
				elif slicer_shape.scale < min_slicer_scale:
					transform_dir_index = 1
				slicer_shape.scale += Vector2.ONE * delta * transform_dir_index * 2
					
			TRANSFORMATION.ROTATE:
				slicer_shape.rotation_degrees += delta * 100
				if slicer_shape.rotation_degrees >= 360:
					slicer_shape.rotation = 0
		
			
func spawn_slicing_line():
	
	# line spawn
	var new_slicing_line = Line2D.new()
	add_child(new_slicing_line)
	new_slicing_line.add_point(swipe_start_global_position)
	
	# postane trenutno aktivna
	active_swiping_line = new_slicing_line
	
	
# SET-GET --------------------------------------------------------------------------------------------------------
	
	
func _change_tool(new_tool: int):
	
	var btnz = [$UILayer/Button10, $UILayer/Button6, $UILayer/Button11, $UILayer/Button12]
	for btn in btnz: 
		btn.modulate = Color.white	
	slicer.scale = default_slicer_scale # zazih	
	slicer_shape.scale = default_slicer_scale # zazih	
	current_tool = new_tool
	slicer.tool_type = current_tool
	
	# setam default slicerja, ki ga glede na mode spremenim
	current_slicing_shape = SLICER_SHAPE.RECT
	match current_tool:
		TOOL.PAINT:
			btnz[1].modulate = Color.orange
			slicer_shape.scale = default_slicer_scale
		TOOL.KNIFE:
			btnz[2].modulate = Color.orange
			slicer.modulate.a = 0.5
		TOOL.HAMMER:
			btnz[3].modulate = Color.orange
			slicer_shape.scale = min_slicer_scale
			
			self.current_trans = TRANSFORMATION.SCALE		
			self.current_slicing_shape = SLICER_SHAPE.CIRCO


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
			slicer_shape.polygon = $Slicer/Shapes/RectPoly.polygon
			btnz[0].modulate = Color.yellow
		SLICER_SHAPE.LINE:
			slicer_shape.polygon = $Slicer/Shapes/LinePoly.polygon
			btnz[1].modulate = Color.yellow
		SLICER_SHAPE.CIRCO:
			slicer_shape.polygon = $Slicer/Shapes/CircoPoly.polygon
			btnz[2].modulate = Color.yellow
	collision_shape.polygon	= slicer_shape.polygon
		

# SIGNALS --------------------------------------------------------------------------------------------------------

				
func _on_MouseArea_body_entered(body: Node) -> void:
	
	if "current_material" in body:
#		if not body.current_material == body.MATERIAL.UNBREAKABLE: 
		if not bodies_to_slice.has(body):
			bodies_to_slice.append(body)
		if current_tool == TOOL.HAMMER and swipe_in_progress:
			finish_swipe(true)


func _on_MouseArea_body_exited(body: Node) -> void:

	if body.has_method("on_hit") and current_tool == TOOL.KNIFE and swipe_in_progress:
		pass
	else:
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

# TOOL
var gravity_force_multiplier: int = 1
func _on_Button10_button_up() -> void:
	
	gravity_force_multiplier += 1
	if gravity_force_multiplier > 1:
		gravity_force_multiplier = -1
	
	# Set the default gravity strength to 98.
	$UILayer/Button10.text = "GRAVITY: %01d" % gravity_force_multiplier
	Physics2DServer.area_set_param(get_viewport().find_world_2d().get_space(), Physics2DServer.AREA_PARAM_GRAVITY, 98 * gravity_force_multiplier)

func _on_Button6_button_up() -> void:
	self.current_tool = TOOL.PAINT
func _on_Button11_button_up() -> void:
	self.current_tool = TOOL.KNIFE
func _on_Button12_button_up() -> void:
	self.current_tool = TOOL.HAMMER

# SLICE_STYLE
func _on_Button7_button_up() -> void:
#	self.current_slice_style = SLICE_STYLE.BLAST
	pass
func _on_Button8_button_up() -> void:
#	self.current_slice_style = SLICE_STYLE.GRID_SQ
	pass
func _on_Button9_button_up() -> void:
#	self.current_slice_style = SLICE_STYLE.GRID_HEX
	pass

# reset
func _on_Reset_button_up() -> void:
	get_tree().reload_current_scene()
