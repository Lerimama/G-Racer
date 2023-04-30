extends Node2D


# FX brick_tile_index
enum Elements {GOAL_PILLAR = 6, GHOST_BRICK, BOUNCER_BRICK, MAGNET_BRICK, TARGET_BRICK, LIGHT_BRICK}  

onready var goal_pillar: PackedScene = preload("res://scenes/arena/GoalPillar.tscn")
onready var ghost_brick: PackedScene = preload("res://scenes/bricks/GhostBrick.tscn")
onready var bouncer_brick: PackedScene = preload("res://scenes/bricks/BouncerBrick.tscn")
onready var magnet_brick: PackedScene = preload("res://scenes/bricks/MagnetBrick.tscn")
onready var target_brick: PackedScene = preload("res://scenes/bricks/TargetBrick.tscn")

onready var edge: TileMap = $Edge


func _ready() -> void:
	call_deferred("setup_tiles")	# funkcijo "setup_tiles" se izvede šele, ko se celotn drevo naloži


func setup_tiles():
	
	var tilemap_cells = edge.get_used_cells() # dobi vse celice brez indexa -1

	for cell_position in tilemap_cells:
		
		var cell_index = edge.get_cell(cell_position.x, cell_position.y)
			
		match cell_index: # dodamo v isto drevo kot je trenutni Brickset
			Elements.GOAL_PILLAR: create_instance_from_tilemap (cell_position, goal_pillar, self, Vector2 (13, 8))
			
			Elements.GHOST_BRICK: create_instance_from_tilemap (cell_position, ghost_brick, self, Vector2 (5, 0))
			Elements.BOUNCER_BRICK: create_instance_from_tilemap (cell_position, bouncer_brick, self, Vector2 (5, 0))
			Elements.MAGNET_BRICK: create_instance_from_tilemap (cell_position, magnet_brick, self, Vector2 (5, 0))	
			Elements.TARGET_BRICK: create_instance_from_tilemap (cell_position, target_brick, self, Vector2 (5, 0))


func create_instance_from_tilemap(coord:Vector2, brick_scene:PackedScene, parent: Node2D, brick_anchor_offset:Vector2): # = Vector2.ZERO):	# primer dobre prakse ... static typing
	
	edge.set_cell(coord.x, coord.y, -1)	# zbrišeš trenutni tile tako da ga zamenjaš z indexom -1 (prazen tile)
	var new_brick_scene = brick_scene.instance() #
	new_brick_scene.position = edge.map_to_world(coord) + brick_anchor_offset
#	new_brick_scene.scale = Vector2(0.5, 0.5)
	add_child(new_brick_scene)	


func _on_FloorGap_body_entered(body: Node) -> void:
	if body is Bolt:
		body.control_enabled = false


func _on_FloorGap_body_exited(body: Node) -> void:
	if body is Bolt:
		body.modulate = Color.red
		body.control_enabled = true
		pass # Replace with function body.
