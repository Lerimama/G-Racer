extends Polygon2D


export (NodePath) var shadow_owner_shape_path: String
export var shadow_z_index: int = 0 # samo, če rabiš spcifičnega

var shadow_owner_shape: Node # poligon, sprite, texture_rect, texture_btn
var shadow_owner_shape_is_texture: bool = false

var shadow_rotation_deg: float = 0 setget _change_shadow_rotation
var shadow_offset: float = 0 setget _change_shadow_offset
var shadow_length: float = 0 setget _change_shadow_length

# detect owner
var shadow_owner_rotation_deg: float # za detect
var shadow_owner_elevation: float # za detect
var shadow_owner_height: float # za detect

onready var shadow_owner: Node2D = get_parent()


func _ready() -> void:

	add_to_group(Refs.group_shadows)

	# z index
	if shadow_z_index == 0:
		z_index = Pros.z_indexes[Refs.group_shadows]
	else:
		z_index = shadow_z_index

	# aktivate shadows
	if shadow_owner_shape_path:
		shadow_owner_shape = get_node(shadow_owner_shape_path)
		# če se shadow caster premakne ali resiza
		shadow_owner_shape.connect("item_rect_changed", self, "_on_item_rect_changed") # ne dela ... bi lahko nadomestil procesno detectanje
		if "texture" in shadow_owner_shape and not shadow_owner_shape is Polygon2D:
			shadow_owner_shape_is_texture = true
		shadow_rotation_deg = Refs.game_manager.game_shadows_rotation_deg
		update_shadow()
		color = Refs.game_manager.game_shadows_color
		modulate.a = Refs.game_manager.game_shadows_alpha
		show()
	else:
		hide()

func _process(delta: float) -> void: # preverjanje sprememb nekaterih lastnosti lastnika

	_detect_on_owner()


func _detect_on_owner():

	# rotacija lastnika
	var prev_rotation_deg = shadow_owner_rotation_deg
	shadow_owner_rotation_deg = shadow_owner.rotation_degrees
	var rotation_change: float = shadow_owner_rotation_deg - prev_rotation_deg
	if not rotation_change == 0:
		var new_rotation_deg: float = shadow_rotation_deg - rotation_change
		self.shadow_rotation_deg = new_rotation_deg

	# elevation
	var prev_elevation = shadow_owner_elevation
	shadow_owner_elevation = shadow_owner.elevation
	var elevation_change: float = shadow_owner_rotation_deg - prev_elevation
	if not elevation_change == 0:
		self.shadow_offset = shadow_owner_elevation * Refs.game_manager.game_shadows_length_factor

	# height
	var prev_height = shadow_owner_height
	shadow_owner_height = shadow_owner.height
	var height_change: float = shadow_owner_height - prev_height
	if not height_change == 0:
		self.shadow_length = shadow_owner_height * Refs.game_manager.game_shadows_length_factor


func update_shadow():

	if not shadow_owner_shape or shadow_length == 0:
		hide()
	else:
		if shadow_owner_shape_is_texture:
			_create_texture_shadow()
		else:
			_create_shadow_polygon()
		if shadow_owner_shape is Control:
			position = shadow_owner_shape.rect_position
			scale = shadow_owner_shape.rect_scale
		else:
			position = shadow_owner_shape.position
			scale = shadow_owner_shape.scale
		show()


func _create_shadow_polygon(base_shadow_casting_polygon: PoolVector2Array = shadow_owner_shape.polygon):
	# dupliciram original polygon in ga zamaknem
	# povežem sorodne pare točko med obema poligonoma v kvadrate
	# kvadrate združim z original obliko

	# casting poligon ... offsetan, če je owner dvignjen
	var new_shadow_casting_polygon: PoolVector2Array = []
	var shadow_offset_in_direction: Vector2 = Vector2.RIGHT.rotated(deg2rad(shadow_rotation_deg)) * shadow_offset
	if shadow_offset == 0:
		new_shadow_casting_polygon = base_shadow_casting_polygon
	else:
		for point in base_shadow_casting_polygon:
			new_shadow_casting_polygon.append(point + shadow_offset_in_direction)
			# širjenje sence z dolžino ... new_shadow_casting_polygon.append(point + point.rotated(deg2rad(shadow_rotation_deg)) * shadow_length)

	# shadow poligon ... senčko
	var shadow_polygon: PoolVector2Array # zamaknjene original točke
	var shadow_length_in_direction: Vector2 = Vector2.RIGHT.rotated(deg2rad(shadow_rotation_deg)) * shadow_length
	for point in base_shadow_casting_polygon:
		shadow_polygon.append(point + shadow_length_in_direction)
		# širjenje sence z dolžino ... shadow_polygon.append(point + point.rotated(deg2rad(shadow_rotation_deg)) * shadow_length)

	# povežem točkovne pare casterja in senčke v kvadrate
	var square_polygons: Array = []
	for point_index in new_shadow_casting_polygon.size():
		var new_square_polygon: PoolVector2Array = []
		var next_point_index: int = point_index + 1
		if point_index == base_shadow_casting_polygon.size() - 1:
			next_point_index = 0
		new_square_polygon.append(new_shadow_casting_polygon[point_index])
		new_square_polygon.append(new_shadow_casting_polygon[next_point_index])
		new_square_polygon.append(shadow_polygon[next_point_index])
		new_square_polygon.append(shadow_polygon[point_index])
		square_polygons.append(new_square_polygon)

	# vsak kvadrat mergam s casterjem
	var merged_shadow: PoolVector2Array = new_shadow_casting_polygon
	for square in square_polygons:
		var merged_to_casting_polygon: Array = Geometry.merge_polygons_2d(merged_shadow, square)
		if not merged_to_casting_polygon.empty():
			merged_shadow = merged_to_casting_polygon[0]

	set_deferred("polygon", merged_shadow)


func _create_texture_shadow():

	var new_shadow_polygons: Array = _get_polygons_from_texture()
	# dela samo z enim poligonom
	if new_shadow_polygons.size() == 1:
		_create_shadow_polygon(new_shadow_polygons[0])
	elif new_shadow_polygons.size() > 1:
		print("Texture shadow resulted in more than one polygon.")
		hide()
	else: # empty
		print("Texture shadow resulted in ZERO polygons.")
		hide()


func _get_polygons_from_texture():

	var transparency_image: Image = shadow_owner_shape.texture.get_data()
	var transparency_bitmap = BitMap.new()
	transparency_bitmap.create_from_image_alpha(transparency_image)
	var bitmap_rect: Rect2 = Rect2(Vector2.ZERO, transparency_bitmap.get_size())
	var bitmap_polygons: Array = transparency_bitmap.opaque_to_polygons(bitmap_rect) # polygons array (rect: Rect2, epsilon: float = 2.0)

	return bitmap_polygons


# SETGET -----------------------------------------------------------------------------------------------


func _change_shadow_rotation(new_rotation_deg: float): # game setting

	shadow_rotation_deg = new_rotation_deg
	update_shadow()


func _change_shadow_offset(new_offset: float): # game setting

	shadow_offset = new_offset
	update_shadow()


func _change_shadow_length(new_length: float): # game setting

	shadow_length = new_length
	update_shadow()


# SIGNALI -----------------------------------------------------------------------------------------------


func _on_item_rect_changed():
	print ("item changed .............")
