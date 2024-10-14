extends RigidBody2D


var sliced_polygon_points: PoolVector2Array
var debry_color: Color =Color.blue
var vector_from_origin: Vector2
#var distance_from_slice_origin: Vector2
	
onready var polygon_shape: Polygon2D = $Polygon2D
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D


func _ready() -> void:
	
	polygon_shape.polygon = sliced_polygon_points
#	collision_shape.polygon = polygon_shape.polygon
	polygon_shape.color = debry_color
	
	collision_shape.disabled = false
