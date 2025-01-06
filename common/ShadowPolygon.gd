extends Polygon2D


export (NodePath) var shadow_casting_polygon_path: String

onready var shadow_owner: Node2D = get_parent()
onready var shadow_casting_node: Node2D = get_node(shadow_casting_polygon_path)

# od ownerja
onready var shadow_color: Color = shadow_owner.shadow_color
onready var shadow_alpha: float = shadow_owner.shadow_alpha * shadow_owner.transparency
onready var owner_elevation: int = shadow_owner.elevation setget _update_shadow_elevation
# od igre
onready var shadow_length: float = Refs.game_manager.shadows_length + shadow_owner.height + owner_elevation setget _update_shadow_length  # odvisno od igre ...  "višina" vira svetlobe, 0 je default
onready var shadow_direction: Vector2 = Refs.game_manager.shadows_direction.normalized() setget _update_shadow_direction


func _ready() -> void:

	add_to_group(Refs.group_shadows)
	z_index = Pros.z_indexes[Refs.group_shadows]

	# popravim rotacijo sence glede na globalno rotacijo poligona
	shadow_direction = shadow_direction.rotated(- global_rotation)

	if shadow_casting_node:
		_update_shadow_polygon()
	else:
		printerr ("No shadow casting node for: ", self)
		hide()


func _update_shadow_polygon():

	if shadow_owner.height == 0:
		hide()
	else:
		var shadow_casting_polygon: PoolVector2Array = []
		var shadow_elevate_in_direction: Vector2 = shadow_direction * owner_elevation
		if owner_elevation == 0:
			shadow_casting_polygon = shadow_casting_node.polygon
		else:
			for point in shadow_casting_node.polygon:
				shadow_casting_polygon.append(point + shadow_elevate_in_direction)

		# imam caster shape in naredim offsetano senčko
#		var shadow_casting_polygon: PoolVector2Array = shadow_casting_node.polygon
		var shadow_polygon: PoolVector2Array # zamaknjene original točke
		var shadow_offset_in_direction: Vector2 = shadow_direction * shadow_length
		for point in shadow_casting_node.polygon:
			shadow_polygon.append(point + shadow_offset_in_direction)

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
			#		Mets.spawn_polygon_2d(new_filler_polygon, shadow_owner, Color(Color.yellow, 0.5))
			square_polygons.append(new_square_polygon)

		# vsak kvadrat mergam s casterjem
		var merged_shadow: PoolVector2Array = shadow_casting_polygon
		for square in square_polygons:
			var merged_to_casting_polygon: Array = Geometry.merge_polygons_2d(merged_shadow, square)
			if not merged_to_casting_polygon.empty():
				merged_shadow = merged_to_casting_polygon[0]
				#	Mets.spawn_polygon_2d(merged_shadow, shadow_owner, Color(Color.red, 0.5))
				#	for point in merged_shadow:
				#		Mets.spawn_indikator(position + point, Color.blue, 10, 0,shadow_owner)

		set_deferred("polygon", merged_shadow)
		show()


func _update_shadow_length(new_length: float):

	shadow_length = new_length
	_update_shadow_polygon()


func _update_shadow_direction(new_direction: Vector2):

	shadow_direction = new_direction.normalized()
	_update_shadow_polygon()

func _update_shadow_elevation(new_elevation: int):
	pass
