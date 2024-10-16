extends RigidBody2D


var broken_debry_polygon: PoolVector2Array
var debry_color: Color =Color.blue
var vector_from_origin: Vector2
	
onready var polygon_shape: Polygon2D = $ShapePoly
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
onready var edge_line: Line2D = $EdgeLine

func _ready() -> void:
	
	# copy points
	polygon_shape.polygon = broken_debry_polygon
	edge_line.points = polygon_shape.polygon
	collision_shape.polygon = polygon_shape.polygon
	
	# props
	polygon_shape.color = debry_color
