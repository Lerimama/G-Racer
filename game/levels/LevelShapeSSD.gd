
extends StaticBody2D


export var shape_height: float = 50 # pravo dobi iz parenta ... debelina pomeni debelino sence
export var shape_on_floor: bool =  true

export var shape_SSD_material: Resource
export var shadow_SSD_material: Resource
export var shade_SSD_material: Resource

export var use_shader_shadow: bool = true
export var shadow_casting_color: Color = Color.green

onready var object_shape: Node2D = $ObjectShapeSSD
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
onready var shadow_direction: Vector2 = Ref.game_manager.game_settings["shadows_direction"] setget _change_shadow_dir # poberi iz igre
onready var shadow_shader_rect: ColorRect = $ShadowShader


func _ready() -> void:

	# dodam glavni material
	object_shape.shape_material = shape_SSD_material
	
	# dodam senco
	if use_shader_shadow:
		# vse pobarvam s casting barvo in setam shader
		object_shape.modulate = shadow_casting_color
		# resizam rect v smeri sence
		if shadow_direction.x > 0:
			shadow_shader_rect.rect_size.x += shape_height * 2
		elif shadow_direction.x < 0:
			shadow_shader_rect.rect_size.x += shape_height * 2
			shadow_shader_rect.rect_position.x -= shape_height * 2
		if shadow_direction.y > 0:
			shadow_shader_rect.rect_size.y += shape_height * 2
		elif shadow_direction.y < 0:
			shadow_shader_rect.rect_size.y += shape_height * 2
			shadow_shader_rect.rect_position.y -= shape_height * 2
			
		# shader povečam za debelino sence v smeri sence
		shadow_shader_rect.material.set_shader_param("casting_color_1", shadow_casting_color)
		shadow_shader_rect.material.set_shader_param("casting_object_on_floor", use_shader_shadow)
		shadow_shader_rect.material.set_shader_param("shadow_distance", shape_height)
		shadow_shader_rect.material.set_shader_param("shadow_direction", shadow_direction)
	else:
		object_shape.modulate = Color.black
		var shadow_shape: Node2D = object_shape.duplicate()
		shadow_shape.name = "Shadow" 
		shadow_shape.collision_polygon_node_path = ""
		add_child(shadow_shape)
		move_child(shadow_shape, 0)
		shadow_shape.position += shadow_direction * shape_height
		shadow_shape.modulate.a = 0.2
		
	# dodam bottom shade
	var shade_shape: Node2D = object_shape.duplicate()
	shade_shape.name = "Shade" 
	shade_shape.shape_material = shade_SSD_material
	shade_shape.collision_polygon_node_path = ""
	add_child(shade_shape)
	move_child(shade_shape, 0)


	

func _change_shape_height(new_height: float):
	
	shape_height = new_height
	if has_node("Shadow"): 
		get_node("Shadow").position = shadow_direction * shape_height
	elif use_shader_shadow:
		pass
	
func _change_shadow_dir(new_direction: Vector2):
	
	shadow_direction = new_direction
	if has_node("Shadow"): 
		get_node("Shadow").position = shadow_direction * shape_height
	elif use_shader_shadow:
		shadow_shader_rect.material.set_shader_param("shadow_direction", shadow_direction)


func _on_EdgeShadows_resized() -> void:
	#	edge_shadows.material.set_shader_param("node_size", edge_shadows.rect_size)
	pass # Replace with function body.
