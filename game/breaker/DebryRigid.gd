extends RigidBody2D


var debry_polygon: PoolVector2Array
var debry_color: Color =Color.blue
var vector_from_origin: Vector2
	
onready var debry_shape: Polygon2D = $DebryShape
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
onready var edge_line: Line2D = $EdgeLine


func _ready() -> void:
	
	# copy points
	debry_shape.polygon = debry_polygon
	edge_line.points = debry_shape.polygon
	collision_shape.polygon = debry_shape.polygon
	
	# props
	debry_shape.color = debry_color
