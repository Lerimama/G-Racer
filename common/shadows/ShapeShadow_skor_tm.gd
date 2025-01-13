extends Polygon2D


export (NodePath) var shadow_caster_path: String
export (NodePath) var shadow_owner_path: String # če je kaj drugega kot senčkin parent
export var shadow_z_index: int = 0 # samo, če rabiš spcifičnega

var is_updating_shadows: bool = false # prevent

var shadow_caster: Node # poligon, sprite, texture_rect, texture_btn
var shadow_caster_is_texture: bool = false

var shadow_rotation_deg: float = 45 setget _change_shadow_rotation
var shadow_offset: float = 50 setget _change_shadow_offset
var shadow_length: float = 150 setget _change_shadow_length

# caster transforms
var shadow_caster_global_rotation_deg: float # za detect
var shadow_caster_position: Vector2  # za detect pri animaciji
var shadow_caster_scale: Vector2 = Vector2(0, .9398484)  # za detect pri animaciji

# owner shadow params
var shadow_owner_elevation: float # za detect
var shadow_owner_height: float # za detect
var shadow_owner_transparency: float = .9398484# za detect

onready var shadow_owner: Node2D #= get_parent()

# neu
onready var attached_shadows_parent_name: String = "AttachedShadows"
onready var texture_shadows_parent_name: String = "TextureShadows"
export var merge_all_attached: bool = false
export var merge_all: bool = false

# NEW
export(Array, NodePath) var shadow_caster_paths: Array
var shadow_caster_shapes: Array = []
var shadows_color: = Color.black
var shadows_alpha: = 0.2
var shadow_owner_global_rotation_deg: float = 0


func _ready() -> void:

	add_to_group(Refs.group_shadows)
	# z index
	#	if shadow_z_index == 0:
	#		z_index = Pros.z_indexes[Refs.group_shadows]
	#	else:
	#		z_index = shadow_z_index

	# nodes setup
	if shadow_caster_paths:
		if shadow_owner_path:
			shadow_owner = get_node(shadow_owner_path)
		else:
			shadow_owner = get_parent()
		shadow_owner.connect("draw", self, "_on_shadow_owner_draw") # če se shadow caster premakne, resiza, ... karkoli

		for path in shadow_caster_paths:
			shadow_caster_shapes.append(get_node(path))
		if Refs.game_manager:
			shadow_rotation_deg = Refs.game_manager.game_shadows_rotation_deg
			color = Refs.game_manager.game_shadows_color
			modulate.a = Refs.game_manager.game_shadows_alpha
	else:
		hide()


func _process(delta: float) -> void: # preverjanje sprememb nekaterih lastnosti lastnika


	if shadow_owner:
		_detect_owner_change()

#	var changed_casters: Array
#	for caster_shape in shadow_caster_shapes:
#		if _detect_caster_local_transforms(caster_shape):
#			changed_casters.append(caster_shape)
#	for changed_caster in changed_casters:
#		_update_caster_shadow(changed_caster)

func _detect_caster_local_transforms(caster_shape: Node):
#	return
	# globalna rotacija lastnika prek lastno globalno rotacijo
	var prev_caster_rotation_deg = shadow_caster_global_rotation_deg
	if shadow_caster is Control:
		shadow_caster_global_rotation_deg = rad2deg(shadow_caster.rect_rotation) + shadow_owner.global_rotation_degrees
	else:
		shadow_caster_global_rotation_deg = shadow_caster.global_rotation_degrees
	var rotation_change: float = shadow_caster_global_rotation_deg - prev_caster_rotation_deg
	if not rotation_change == 0:
		var new_rotation_deg: float = shadow_rotation_deg - rotation_change
		self.shadow_rotation_deg = new_rotation_deg

	if shadow_caster is Control:
		position = shadow_caster.rect_position
		scale = shadow_caster.rect_scale
		# striže z globalno rotacijo ... self.shadow_rotation_deg = shadow_caster.rect_rotation
	else:
		position = shadow_caster.position
		if "centered" in shadow_caster:
			if shadow_caster.centered:
				position -= shadow_caster.texture.get_size()/2
		scale = shadow_caster.scale
		# striže z globalno rotacijo ... self.shadow_rotation_deg = shadow_caster.rotation


func _update_caster_shadow(caster_shape: Node):

	caster_shape.connect("draw", self, "_on_shadow_caster_draw")

	match caster_shape.get_class():
		"Polygon2D":
			shadow_caster_is_texture = false
		"Sprite":
			if caster_shape.texture:
				shadow_caster_is_texture = true
		"AnimatedSprite":
			if caster_shape.texture:
				shadow_caster_is_texture = true
		"TextureRect":
			if caster_shape.texture:
				shadow_caster_is_texture = true
				# če ni teksture ni redi
		"CollisionPolygon2D":
			pass


	if shadow_caster_is_texture:
		_create_texture_shadows(caster_shape)
		if caster_shape is Control:
			position = caster_shape.rect_position
			rotation = caster_shape.rect_rotation
			scale = caster_shape.rect_scale
		else:
			position = caster_shape.position
			if "centered" in caster_shape:
				if caster_shape.centered:
					position -= caster_shape.texture.get_size()/2
			rotation = caster_shape.rotation
			scale = caster_shape.scale
	else:
		_create_caster_shadow(caster_shape)


func _detect_owner_change():
	# samo globalna rotacija, ker se pri skejlanju in premikanju ownerja  senca ne spremeni
		# parametri casterev se ne spreminjajo, samo senčka se rebilda
		var prev_rotation_deg = shadow_owner_global_rotation_deg
		shadow_owner_global_rotation_deg = shadow_owner.global_rotation_degrees
		var rotation_change: float = shadow_owner_global_rotation_deg - prev_rotation_deg
		if abs(rotation_change) > 0:
			var new_rotation_deg: float = shadow_rotation_deg - rotation_change
			self.shadow_rotation_deg = new_rotation_deg


		# shadow params
		# debug
		var game_shadows_length_factor: float = 1
		if Refs.game_manager:
			game_shadows_length_factor = Refs.game_manager.game_shadows_length_factor

		# elevation
		var prev_elevation = shadow_owner_elevation
		shadow_owner_elevation = shadow_owner.elevation
		var elevation_change: float = shadow_owner_elevation - prev_elevation
		if not elevation_change == 0:
			self.shadow_offset = shadow_owner_elevation * game_shadows_length_factor

		# height
		var prev_height = shadow_owner_height
		shadow_owner_height = shadow_owner.height
		var height_change: float = shadow_owner_height - prev_height
		if not height_change == 0:
			self.shadow_length = shadow_owner_height * game_shadows_length_factor



func update_all_shadows():

	var shape_is_ready: bool = false

	for old_child in get_children():
		if not old_child.name == texture_shadows_parent_name:
			old_child.queue_free()


	if shadow_length == 0:
		shape_is_ready = false

	for shape in shadow_caster_shapes:
		if not is_updating_shadows:
			is_updating_shadows = true



			if not shadow_caster_paths.empty():
				shape_is_ready = true
				# spawn parenta, če še ne obstaja
				var attached_shadows_parent: Node2D
				if get_node(attached_shadows_parent_name):
					attached_shadows_parent = get_node(attached_shadows_parent_name)
					# zbrišem stare
					if not attached_shadows_parent.get_children().empty():
						for shadow_shape in attached_shadows_parent.get_children():
							shadow_shape.queue_free()
				else:
					attached_shadows_parent = Node2D.new()
					attached_shadows_parent.name = attached_shadows_parent_name
					add_child(attached_shadows_parent)

				for shape_path in shadow_caster_paths:


					var caster_shape_from_path: Node = get_node(shape_path)

					_update_caster_shadow(caster_shape_from_path)


#					var new_shadow_shape: Polygon2D = Polygon2D.new()
#					new_shadow_shape.polygon = caster_shape_from_path.polygon
#					new_shadow_shape.color = color
#					new_shadow_shape.modulate.a = modulate.a
#					add_child(new_shadow_shape)
#
#
#					_create_caster_shadow(new_shadow_shape)


#			if shadow_caster:
#				shape_is_ready = true
#				if shadow_caster_is_texture:
#					_create_texture_shadows()
#					if shadow_caster is Control:
#						position = shadow_caster.rect_position
#						rotation = shadow_caster.rect_rotation
#						scale = shadow_caster.rect_scale
#					else:
#						position = shadow_caster.position
#						if "centered" in shadow_caster:
#							if shadow_caster.centered:
#								position -= shadow_caster.texture.get_size()/2
#						rotation = shadow_caster.rotation
#						scale = shadow_caster.scale
#				else:
#					_update_caster_shadow(shadow_caster.polygon)
#					position = shadow_caster.position
#					rotation = shadow_caster.rotation
#					scale = shadow_caster.scale

			is_updating_shadows = false
#
#		if shape_is_ready:
#			show()
#		else:
#			hide()




# BUILD ------------------------------------------------------------------------------------------------------------


func _create_texture_shadows(shape_with_texture):

	var new_shadow_polygons: Array = _get_polygons_from_texture(shape_with_texture)
	if not new_shadow_polygons.empty():
		var texture_shadows_parent: Node2D
		if get_node(texture_shadows_parent_name):
			texture_shadows_parent = get_node(texture_shadows_parent_name)
		else:
			texture_shadows_parent = Node2D.new()
			texture_shadows_parent.name = texture_shadows_parent_name
			add_child(texture_shadows_parent)
		_create_child_shadows(new_shadow_polygons, texture_shadows_parent)
	else: # empty
		print("Error: Texture shadow resulted in ZERO polygons ... hide()")
		hide()



func _create_child_shadows(shadow_polygons: Array, shadows_parent: Node2D = self):

	# zbrišem stare
	if not shadows_parent.get_children().empty():
		for shadow_shape in shadows_parent.get_children():
			shadow_shape.queue_free()

	for shadow_polygon in shadow_polygons:

		var new_shadow_shape: Polygon2D = Polygon2D.new()
		new_shadow_shape.polygon = shadow_polygon
		new_shadow_shape.color = color
		new_shadow_shape.modulate.a = modulate.a
		shadows_parent.add_child(new_shadow_shape)


		_create_caster_shadow(new_shadow_shape)


# NEW


func _create_caster_shadow(shadow_casting_shape: Polygon2D):
	# dupliciram original polygon in ga zamaknem
	# povežem sorodne pare točko med obema poligonoma v kvadrate
	# kvadrate združim z original obliko

	var shadow_casting_polygon: PoolVector2Array = shadow_casting_shape.polygon

	# casting poligon ... offsetan, če je owner dvignjen
	var new_shadow_casting_polygon: PoolVector2Array = []
	var shadow_offset_in_direction: Vector2 = Vector2.RIGHT.rotated(deg2rad(shadow_rotation_deg)) * shadow_offset
	if shadow_offset == 0:
		new_shadow_casting_polygon = shadow_casting_polygon
	else:
		for point in shadow_casting_polygon:
			new_shadow_casting_polygon.append(point + shadow_offset_in_direction)
			# širjenje sence z dolžino ... new_shadow_casting_polygon.append(point + point.rotated(deg2rad(shadow_rotation_deg)) * shadow_length)

	# shadow poligon ... senčko
	var shadow_polygon: PoolVector2Array # zamaknjene original točke
	var shadow_length_in_direction: Vector2 = Vector2.RIGHT.rotated(deg2rad(shadow_rotation_deg)) * shadow_length
	for point in shadow_casting_polygon:
		shadow_polygon.append(point + shadow_length_in_direction)
		# širjenje sence z dolžino ... shadow_polygon.append(point + point.rotated(deg2rad(shadow_rotation_deg)) * shadow_length)

	# povežem točkovne pare casterja in senčke v kvadrate
	var square_polygons: Array = []
	for point_index in new_shadow_casting_polygon.size():
		var new_square_polygon: PoolVector2Array = []
		var next_point_index: int = point_index + 1
		if point_index == shadow_casting_polygon.size() - 1:
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
		# tukej lahko pride več poligonov pa ne upoštevam
		if not merged_to_casting_polygon.empty():
			merged_shadow = merged_to_casting_polygon[0]

	var new_shadow: Polygon2D = Polygon2D.new()
	new_shadow.name = shadow_casting_shape.name + "_Shadow"
	new_shadow.polygon = merged_shadow
	new_shadow.position = shadow_casting_shape.position
	new_shadow.scale = shadow_casting_shape.scale
	new_shadow.color = shadows_color
	add_child(new_shadow)
#	shadow_casting_shape.set_deferred("polygon", merged_shadow)

	modulate.a = shadows_alpha

# HELPERS ------------------------------------------------------------------------------------------------------------


func _get_polygons_from_texture(shape_with_texture):

	var transparency_image: Image = shape_with_texture.texture.get_data()
#	var transparency_image: Image = shadow_caster.texture.get_data()
	var transparency_bitmap = BitMap.new()
	transparency_bitmap.create_from_image_alpha(transparency_image)
	var bitmap_rect: Rect2 = Rect2(Vector2.ZERO, transparency_bitmap.get_size())
	var bitmap_polygons: Array = transparency_bitmap.opaque_to_polygons(bitmap_rect) # polygons array (rect: Rect2, epsilon: float = 2.0)

	return bitmap_polygons


# SETGET -----------------------------------------------------------------------------------------------


func _change_shadow_rotation(new_rotation_deg: float): # game setting
	print("change rotation setget")

	if not shadow_rotation_deg == new_rotation_deg: # OPT preverjanje trenutno nekaj zjebe ... popravi
		shadow_rotation_deg = new_rotation_deg
		update_all_shadows()


func _change_shadow_offset(new_offset: float): # game setting
	printt("change offset setget")

	if not shadow_offset == new_offset:
		shadow_offset = new_offset
		update_all_shadows()

func _change_shadow_length(new_length: float): # game setting
	printt("change length setget")

	if not shadow_length == new_length:
		shadow_length = new_length
		update_all_shadows()


# SIGNALI -----------------------------------------------------------------------------------------------


func _on_shadow_caster_draw():

	# problem signala je da ne zaznava animiranega z animation player
	#	if shadow_caster_is_texture:
	#		if "centered" in shadow_caster:
	#				if shadow_caster.centered:
	#					print("pos", shadow_caster.position)
	print("caster draw")

func _on_shadow_owner_draw():
	print("owner draw")
