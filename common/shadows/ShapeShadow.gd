extends Polygon2D


export (NodePath) var shadow_caster_path: String
export (NodePath) var shadow_owner_path: String # če je kaj drugega kot senčkin parent
export var shadow_z_index: int = 0 # samo, če rabiš spcifičnega
export(Array, NodePath) var attached_shapes: Array

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
var imitate_3d: bool = false setget _imitate_3d
var viewport_camera: Camera2D
var viewport_center_position: Vector2 setget _change_viewport_center_position
onready var attached_shadows_parent_name: String = "AttachedShadows"
onready var texture_shadows_parent_name: String = "TextureShadows"
export var merge_all_attached: bool = false
export var merge_all: bool = false


func _ready() -> void:

	add_to_group(Refs.group_shadows)

	# z index
	#	if shadow_z_index == 0:
	#		z_index = Pros.z_indexes[Refs.group_shadows]
	#	else:
	#		z_index = shadow_z_index

	# nodes setup
	if shadow_caster_path:
		_set_shadow_caster(shadow_caster_path)
		if shadow_owner_path:
			shadow_owner = get_node(shadow_owner_path)
		else:
			shadow_owner = shadow_caster.get_parent()
			if Refs.game_manager:
				shadow_rotation_deg = Refs.game_manager.game_shadows_rotation_deg
				color = Refs.game_manager.game_shadows_color
				modulate.a = Refs.game_manager.game_shadows_alpha
	else:
		hide()


func _process(delta: float) -> void: # preverjanje sprememb nekaterih lastnosti lastnika

	if shadow_caster:
		_detect_caster_transforms(shadow_caster)

	if shadow_owner:
		_detect_shadow_params()

	if not attached_shapes.empty():
		pass


func update_shadows():

#	if _is_build_ready():
	var is_ready: bool = false

	if shadow_length == 0:
			is_ready = false
			return

	elif not is_updating_shadows:
		is_updating_shadows = true


		if not attached_shapes.empty():
			is_ready = true
			# spawn parenta, če še ne obstaja
			var attached_shadows_parent: Node2D
			if get_node(attached_shadows_parent_name):
				attached_shadows_parent = get_node(attached_shadows_parent_name)
			else:
				attached_shadows_parent = Node2D.new()
				attached_shadows_parent.name = attached_shadows_parent_name
				add_child(attached_shadows_parent)

			var attached_polygons: Array = []
			for shape_path in attached_shapes:
				var attached_shape = get_node(shape_path)
				attached_polygons.append(attached_shape.polygon)
			_create_child_shadows(attached_polygons, attached_shadows_parent)

		if shadow_caster:
			is_ready = true
			if shadow_caster_is_texture:
				_create_texture_shadows()
				if shadow_caster is Control:
					position = shadow_caster.rect_position
					rotation = shadow_caster.rect_rotation
					scale = shadow_caster.rect_scale
				else:
					position = shadow_caster.position
					if "centered" in shadow_caster:
						if shadow_caster.centered:
							position -= shadow_caster.texture.get_size()/2
					rotation = shadow_caster.rotation
					scale = shadow_caster.scale
			else:
				_update_main_shadow_polygon(shadow_caster.polygon)
				position = shadow_caster.position
				rotation = shadow_caster.rotation
				scale = shadow_caster.scale

		is_updating_shadows = false
	if is_ready:
		show()
	else:
		hide()


# BUILD ------------------------------------------------------------------------------------------------------------


func _create_texture_shadows():

	var new_shadow_polygons: Array = _get_polygons_from_texture()
	if new_shadow_polygons.size() == 1:
		_update_main_shadow_polygon(new_shadow_polygons[0])
	elif new_shadow_polygons.size() > 1:
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


func _update_main_shadow_polygon(shadow_casting_polygon: PoolVector2Array, shadow_casting_shape: Polygon2D = self):
	# dupliciram original polygon in ga zamaknem
	# povežem sorodne pare točko med obema poligonoma v kvadrate
	# kvadrate združim z original obliko

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
		if not merged_to_casting_polygon.empty():
			merged_shadow = merged_to_casting_polygon[0]

	shadow_casting_shape.set_deferred("polygon", merged_shadow)


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

		_update_main_shadow_polygon(shadow_polygon, new_shadow_shape)


# HELPERS ------------------------------------------------------------------------------------------------------------


func _set_shadow_caster(caster_node_path: String):

	shadow_caster = get_node(shadow_caster_path)
	shadow_caster.connect("draw", self, "_on_shadow_caster_draw") # če se shadow caster premakne, resiza, ... karkoli

	match shadow_caster.get_class():
		"Polygon2D":
			shadow_caster_is_texture = false
		"Sprite":
			if shadow_caster.texture:
				shadow_caster_is_texture = true
		"AnimatedSprite":
			if shadow_caster.texture:
				shadow_caster_is_texture = true
			pass
		"TextureRect":
			if shadow_caster.texture:
				shadow_caster_is_texture = true
			pass
		"CollisionPolygon2D":
			pass

	update_shadows()


func _get_polygons_from_texture():

	var transparency_image: Image = shadow_caster.texture.get_data()
	var transparency_bitmap = BitMap.new()
	transparency_bitmap.create_from_image_alpha(transparency_image)
	var bitmap_rect: Rect2 = Rect2(Vector2.ZERO, transparency_bitmap.get_size())
	var bitmap_polygons: Array = transparency_bitmap.opaque_to_polygons(bitmap_rect) # polygons array (rect: Rect2, epsilon: float = 2.0)

	return bitmap_polygons


func _detect_caster_transforms(caster_shape: Node):

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


func _detect_shadow_params():

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
		printt("shadow_owner.height", shadow_owner_height, shadow_owner.height, shadow_length)

	# 3D
	if imitate_3d and viewport_camera:
		self.viewport_center_position = viewport_camera.get_camera_screen_center()


#func _is_build_ready():
#
#	var is_build_ready: bool = false
#	if shadow_caster or not attached_shapes.empty():
#		is_build_ready = true
#	if shadow_length == 0:
#		is_build_ready = true
#
#	return is_build_ready


# 3D IMITATE ------------------------------------------------------------------------------------------------------------


func _imitate_3d(new_imitate): # setget
	# tole še ni okej

	imitate_3d = new_imitate
	if imitate_3d:
		viewport_camera = Refs.current_camera
		var new_screen_center_position: Vector2 = viewport_camera.get_camera_screen_center()
		self.viewport_center_position = new_screen_center_position
#		var new_rot: float = Vector2.RIGHT.angle_to(screen_center_position - global_position)
#		self.shadow_rotation_deg = rad2deg(new_rot)
	else:
		self.shadow_rotation_deg = Refs.game_shadows_rotation_deg


func _change_viewport_center_position(new_center_position: Vector2):

	if not viewport_center_position.is_equal_approx(new_center_position):

		# smer sence
		viewport_center_position = new_center_position
		Mets.spawn_indikator(viewport_center_position, Color.red, 0, Refs.node_creation_parent)
		var shape_distance_to_center: float = (viewport_center_position - global_position).length()
		var new_shadows_rotation: float = Vector2.RIGHT.angle_to(viewport_center_position - global_position)
		self.shadow_rotation_deg = rad2deg(new_shadows_rotation)

		# dolžina sence
		#		printt("camera", viewport_center_position)
		#		yield(get_tree(),"idle_frame")
		#		# dožina sence ... začasna verzija
		#		var whole_part_distance: float = get_viewport().get_size().x/2
		#		var shadow_length_part: float = shape_distance_to_center / whole_part_distance
		#		self.shadow_length = shadow_length * shadow_length_part


# SETGET -----------------------------------------------------------------------------------------------


func _change_shadow_rotation(new_rotation_deg: float): # game setting

	if not shadow_rotation_deg == new_rotation_deg: # OPT preverjanje trenutno nekaj zjebe ... popravi
		shadow_rotation_deg = new_rotation_deg
		update_shadows()


func _change_shadow_offset(new_offset: float): # game setting

	if not shadow_offset == new_offset:
		shadow_offset = new_offset
		update_shadows()


func _change_shadow_length(new_length: float): # game setting

	if not shadow_length == new_length:
		shadow_length = new_length
#		printt("se.height", shadow_length)

		update_shadows()


# SIGNALI -----------------------------------------------------------------------------------------------


func _on_shadow_caster_draw():

	# problem signala je da ne zaznava animiranega z animation player
	#	if shadow_caster_is_texture:
	#		if "centered" in shadow_caster:
	#				if shadow_caster.centered:
	#					print("pos", shadow_caster.position)
	print("draw")
#	update_shadows()
