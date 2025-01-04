extends Area2D

# imitacija lastnosti hitting noda v igri

var tool_type: int = 0 
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
onready var slicing_poly: Polygon2D = $SlicingPoly


func _ready() -> void:
	pass
