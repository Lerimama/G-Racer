
extends StaticBody2D


export var height: float = 50 setget _change_shape_height
export var elevation: float = 0
export var transparency: float = 1

onready var object_shape: Node2D = $ObjectShapeSS2D
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D


func _ready() -> void:
	pass


func _change_shape_height(new_height: float):

	height = new_height


func _on_ObjectShapeSS2D_on_dirty_update() -> void:

	$ShapeShadow.update_shadow()
