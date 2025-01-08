extends Area2D


enum MOTION {STILL, EXPLODE, FALL, MINIMIZE, DISSAPEAR} # SLIDE, CRACK, SHATTER
var current_motion: int = MOTION.STILL setget _on_change_motion

export var height = 500 # setget
export var elevation = 0 # setget
export var transparency: float = 1 # setget
export (int) var shape_edge_width: float = 0 setget _on_change_shape_edge_width

var break_origin_global: Vector2 = Vector2.ZERO # se inherita skozi vse spawne
var shape_edge_color: Color = Color.black
var shape_polygon: PoolVector2Array = [] setget _on_change_shape # !!! polygon menjam samo prek tega setgeta

# polygons
onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
onready var edge_shape: Polygon2D = $DebryShape/EdgeShape
onready var debry_shape: Polygon2D = $DebryShape

# nodes
var breaker_debry_world: Node


func _ready() -> void:

	# določim svet spawnanja
	if breaker_debry_world == null:
		breaker_debry_world = get_parent()

	# če ni podana oblika, izbere defaultno
	if shape_polygon.empty():
		#		print("shape_polygon empty")
		self.shape_polygon = debry_shape.polygon
	# če je podana oblika, jo prevzame
	else:
		#		print("shape_polygon true")
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

	current_motion =  new_motion_state

	# _temp
#	if not current_motion == MOTION.STILL:
#		current_motion =  MOTION.MINIMIZE

	printt("AreaDebry MOTION", name, MOTION.keys()[current_motion])

	match current_motion:
		MOTION.STILL:
			pass
#			mode = RigidBody2D.MODE_STATIC
#			set_deferred("mode", RigidBody2D.MODE_STATIC)
		MOTION.FALL:
			pass
#			gravity_scale = 1
#			set_deferred("mode", RigidBody2D.MODE_RIGID)
		MOTION.EXPLODE:
			pass
#			gravity_scale = 0
##			mode = RigidBody2D.MODE_RIGID
#			set_deferred("mode", RigidBody2D.MODE_RIGID)
#			linear_damp = 2
			var force_vector = global_position - break_origin_global
#			apply_central_impulse(force_vector * 20)
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
