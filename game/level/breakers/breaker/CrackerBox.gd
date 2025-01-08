extends ColorRect


signal cracks_animation_finished # ne dela

var cracks_color = Color.black
var crackers_reveal_time: float = 0.5

# poda spawner ob spawnu
var breaker_position: Vector2
var break_origin_global: Vector2
var cracked_polygons: Array
var chunk_polygon: PoolVector2Array
var breaker_shape: Polygon2D

onready var Cracker: PackedScene = preload("res://game/level/breakers/breaker/Cracker.tscn")
onready var crackers_parent: Node2D = $CrackersParent


func _ready() -> void:
	_spawn_crackers()


func _spawn_crackers():

	# chunk rect za animacijo maske
	var chunk_far_points: Array = get_polygon_far_points(chunk_polygon) # L-T-R-B
	var chunk_position: Vector2 = Vector2(chunk_far_points[0].x, chunk_far_points[1].y)
	var chunk_size: Vector2 = Vector2(chunk_far_points[2].x, chunk_far_points[3].y) - chunk_position

	for poly_index in cracked_polygons.size():
		var new_cracker: Polygon2D = Cracker.instance()
		new_cracker.position -= chunk_position
		new_cracker.polygon = cracked_polygons[poly_index]
		new_cracker.name = "%s_Cracker" % name
		new_cracker.cracker_color = breaker_shape.color
		new_cracker.crack_color = cracks_color
		crackers_parent.add_child(new_cracker)
		if breaker_shape.texture:
			_copy_texture_between_shapes(new_cracker, breaker_shape)

	# dobim pozicije za animacijo
	var start_mask_size: Vector2 # lahko je 0 ali pa hor / ver razširjena
	var start_mask_position: Vector2 # začne v slice-originu v breakerju slice z size 0
	var start_crackers_position: Vector2 # razlika med začetnoin končno pozicijo maske (slice-origin pos in chunk pos)
	var end_mask_position: Vector2 = chunk_position # pozicija izvora znotraj brejkerja
	var end_mask_size: Vector2 = chunk_size
	var end_crackers_position: Vector2 = Vector2.ZERO # konča na svoji def poziciji znotraj maske (0,0)

	if break_origin_global == Vector2.ZERO:
		start_mask_size = Vector2.ZERO
		start_mask_position = break_origin_global - breaker_position # origin pozicija lokalno
		start_crackers_position = end_mask_position - start_mask_position
	else:
		start_mask_position = chunk_position # pozicija izvora znotraj brejkerja
		start_mask_size = Vector2(end_mask_size.x, 0)
		start_crackers_position = crackers_parent.position

	# apliciram pozicije pred animacijo
	crackers_parent.position = start_crackers_position
	rect_position = start_mask_position
	rect_size = start_mask_size

	# animiram ... istočasno tweenam rect masko in crackers parenta ... crackerji zgledajo pri miru
	var reveal_tween = get_tree().create_tween().set_ease(Tween.EASE_IN)#.set_trans(Tween.TRANS_QUART)
	reveal_tween.tween_property(self, "rect_size", end_mask_size, crackers_reveal_time)
	reveal_tween.parallel().tween_property(self, "rect_position", end_mask_position, crackers_reveal_time)
	reveal_tween.parallel().tween_property(crackers_parent, "position", end_crackers_position, crackers_reveal_time)
	yield(reveal_tween, "finished")

	emit_signal("cracks_animation_finished") # ne dela

	# pucam krekerje po animaciji
	for child in crackers_parent.get_children():
		child.queue_free()


func get_polygon_far_points(polygon_points: PoolVector2Array):

	var points_to_sort: Array = polygon_points

	# x
	points_to_sort.sort_custom(self, "sort_vectors_by_x")
	var far_right_point: Vector2 = points_to_sort[0]
	var far_left_point: Vector2 = points_to_sort[points_to_sort.size() - 1]

	# Y
	points_to_sort.sort_custom(self, "sort_vectors_by_y")
	var far_down_point: Vector2 = points_to_sort[0]
	var far_up_point: Vector2 = points_to_sort[points_to_sort.size() - 1]

	var far_points: Array = [far_left_point, far_up_point, far_right_point, far_down_point]

	return far_points


func _copy_texture_between_shapes(copy_to: Polygon2D, copy_from: Polygon2D):

	copy_to.texture = copy_from.texture
	copy_to.texture_offset = copy_from.texture_offset
	copy_to.rotation_degrees = copy_from.rotation_degrees
	copy_to.texture_scale = copy_from.texture_scale
