extends Area2D


enum MOTION {STILL, EXPLODE, FALL, MINIMIZE, DISSAPEAR} # SLIDE, CRACK, SHATTER
var current_motion: int = MOTION.STILL setget _on_change_motion

export var height = 500 # setget
export var elevation = 0 # setget
export var transparency: float = 1 # setget
export (int) var shape_edge_width: float = 0 setget _on_change_shape_edge_width

var shape_polygon: PoolVector2Array = [] setget _on_change_shape # !!! polygon menjam samo prek tega setgeta
var break_origin_global: Vector2 = Vector2.ZERO # se inherita skozi vse spawne
var shape_edge_color: Color = Color.black
var debry_owner: Node2D # original lastnik delca ... poda brejker ob spawnu

# polygons
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
onready var edge_shape: Polygon2D = $DebryShape/EdgeShape
onready var debry_shape: Polygon2D = $DebryShape



func _ready() -> void:

	# če ni podana oblika, izbere defaultno
	if shape_polygon.empty():
		self.shape_polygon = debry_shape.polygon
	# če je podana oblika, jo prevzame
	else:
		self.shape_polygon = shape_polygon

	self.current_motion = current_motion
	self.shape_edge_width = shape_edge_width
	edge_shape.color =  shape_edge_color


func _on_change_shape(new_breaker_polygon: PoolVector2Array):

	shape_polygon = new_breaker_polygon
	debry_shape.polygon = shape_polygon
	edge_shape.polygon = shape_polygon
	self.shape_edge_width = shape_edge_width
	collision_shape.set_deferred("polygon", shape_polygon)

	$PolygonShadow._update_shadow_polygon()


func _on_change_motion(new_motion_state: int):
	# animacije so enake kot v breakerju

	current_motion =  new_motion_state

	# _temp
#	if not current_motion == MOTION.STILL:
	current_motion =  MOTION.MINIMIZE

	printt("Debry Area MOTION", MOTION.keys()[current_motion])

	match current_motion:
		MOTION.STILL:
			pass
		MOTION.FALL:
			print("animate debry FALL")
			pass
		MOTION.EXPLODE:
			print("animate debry EXPLOSION")
			pass
			var force_vector = global_position - break_origin_global
		MOTION.DISSAPEAR:
			randomize()
			var random_duration: float = (randi() % 5 + 5)/10.0
			var random_delay: float = (randi() % 3)/10
			var dissolve_tween = get_tree().create_tween()
			dissolve_tween.tween_property(self, "modulate:a", 0, random_duration).set_delay(random_delay)
			yield(dissolve_tween, "finished")
			queue_free()
		MOTION.MINIMIZE:
			randomize()
			var random_duration: float = (randi() % 5 + 5)/10.0
			var random_delay: float = (randi() % 3)/10
			var minimize_tween = get_tree().create_tween()
			minimize_tween.tween_property(self, "scale", Vector2.ZERO, random_duration).set_delay(random_delay)
			yield(minimize_tween, "finished")
			queue_free()
		MOTION.CRACK:
			print("animate debry CRACK")
			pass


func _on_change_shape_edge_width(new_width: float):

	if edge_shape:
		var offset_polygons: Array = Geometry.offset_polygon_2d(edge_shape.polygon, new_width)
		if offset_polygons.size() == 1:
			edge_shape.polygon = offset_polygons[0]
			shape_edge_width = new_width # šele tukaj, da ne morem setat, če je error
		else:
			shape_edge_width = new_width / 2
			#			printt("Breaker offset to big (multiple inset_polygons) ... polovička", shape_edge_width)


func _on_VisibilityNotifier2D_screen_exited() -> void:

	queue_free()
