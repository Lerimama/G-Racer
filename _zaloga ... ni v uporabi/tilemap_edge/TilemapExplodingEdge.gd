extends TileMap


var light_color: Color = Color.white # za barvanje debrisa

onready var edge_shadows: ColorRect = $EdgeShadows
onready var shadows_direction: Vector2 = Rfs.game_manager.game_settings["shadows_direction"] setget _on_shadow_direction_change
onready var DebrisParticles: PackedScene = preload("res://game/arena/EdgeDebrisParticles.tscn")
onready var ExplodingEdge: PackedScene = preload("res://game/arena/ExplodingEdge.tscn")

func _ready() -> void:

	# setam senco
#	var screen_size: Vector2 = get_viewport_rect().size * 0.25
#	edge_shadows.material.set_shader_param("screen_size", screen_size)
#	edge_shadows.material.set_shader_param("node_size", screen_size)
#	edge_shadows.material.set_shader_param("node_size", edge_shadows.rect_size)
	var edge_shadows_deg: float = get_angle_to(shadows_direction) + deg2rad(90) # adaptacija na "node" senčke
	edge_shadows.material.set_shader_param("shadow_rotation_deg", rad2deg(edge_shadows_deg))


func on_hit (collision_object):
	# tilemap prevede pozicijo na najbližjo pozicijo tileta v tilempu
	# to pomeni da lahko izbriše prazen tile
	# s tem ko poziciji dodamo nekaj malega v smeri gibanja izstrelka, poskrbimo, da je izbran pravi tile

	var collision_position: Vector2
	var collision_normal: Vector2

	collision_position = collision_object.vision_ray.get_collision_point() + collision_object.velocity.normalized()
	collision_normal = collision_object.vision_ray.get_collision_normal()

	var cell_position: Vector2 = world_to_map(collision_position) # katera celica je bila zadeta glede na global coords
	var cell_index: int = get_cellv(cell_position) # index zadete celice na poziciji v grid koordinatah

	if not cell_index == -1: # če ni prazen
		if collision_object is Bullet: # poškodovana zadeta celica
			var cell_region_position = get_cell_autotile_coord(cell_position.x, cell_position.y) # položaj celice v autotile regiji
			set_cellv(cell_position, 2, false, false, false, cell_region_position) # namestimo celico iz autotile regije z id = 2
			release_debris(collision_position, collision_normal)
			# release_debris(collision_object.collision)

		elif collision_object is Misile: # uničena zadeta celica in poškodovane vse sosednje
			set_cellv(cell_position, -1) # namestimo celico s prazno
			update_bitmask_area(cell_position) # vse celice se apdejtajo glede na novo stanje
			explode_tile(cell_position)


func release_debris(collision_position: Vector2, collision_normal: Vector2):

	var new_debris_particles = DebrisParticles.instance()
	new_debris_particles.position = collision_position
	new_debris_particles.rotation = collision_normal.angle() # rotacija partiklov glede na normalo površine
	new_debris_particles.color = light_color
	new_debris_particles.z_index = z_index + 1
	new_debris_particles.set_emitting(true)
	Rfs.node_creation_parent.add_child(new_debris_particles)


func explode_tile(current_cell):

	var surrounding_cells: Array = []
	var target_cell: Vector2

	# zadeta celica dobi celico, ki explodira
	var cell_global_position = map_to_world(current_cell)
	var new_exploding_cell = ExplodingEdge.instance()
	new_exploding_cell.global_position = cell_global_position
	new_exploding_cell.z_index = z_index + 1
	Rfs.node_creation_parent.add_child(new_exploding_cell)

	# poiščem sosede in jim dodam poškodovani autotile
	for y in 3:
		for x in 3:
			target_cell = current_cell + Vector2(x - 1, y - 1)
			if current_cell != target_cell:
				surrounding_cells.append(target_cell)
	for cell in surrounding_cells:
		var cell_region_position = get_cell_autotile_coord(cell.x, cell.y) # položaj celice v autotile regiji
		set_cellv(cell, 2, false, false, false, cell_region_position) # namestimo celico iz autotile regije z id = 2


func _on_shadow_direction_change(new_shadows_direction: Vector2):

	var edge_shadows_rotation: float = get_angle_to(new_shadows_direction) + deg2rad(90) # adaptacija na "node" senčke
	edge_shadows.material.set_shader_param("shadow_rotation_deg", rad2deg(edge_shadows_rotation))


func _on_EdgeShadows_resized() -> void:
	pass
#	edge_shadows.material.set_shader_param("node_size", edge_shadows.rect_size)
