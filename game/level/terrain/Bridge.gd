extends Node2D


enum UNDER_DIR {HOR, VER}
export (UNDER_DIR) var under_direction: int = UNDER_DIR.HOR setget _change_under_direction

export (NodePath) var node_to_bridge_path: String
var node_to_bridge: Node2D

var bodies_z_indexes: Dictionary = {}
var vertical_walls_coll_layer_bit: int
var horizontal_walls_coll_layer_bit: int
onready var horizontal_walls: Node2D = $HorizontalWalls
onready var vertical_walls: Node2D = $VerticalWalls


func _ready() -> void:

	if not node_to_bridge_path:
		node_to_bridge = get_node(node_to_bridge_path)
	else:
		node_to_bridge = self

	var top_coll_layer_bit: int = Mts.get_all_named_collision_layers().keys().max()
	vertical_walls_coll_layer_bit = top_coll_layer_bit
	horizontal_walls_coll_layer_bit = vertical_walls_coll_layer_bit + 1

	# hor wall collision bits
	for wall in horizontal_walls.get_children():
		wall.set_collision_layer_bit(horizontal_walls_coll_layer_bit, true)
		wall.set_collision_mask_bit(horizontal_walls_coll_layer_bit, true)
	#	$HorizontalWalls/StaticBody2D.set_collision_layer_bit(horizontal_walls_coll_layer_bit, true)
	#	$HorizontalWalls/StaticBody2D.set_collision_mask_bit(horizontal_walls_coll_layer_bit, true)
	#	$HorizontalWalls/StaticBody2D2.set_collision_layer_bit(horizontal_walls_coll_layer_bit, true)
	#	$HorizontalWalls/StaticBody2D2.set_collision_mask_bit(horizontal_walls_coll_layer_bit, true)

	for wall in vertical_walls.get_children():
		wall.set_collision_layer_bit(vertical_walls_coll_layer_bit, true)
		wall.set_collision_mask_bit(vertical_walls_coll_layer_bit, true)
	#	$VerticalWalls/StaticBody2D.set_collision_layer_bit(vertical_walls_coll_layer_bit, true)
	#	$VerticalWalls/StaticBody2D.set_collision_mask_bit(vertical_walls_coll_layer_bit, true)
	#	$VerticalWalls/StaticBody2D2.set_collision_layer_bit(vertical_walls_coll_layer_bit, true)
	#	$VerticalWalls/StaticBody2D2.set_collision_mask_bit(vertical_walls_coll_layer_bit, true)

	printt("bridge", node_to_bridge.z_index, horizontal_walls_coll_layer_bit, vertical_walls_coll_layer_bit)


func _change_under_direction(new_under_direction: int):

	under_direction = new_under_direction


func _on_DetectHor_body_entered(body: Node) -> void:
#	print("HOR")

	if not body in bodies_z_indexes:
		bodies_z_indexes[body] = [body.z_index, body.z_as_relative]
		body.z_as_relative = false
		match under_direction:
			UNDER_DIR.HOR:
				body.z_index = node_to_bridge.z_index - 1
				body.set_collision_layer_bit(horizontal_walls_coll_layer_bit, true)
				body.set_collision_mask_bit(horizontal_walls_coll_layer_bit, true)
				# off zazih
				body.set_collision_mask_bit(horizontal_walls_coll_layer_bit, false)
				body.set_collision_mask_bit(vertical_walls_coll_layer_bit, false)
			UNDER_DIR.VER:
				body.z_index = node_to_bridge.z_index + 1
				body.set_collision_layer_bit(vertical_walls_coll_layer_bit, true)
				body.set_collision_mask_bit(vertical_walls_coll_layer_bit, true)
				# off zazih
				body.set_collision_layer_bit(vertical_walls_coll_layer_bit, false)
				body.set_collision_layer_bit(horizontal_walls_coll_layer_bit, false)


func _on_DetectHor_body_exited(body: Node) -> void:

	if body in bodies_z_indexes:
		body.z_index = bodies_z_indexes[body][0]
		body.z_as_relative = bodies_z_indexes[body][1]
		bodies_z_indexes.erase(body)

		body.set_collision_layer_bit(vertical_walls_coll_layer_bit, false)
		body.set_collision_mask_bit(vertical_walls_coll_layer_bit, false)


func _on_DetectVer_body_entered(body: Node) -> void:

	if not body in bodies_z_indexes:
		bodies_z_indexes[body] = [body.z_index, body.z_as_relative]
		body.z_as_relative = false

		match under_direction:
			UNDER_DIR.HOR:
				body.z_index = node_to_bridge.z_index + 1
				body.set_collision_layer_bit(vertical_walls_coll_layer_bit, true)
				body.set_collision_mask_bit(vertical_walls_coll_layer_bit, true)
				# off zazih
				body.set_collision_layer_bit(horizontal_walls_coll_layer_bit, false)
				body.set_collision_mask_bit(horizontal_walls_coll_layer_bit, false)
			UNDER_DIR.VER:
				body.z_index = node_to_bridge.z_index - 10
				body.set_collision_layer_bit(horizontal_walls_coll_layer_bit, true)
				body.set_collision_mask_bit(horizontal_walls_coll_layer_bit, true)
				# off zazih
				body.set_collision_layer_bit(vertical_walls_coll_layer_bit, false)
				body.set_collision_mask_bit(vertical_walls_coll_layer_bit, false)


func _on_DetectVer_body_exited(body: Node) -> void:

	if body in bodies_z_indexes:
		body.z_index = bodies_z_indexes[body][0]
		body.z_as_relative = bodies_z_indexes[body][1]
		bodies_z_indexes.erase(body)

		body.set_collision_layer_bit(horizontal_walls_coll_layer_bit, false)
		body.set_collision_mask_bit(horizontal_walls_coll_layer_bit, false)

