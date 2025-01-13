extends Polygon2D

signal all_shadows_updated
signal all_shadows_merged


export (NodePath) var shadow_owner_path: String # če je kaj drugega kot senčkin parent
export(Array, NodePath) var shadow_caster_paths: Array
export var merge_all: bool = true
export var shadow_z_index: int = 0 # samo, če rabiš spcifičnega

var is_updating_shadows: bool = false # prevent
var texture_shadows_parent_suffix: String = "_Shadows"
var created_shadow_name_suffix: String = "_Shadow"

var shadows_color: = Color.black
var shadows_alpha: = 0.2
var shadow_rotation_deg: float = 45 setget _change_shadow_rotation
var shadow_offset: float = 50 setget _change_shadow_offset
var shadow_length: float = 150 setget _change_shadow_length

# owner shadow params
var shadow_owner_global_rotation_deg: float = 0
var shadow_owner_elevation: float # za detect
var shadow_owner_height: float # za detect
var shadow_owner_transparency: float = .9398484# za detect

onready var shadow_owner: Node2D #= get_parent()

# NEW
var shadow_caster_shapes: Array = []



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
		if Refs.game_manager:
			#			shadow_rotation_deg = Refs.game_manager.game_shadows_rotation_deg
			self.shadow_rotation_deg = Refs.game_manager.game_shadows_rotation_deg
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


	var shadow_caster_global_rotation_deg: float # za detect

	# globalna rotacija lastnika prek lastno globalno rotacijo
	var prev_caster_rotation_deg = shadow_caster_global_rotation_deg
	if caster_shape is Control:
		shadow_caster_global_rotation_deg = rad2deg(caster_shape.rect_rotation) + caster_shape.global_rotation_degrees
	else:
		shadow_caster_global_rotation_deg = caster_shape.global_rotation_degrees
	var rotation_change: float = shadow_caster_global_rotation_deg - prev_caster_rotation_deg
	if not rotation_change == 0:
		var new_rotation_deg: float = shadow_rotation_deg - rotation_change
		self.shadow_rotation_deg = new_rotation_deg

	if caster_shape is Control:
		position = caster_shape.rect_position
		scale = caster_shape.rect_scale
		# striže z globalno rotacijo ... self.shadow_rotation_deg = caster_shape.rect_rotation
	else:
		position = caster_shape.position
		if "centered" in caster_shape:
			if caster_shape.centered:
				position -= caster_shape.texture.get_size()/2
		scale = caster_shape.scale
		# striže z globalno rotacijo ... self.shadow_rotation_deg = caster_shape.rotation


func _detect_owner_change(): # vedno spreminja vse sence

	# owner transforms ... samo rotacija, ker se pri scale in position, se senca ne spremeni
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


# UPDATE ---------------------------------------------------------------------------------------------


func update_all_shadows():

	if shadow_length > 0:
		if not is_updating_shadows:# and not shape == null: # zaradi oblike vnosa (export array
			for child in get_children():
				if child is Polygon2D: # ne brišam
					child.queue_free()

			is_updating_shadows = true
			for shape_path in shadow_caster_paths:
				var caster_shape_from_path: Node = get_node(shape_path)
				_update_caster_shadow(caster_shape_from_path)
			emit_signal("all_shadows_updated")

#			merge_all = false # debug
			if not merge_all:
				is_updating_shadows = false
			elif merge_all and not get_children().empty():

				# naberem vse senčke
				var shadows_to_merge: Array = []
				for child in get_children():
					if child is Polygon2D:
						shadows_to_merge.append(child)
					else:
						for child_2 in child.get_children():
							shadows_to_merge.append(child_2)
				# vsak kvadrat mergam s casterjem
				var start_shadow: Polygon2D = shadows_to_merge.pop_back()
				var shapes_to_kvefri: Array = [start_shadow]
				var merged_shadow: PoolVector2Array = start_shadow.polygon
				for shadow_to_merge in shadows_to_merge:
					var merged_to_casting_polygon: Array = Geometry.merge_polygons_2d(merged_shadow, shadow_to_merge.polygon)
					# tukej lahko pride več poligonov pa ne upoštevam
					if not merged_to_casting_polygon.empty():
						merged_shadow = merged_to_casting_polygon[0]
						shapes_to_kvefri.append(shadow_to_merge)

				for kvefri in shapes_to_kvefri:
					kvefri.queue_free()

				for child in get_children():
					child.queue_free()
	#			if has_node("Biggie"):
	#				get_node("Biggie").queue_free()
				var new_shadow: Polygon2D = Polygon2D.new()
				new_shadow.name = "Biggie"
				new_shadow.polygon = merged_shadow
				new_shadow.color = shadows_color
				add_child(new_shadow)

				is_updating_shadows = false

# BUILD ------------------------------------------------------------------------------------------------------------


func _update_caster_shadow(caster_shape: Node):

	caster_shape.connect("draw", self, "_on_shadow_caster_draw")

	var shadow_caster_is_texture: bool = false

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
		_build_shadow_from_texture(caster_shape)
	else:
		_build_shadow_from_shape(caster_shape)


func _build_shadow_from_texture(shape_with_texture):

	# textura v poligone
	var transparency_image: Image = shape_with_texture.texture.get_data()
	var transparency_bitmap = BitMap.new()
	transparency_bitmap.create_from_image_alpha(transparency_image)
	var bitmap_rect: Rect2 = Rect2(Vector2.ZERO, transparency_bitmap.get_size())
	var new_shadow_polygons: Array = transparency_bitmap.opaque_to_polygons(bitmap_rect) # polygons array (rect: Rect2, epsilon: float = 2.0)

	if new_shadow_polygons.empty():
		print("Error: Texture shadow resulted in ZERO polygons ... hide()")
	else:
		# spaw parenta
		var texture_shadows_parent: Node2D
		if has_node(shape_with_texture.name + texture_shadows_parent_suffix):
			texture_shadows_parent = get_node(shape_with_texture.name + texture_shadows_parent_suffix)
			for shadow_shape in texture_shadows_parent.get_children():
				shadow_shape.queue_free()
		else:
			texture_shadows_parent = Node2D.new()
			texture_shadows_parent.name = shape_with_texture.name + texture_shadows_parent_suffix
			add_child(texture_shadows_parent)

		for shadow_polygon in new_shadow_polygons:
			var new_shadow_shape: Polygon2D = Polygon2D.new()
			new_shadow_shape.polygon = shadow_polygon
			new_shadow_shape.color = color
			new_shadow_shape.modulate.a = modulate.a
			_build_shadow_from_shape(new_shadow_shape, texture_shadows_parent)


func _build_shadow_from_shape(shadow_casting_shape: Polygon2D, shadow_parent: Node = self):
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
		if not merged_to_casting_polygon.empty(): # OPT tukej lahko pride več poligonov pa ne upoštevam
			merged_shadow = merged_to_casting_polygon[0]

	var new_shadow: Polygon2D = Polygon2D.new()
	new_shadow.name = shadow_casting_shape.name + created_shadow_name_suffix
	new_shadow.polygon = merged_shadow
	new_shadow.position = shadow_casting_shape.position
	new_shadow.scale = shadow_casting_shape.scale
	new_shadow.color = shadows_color
	shadow_parent.add_child(new_shadow)

	modulate.a = shadows_alpha


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

	print("caster draw")

func _on_shadow_owner_draw():

	print("owner draw")
