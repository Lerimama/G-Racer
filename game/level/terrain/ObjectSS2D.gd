
extends StaticBody2D


export var height: float = 50 setget _change_shape_height
export var elevation: float = 0

onready var object_shape: Node2D = $ObjectShapeSS2D
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D



func _change_shape_height(new_height: float):

	height = new_height


func _on_ObjectShapeSS2D_on_dirty_update() -> void:

	$ShapeShadows.update_all_shadows()
