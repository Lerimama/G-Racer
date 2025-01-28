extends Node2D


signal all_shadows_updated # ne uporabljam
signal all_shadows_merged # ne uporabljam

export var enabled: bool = true setget _change_enabled
export (NodePath) var shadow_owner_path: String # če je kaj drugega kot senčkin parent
export(Array, NodePath) var shadow_caster_paths: Array
export var merge_all: bool = false
export var shadows_z_absolute: int = 0 # samo, če rabiš spcifičnega

var is_updating_shadows: bool = false # prevent
var texture_shadows_parent_suffix: String = "_Shadows"
var created_shadow_name_suffix: String = "_Shadow"
var caster_shapes_shadows: Dictionary = {} # zapovezavo casterjev in senčk

var shadow_rotation_deg: float = 45 setget _change_shadow_rotation # rotacija game sence, rotacija objekta
var shadow_length: float# končna dolžina sence ... (owner offset + owner height) * length factor

# game shadows
var shadows_color: = Color.red setget _change_shadows_color
var shadows_alpha: = 0.2 setget _change_shadows_alpha
var shadows_length_factor: float = 1 setget _change_shadows_length_factor # factor game sence (0 - 1)

# per owner
var shadow_owner_global_rotation_deg: float = 0
var shadow_owner_scale: Vector2 = Vector2.ONE
var shadow_owner_elevation: float = 50
var shadow_owner_height: float = 50

onready var shadow_owner: Node#2D


func _change_enabled(new_enabled):

	enabled = new_enabled
	if enabled:
		update_all_shadows()
	else:
		for child in get_children():
			child.queue_free()
		for shadow_casting_shape in caster_shapes_shadows.keys():
			caster_shapes_shadows.erase(shadow_casting_shape)

func _ready() -> void:

	add_to_group(Rfs.group_shadows)

	# nodes setup
	if shadow_caster_paths:

		if shadow_owner_path:
			shadow_owner = get_node(shadow_owner_path)
		else:
			shadow_owner = get_parent()

		# per game
		if Rfs.game_manager:
			shadow_rotation_deg = Rfs.game_manager.game_shadows_rotation_deg
			shadows_color = Rfs.game_manager.game_shadows_color
			shadows_alpha = Rfs.game_manager.game_shadows_alpha
			shadows_length_factor = Rfs.game_manager.game_shadows_length_factor

		# per owner
		shadow_owner_global_rotation_deg = shadow_owner.global_rotation_degrees
		shadow_owner_scale = shadow_owner.scale
		shadow_owner_elevation = 0
		if "elevation" in shadow_owner:
			shadow_owner_elevation = shadow_owner.elevation
		shadow_owner_height = 0
		if "height" in shadow_owner:
			shadow_owner_height = shadow_owner.height
		modulate.a = shadows_alpha

		update_all_shadows()
	else:
		hide()


func _process(delta: float) -> void:

	if shadow_owner and enabled:
		_detect_owner_change()


func update_all_shadows():

	if enabled:
		if not is_updating_shadows:# and not shape == null: # zaradi oblike vnosa (export array
			for child in get_children():
				if child is Polygon2D: # ne brišam
					child.queue_free()

			is_updating_shadows = true
			for shape_path in shadow_caster_paths:
				var caster_shape_from_path: Node = get_node(shape_path)
				if not caster_shape_from_path == null: # error če je array večji od števila povezanih poti
					_update_caster_shadow(caster_shape_from_path)
			emit_signal("all_shadows_updated")

			if not merge_all:
				is_updating_shadows = false
			elif merge_all and not get_children().empty():
				_merge_all_shadows()


func _merge_all_shadows():

	var shadows_to_merge: Array = _get_all_shadow_shapes()

	# ta način merganja ne upošteva situcij ko postaneta 2 mergana poligona
	var obsolete_shapes: Array = []
	var merged_shadow_polygon: PoolVector2Array = [shadows_to_merge[0].polygon]
	for shadow in shadows_to_merge:
		var merged_to_casting_polygon: Array = Geometry.merge_polygons_2d(merged_shadow_polygon, shadow.polygon)
		# 1 poligon je USPEH
		if merged_to_casting_polygon.size() == 1:
			# rezultat postane poligon na katerega mergam naprej
			merged_shadow_polygon = merged_to_casting_polygon[0]
			# uporabljen šejp postane odveč
			obsolete_shapes.append(shadow)
		# 2 poligona je FAIL
		elif merged_to_casting_polygon.size() > 1:
			# poligon na katerega mergam naprej ostane isti
			# uporabljen šejp postane osamelec
			pass

	# brišem senčke, ki sem jih zmergal
	for obsolete in obsolete_shapes:
		obsolete.queue_free()

	var new_shadow: Polygon2D = Polygon2D.new()
	new_shadow.name = "MergedShadow"
	new_shadow.polygon = merged_shadow_polygon
	new_shadow.color = shadows_color
	add_child(new_shadow)

	is_updating_shadows = false


# BUILD ------------------------------------------------------------------------------------------------------------


func _update_caster_shadow(caster_shape: Node):

	if not caster_shape.is_connected("draw", self, "_on_shadow_caster_draw"):
		caster_shape.connect("draw", self, "_on_shadow_caster_draw", [caster_shape])
	if not caster_shape.is_connected("visibility_changed", self, "_on_shadow_caster_visibility_changed"):
		caster_shape.connect("visibility_changed", self, "_on_shadow_caster_visibility_changed", [caster_shape])

	var shadow_caster_is_texture: bool = false

	match caster_shape.get_class():
		"Polygon2D", "CollisionPolygon2D":
			shadow_caster_is_texture = false
		"Sprite", "TextureRect":
			if caster_shape.texture:
				shadow_caster_is_texture = true
		"AnimatedSprite":
			if caster_shape.frames:
				shadow_caster_is_texture = true
				print("Shadows doesn't support AnimatedSprite .. currently")
				return
		"CollisionShape2D":
			if caster_shape.frames:
				shadow_caster_is_texture = true
				print("Shadows doesn't support CollisionShape2D")
				return


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
			new_shadow_shape.color = shadows_color
			new_shadow_shape.visible = shape_with_texture.visible # da v fazi kreiranja sence ve
			if shape_with_texture is Control:
				new_shadow_shape.position = shape_with_texture.rect_position
				new_shadow_shape.scale = shape_with_texture.rect_scale
				#				new_shadow_shape.rotation = shape_with_texture.rect_rotation
			elif Node2D:
				new_shadow_shape.position = shape_with_texture.position
				if "centered" in shape_with_texture:
					if shape_with_texture.centered:
						new_shadow_shape.position -= shape_with_texture.texture.get_size()/2 * shape_with_texture.scale
				new_shadow_shape.scale = shape_with_texture.scale
				#				new_shadow_shape.rotation = shape_with_texture.rotation
			_build_shadow_from_shape(new_shadow_shape, texture_shadows_parent)

		# senčko pripišem casterju
		caster_shapes_shadows[shape_with_texture] = texture_shadows_parent


func _build_shadow_from_shape(shadow_casting_shape, shadow_parent: Node = self):
	# dupliciram original polygon in ga zamaknem
	# povežem sorodne pare točko med obema poligonoma v kvadrate
	# kvadrate združim z original obliko

	if shadow_casting_shape.visible or shadow_casting_shape is CollisionPolygon2D:

		var shadow_casting_polygon: PoolVector2Array = shadow_casting_shape.polygon

		# main casting poligon ... offsetan, če je owner elevated
		var new_shadow_casting_polygon: PoolVector2Array = []
		var shadow_offset_length: float = shadow_owner_elevation * shadows_length_factor / shadow_casting_shape.scale.x / shadow_owner.scale.x
		var shadow_offset_in_direction: Vector2 = Vector2.RIGHT.rotated(deg2rad(shadow_rotation_deg - shadow_owner_global_rotation_deg)) * shadow_offset_length
		if shadow_offset_length == 0:
			new_shadow_casting_polygon = shadow_casting_polygon
		else:
			for point in shadow_casting_polygon:
				new_shadow_casting_polygon.append(point + shadow_offset_in_direction)
				# širjenje sence z dolžino ... new_shadow_casting_polygon.append(point + point.rotated(deg2rad(shadow_rotation_deg)) * shadow_length)

		# shadow poligon ... zamaknjene original točke
		var shadow_polygon: PoolVector2Array # zamaknjene original točke
		var shadow_length_sum: float = shadow_offset_length + (shadow_owner_height * shadows_length_factor / shadow_casting_shape.scale.x / shadow_owner.scale.x)
		var shadow_rotation_sum: float = deg2rad(shadow_rotation_deg - shadow_owner_global_rotation_deg) - shadow_casting_shape.rotation # rotiram še za rotacijo šejpa (sodeluje z rotacijo spawnane senčke)

		if shadow_length_sum == 0:
			if shadow_casting_shape in caster_shapes_shadows.keys():
				if caster_shapes_shadows[shadow_casting_shape]:
					caster_shapes_shadows[shadow_casting_shape].queue_free()
				caster_shapes_shadows.erase(shadow_casting_shape)
		else:
			var shadow_length_in_direction: Vector2 = Vector2.RIGHT.rotated(shadow_rotation_sum) * shadow_length_sum
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

			# spawnam mergano senčko
			var new_shadow: Polygon2D = Polygon2D.new()
			new_shadow.name = shadow_casting_shape.name + created_shadow_name_suffix
			new_shadow.polygon = merged_shadow
			new_shadow.color = shadows_color
			new_shadow.position = shadow_casting_shape.position
			if shadow_casting_shape is Polygon2D:
				new_shadow.position += shadow_casting_shape.offset
			# skejlam šejp senčke (sodeluje z dolžino zamika senčne podlage)
			new_shadow.scale = shadow_casting_shape.scale
			# rotiram šejp senčke (sodeluje z rotacijo zamika senčne podlage)
			new_shadow.rotation = shadow_casting_shape.rotation
			shadow_parent.add_child(new_shadow)

			# zbrišem staro senčko casterja in mu pripišem novo
			if shadow_casting_shape in caster_shapes_shadows.keys():
				if caster_shapes_shadows[shadow_casting_shape]:
					caster_shapes_shadows[shadow_casting_shape].queue_free()
				caster_shapes_shadows.erase(shadow_casting_shape)

			caster_shapes_shadows[shadow_casting_shape] = new_shadow
	else:
		if shadow_casting_shape in caster_shapes_shadows.keys():
			if caster_shapes_shadows[shadow_casting_shape]:
				caster_shapes_shadows[shadow_casting_shape].queue_free()
			caster_shapes_shadows.erase(shadow_casting_shape)

# HELPERS -----------------------------------------------------------------------------------------------

func _get_all_shadow_shapes():

	var all_current_shadows: Array = []
	for child in get_children():
		if child is Polygon2D: # poligoni
			all_current_shadows.append(child)
		else: # textrune senčke
			for child_2 in child.get_children():
				all_current_shadows.append(child_2)

	return all_current_shadows


func _detect_owner_change(): # vedno spreminja vse sence

	var update_needed: bool = false

	# rotacija
	var prev_rotation_deg = shadow_owner_global_rotation_deg
	shadow_owner_global_rotation_deg = shadow_owner.global_rotation_degrees
	if not shadow_owner_global_rotation_deg - prev_rotation_deg == 0:
		update_needed = true
	# scale
	var prev_scale = shadow_owner_scale
	shadow_owner_scale = shadow_owner.scale
	if not shadow_owner_scale.x - prev_scale.x == 0:
		update_needed = true
	# elevation
	if "elevation" in shadow_owner:
		var prev_elevation = shadow_owner_elevation
		shadow_owner_elevation = shadow_owner.elevation
		if not shadow_owner_elevation - prev_elevation == 0:
			update_needed = true
	# height
	if "height" in shadow_owner:
		var prev_height = shadow_owner_height
		shadow_owner_height = shadow_owner.height
		if not shadow_owner_height - prev_height == 0:
			update_needed = true

	if update_needed:
		update_all_shadows()


func _change_shadow_rotation(new_rotation_deg: float): # game setting
	#	print("setget _change_shadow_rotation")

	if not shadow_rotation_deg == new_rotation_deg: # OPT preverjanje trenutno nekaj zjebe ... popravi
		shadow_rotation_deg = new_rotation_deg
		update_all_shadows()


func _change_shadows_length_factor(new_length_factor: float): # game setting
	#	printt("setget _change_shadows_length_factor")

	if not shadows_length_factor == new_length_factor:
		shadows_length_factor = new_length_factor
		update_all_shadows()


func _change_shadows_color(new_color: Color): # game setting
	#	printt("setget _change_shadows_color")

	if not shadows_color == new_color:
		shadows_color = new_color
		for shadow in _get_all_shadow_shapes():
			shadow.color = shadows_color


func _change_shadows_alpha(new_alpha: float): # game setting
	#	printt("setget _change_shadows_alpha")

	if not shadows_alpha == new_alpha:
		shadows_alpha = new_alpha
		modulate.a = shadows_alpha


# SIGNALI -----------------------------------------------------------------------------------------------


func _on_shadow_caster_draw(caster_shape):
	#	print ("draw caster", caster_shape.get_parent().name)

	if merge_all:
		update_all_shadows()
	else:
		_update_caster_shadow(caster_shape)


func _on_shadow_caster_visibility_changed(caster_shape):
	#	print ("draw caster")

	if merge_all:
		update_all_shadows()
	else:
		_update_caster_shadow(caster_shape)
