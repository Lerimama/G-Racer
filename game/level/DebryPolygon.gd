extends RigidBody2D

# poda spawner
var sliced_polygon_shape: Polygon2D
var vector_from_origin: Vector2
#var distance_from_slice_origin: Vector2
	
onready var polygon_shape: Polygon2D = $Polygon2D
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D


func _ready() -> void:
	print("debry poly", self)
	polygon_shape.polygon = sliced_polygon_shape.polygon
	collision_shape.polygon = sliced_polygon_shape.polygon
	
	polygon_shape.color = Color.blue
#	polygon_shape.color = sliced_polygon_shape.color
