extends StaticBody2D


export var height: float = 30
export var elevation: float = 0
export var occlude_light: bool = true

onready var polygon_shadow: Polygon2D = $PolygonShadow2
onready var light_occluder_2d: LightOccluder2D = $LightOccluder2D
onready var collision_polygon_2d: CollisionPolygon2D = $CollisionPolygon2D


func _ready() -> void:

	# light occluder
	if occlude_light:
		var new_occluder: OccluderPolygon2D = OccluderPolygon2D.new()
		var collision_poly: PoolVector2Array = collision_polygon_2d.polygon
		new_occluder.polygon = collision_poly
		light_occluder_2d.occluder = new_occluder
		# enable
		light_occluder_2d.show()
		light_occluder_2d.occluder.cull_mode = OccluderPolygon2D.CULL_CLOCKWISE
	else:
		# disable
		light_occluder_2d.hide()
		light_occluder_2d.occluder.cull_mode = OccluderPolygon2D.CULL_DISABLED
