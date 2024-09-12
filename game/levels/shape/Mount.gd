extends StaticBody2D


export var altitude: float = 100
var shadow_direction: Vector2 = Vector2.DOWN

onready var shape_line: Node2D = $Shape
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
onready var shape_material: Resource = preload("res://game/levels/shape/mount_shade.tres")

func _ready() -> void:
	
	# dodam senco
	var shadow_line: Node2D = shape_line.duplicate()
	shadow_line.name = "Shadow" 
	shadow_line.collision_polygon_node_path = ""
	add_child(shadow_line)
	move_child(shadow_line, 0)
	shadow_line.position += shadow_direction * altitude
	shadow_line.modulate.a = 0.2

	# dodam bottom shade
	var shade_line: Node2D = shape_line.duplicate()
	shade_line.name = "Shade" 
	shade_line.shape_material = shape_material
	shade_line.collision_polygon_node_path = ""
	add_child(shade_line)
	move_child(shade_line, 0)
	

	pass
