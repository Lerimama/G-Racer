extends Node

#> tale vrstica odstrani errorje iz kode
	
# ---------- inline timer
func timer():
	yield(get_tree().create_timer(0.0), "timeout")

func tween():
# ---------- inline tween
	var ime = get_tree().create_tween()
	ime.tween_property(node, "property", end_value, time)
	ime.parallel().tween_property(node, "property", end_value, time)
	ime.tween_callback(node, "method")
#	ime.tween_method(object: Object, method: String, from: Variant, to: Variant, duration: float, binds: Array = [  ])

func shaders():
	
	# šejder snipiz gre v filet za šejder snipije
	# ---------- šejder pixelizacija
#	vec2 grid_uv = round(UV * texture_size.x ) / texture_size.y; // pixelizacija efekta
	pass


func flat_shadows_on_texture():

	var sprite_center: Vector2 = Vector2(-4.5,-5) # dodamo sprite offset
	var shadow_offset: float = 5.0
	var engines_alpha: float = 1.0

	
#func _process(delta: float) -> void:
	update()

#func _draw():
	var shadow_position: Vector2
	var sprite_angle: float

	sprite_angle = rotation + rad2deg(90) # z dodatkom 90 stopinj dobimo vetikalni zamik 
	shadow_position.x = sprite_center.x - (shadow_offset * sin(sprite_angle)) # seštevanje ali odštevanje določa gor ali dol
	shadow_position.y = sprite_center.y - ((shadow_offset) * cos(sprite_angle))

	draw_set_transform(Vector2.ZERO, deg2rad(90), Vector2.ONE)
	draw_texture(bolt_sprite.texture, shadow_position, Color( 0, 0, 0, 0.3 ))



func tilemap_cell_detection():

	var used_tiles = get_used_cells_by_id(tile_id) # autotile region ima en id
	# array of all cells with the given id

	var used_tile = map_to_world(used_tiles[0])
	# returns global position coresponding to grid-based coords

	var autotile = get_cell_autotile_coord(used_tiles[0][0], used_tiles[0][1])
	# returns coord of tile variation in region
	# returns zero vector if cell has no autotileing




