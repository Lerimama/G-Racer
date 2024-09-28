extends StaticBody2D


export var altitude: float = 100
export var object_material: Resource
export var shadow_material: Resource
export var shade_material: Resource
export var shadow_direction: Vector2 = Vector2(1,1) # poberi iz igre

onready var object_shape: Node2D = $ObjectShapeSSD
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D


func _ready() -> void:

	# dodam glavni material
	object_shape.shape_material = object_material
		
	# dodam senco
	var shadow_shape: Node2D = object_shape.duplicate()
	shadow_shape.name = "Shadow" 
	shadow_shape.collision_polygon_node_path = ""
	add_child(shadow_shape)
	move_child(shadow_shape, 0)
	shadow_shape.position += shadow_direction * altitude
	shadow_shape.modulate.a = 0.2

	# dodam bottom shade
	var shade_shape: Node2D = object_shape.duplicate()
	shade_shape.name = "Shade" 
	shade_shape.shape_material = shade_material
	shade_shape.collision_polygon_node_path = ""
	add_child(shade_shape)
	move_child(shade_shape, 0)
	
