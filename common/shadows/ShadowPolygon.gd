extends Polygon2D


export (NodePath) var shadow_casting_polygon_path: String
export var shadow_z_index: int = 0 # samo, če rabiš spcifičnega

#onready var shadow_owner: Node2D = get_parent()
onready var shadow_owner: Node2D = get_parent()
onready var shadow_casting_node: Node2D = get_node(shadow_casting_polygon_path)

# od ownerja, igre in obeh
onready var shadow_offset: float = shadow_owner.elevation
onready var shadow_direction: Vector2 = Refs.game_manager.shadows_direction_from_source.normalized() setget _on_direction_change
onready var shadow_color: Color = Refs.game_manager.shadows_color_from_source
onready var shadow_alpha: float = Refs.game_manager.shadows_alpha_from_source * shadow_owner.transparency
onready var shadow_length: float = (shadow_owner.height + shadow_offset) * Refs.game_manager.shadows_length_from_source

var shadow_angle_degrees: float setget _on_angle_change # za animirano rotacijo rabim kot


func _on_angle_change(new_angle: float):

	printt("prej", shadow_angle_degrees, shadow_direction.angle(), shadow_direction)
	shadow_angle_degrees = new_angle
	shadow_direction = Vector2.RIGHT.rotated(deg2rad(shadow_angle_degrees))
	_update_shadow()

	printt("rotiram", shadow_angle_degrees, shadow_direction.angle(), shadow_direction)

func _on_direction_change(new_direction: Vector2):
	print("d", shadow_owner.name, shadow_direction, new_direction)
	shadow_direction = new_direction.normalized()
	print("after", shadow_direction, new_direction)
	_update_shadow()


func _ready() -> void:

	add_to_group(Refs.group_shadows)

	# z index
	if shadow_z_index == 0:
		z_index = Pros.z_indexes[Refs.group_shadows]
	else:
		z_index = shadow_z_index

	# popravim rotacijo sence glede na globalno rotacijo poligona
	shadow_direction = shadow_direction.rotated(-global_rotation)

	# shadows
	if shadow_casting_node:

		_update_shadow()
	else:
		printerr ("Shadow casting missing: ", self)
		hide()


func _update_shadow(with_shape_update: bool = true):
#	print("shadow update")

	# pogrebam nove nastavitve
	shadow_offset = shadow_owner.elevation
	shadow_length = (shadow_owner.height + shadow_offset) * Refs.game_manager.shadows_length_from_source
	shadow_alpha = Refs.game_manager.shadows_alpha_from_source * shadow_owner.transparency
	#	shadow_direction = Refs.game_manager.shadows_direction_from_source.normalized()
	shadow_color = Refs.game_manager.shadows_color_from_source

	if shadow_length == 0 or shadow_direction == Vector2.ZERO:
		hide()
	else:
		if with_shape_update:
			var new_shadow_polygon: PoolVector2Array = _update_shadow_polygon()
		show()


func _update_shadow_polygon():
	# dupliciram original polygon in ga zamaknem
	# povežem sorodne pare točko med obema poligonoma v kvadrate
	# kvadrate združim z original obliko

	# casting poligon ... offsetan, če je owner dvignjen
	var shadow_casting_polygon: PoolVector2Array = []
	var shadow_offset_in_direction: Vector2 = shadow_direction * shadow_offset
	if shadow_offset == 0:
		shadow_casting_polygon = shadow_casting_node.polygon
	else:
		for point in shadow_casting_node.polygon:
			shadow_casting_polygon.append(point + shadow_offset_in_direction)

	# shadow poligon ... senčko
	var shadow_polygon: PoolVector2Array # zamaknjene original točke
	var shadow_length_in_direction: Vector2 = shadow_direction * shadow_length
	for point in shadow_casting_node.polygon:
		shadow_polygon.append(point + shadow_length_in_direction)

	# povežem točkovne pare casterja in senčke v kvadrate
	var square_polygons: Array = []
	for point_index in shadow_casting_polygon.size():
		var new_square_polygon: PoolVector2Array = []
		var next_point_index: int = point_index + 1
		if point_index == shadow_casting_node.polygon.size() - 1:
			next_point_index = 0
		new_square_polygon.append(shadow_casting_polygon[point_index])
		new_square_polygon.append(shadow_casting_polygon[next_point_index])
		new_square_polygon.append(shadow_polygon[next_point_index])
		new_square_polygon.append(shadow_polygon[point_index])
		square_polygons.append(new_square_polygon)

	# vsak kvadrat mergam s casterjem
	var merged_shadow: PoolVector2Array = shadow_casting_polygon
	for square in square_polygons:
		var merged_to_casting_polygon: Array = Geometry.merge_polygons_2d(merged_shadow, square)
		if not merged_to_casting_polygon.empty():
			merged_shadow = merged_to_casting_polygon[0]

	set_deferred("polygon", merged_shadow)

	return merged_shadow
