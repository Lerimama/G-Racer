extends Node2D


var _helper_nodes: Array = []
var helper_nodes_prefix: String = "__"


func hide_helper_nodes(delete_it: bool = false):

	get_all_nodes_in_node(helper_nodes_prefix)
	for node in _helper_nodes:
		print("__helper nodes: ", node)
		if "visible" in node:
				node.hide()


func get_all_nodes_in_node(string_to_search: String = "", node_to_check: Node = get_tree().root, all_nodes_of_nodes: Array = []):

	all_nodes_of_nodes.push_back(node_to_check)
	for node in node_to_check.get_children():
		if not string_to_search.empty() and node.name.begins_with(string_to_search):
			#			printt("node", node.name, node.get_parent())
			if node.name.begins_with(helper_nodes_prefix):
				_helper_nodes.append(node)
		all_nodes_of_nodes = get_all_nodes_in_node(string_to_search, node)

	return all_nodes_of_nodes


func get_hunds_from_clock(clock_string: String):

	var clock_format: String = "00:00.00"

	var mins: int = int(clock_string.get_slice(":", 0))
	var secs_and_hunds: String = clock_string.get_slice(":", 1)
	var secs: int = int(clock_string.get_slice(".", 0))
	var hunds: int = int(clock_string.get_slice(".", 1))

	return (mins * 60 * 100) + (secs * 100) + hunds


func get_clock_time_string(hundreds_to_split: int): # cele stotinke ali ne cele sekunde

	# če so podane stotinke, pretvorim v sekunde z decimalko
	var seconds_to_split: float = hundreds_to_split / 100.0

	# če so podane sekunde
	var minutes: int = floor(seconds_to_split / 60) # vse cele sekunde delim s 60
	var seconds: int = floor(seconds_to_split) - minutes * 60 # vse sekunde minus sekunde v celih minutah
	var hundreds: int = round((seconds_to_split - floor(seconds_to_split)) * 100) # decimalke množim x 100 in zaokrožim na celo

	# če je točno 100 stotink doda 1 sekundo da stotinke na 0
	if hundreds == 100:
		seconds += 1
		hundreds = 0

	# return [minutes, seconds, hundreds]
#	var time_on_clock: String = "%02d" % minutes + ":" + "%02d" % seconds + ":" + "%02d" % hundreds
	var time_on_clock: String = "%02d" % minutes + ":" + "%02d" % seconds + "." + "%02d" % hundreds

	return time_on_clock


func get_clock_time_array(hundreds_to_split: int): # cele stotinke ali ne cele sekunde

	var seconds: float = hundreds_to_split / 100.0
	var rounded_minutes: int = floor(seconds / 60) # vse cele sekunde delim s 60
	var rounded_seconds_leftover: int = floor(seconds) - rounded_minutes * 60 # vse sekunde minus sekunde v celih minutah
	var rounded_hundreds_leftover: int = round((seconds - floor(seconds)) * 100) # decimalke množim x 100 in zaokrožim na celo

	# če je točno 100 stotink doda 1 sekundo da stotinke na 0
	if rounded_hundreds_leftover == 100:
		rounded_seconds_leftover += 1
		rounded_hundreds_leftover = 0

	return [rounded_minutes, rounded_seconds_leftover, rounded_hundreds_leftover]


func generate_random_string(random_string_length: int):

#	var available_characters: Array = [a, ]
	var available_characters: String = "ABCDEFGHIJKLMNURSTUVZYXWQ0123456789"
	var random_string: String = ""
	for character in random_string_length:
		var random_index: int = randi() % available_characters.length()
		random_string += available_characters[random_index]

	#	print ("Random string ", random_string)

	return random_string


func get_all_named_collision_layers(in_range: int = 21):

	var layer_names_by_index = {}

	for i in range(1, in_range):
		var layer_name = ProjectSettings.get_setting("layer_names/2d_physics/layer_" + str(i))
		if layer_name:
			layer_names_by_index[i] = layer_name
		#			print("Layer " + str(i) + ": " + layer_name)

	return layer_names_by_index


func get_absolute_z_index(target: Node2D) -> int:

	var node = target
	var z_index = 0
	while node and node is Node2D:
		z_index += node.z_index
		if not node.z_as_relative:
			break
		node = node.get_parent()

	return z_index


func get_tilemap_cells(tilemap: TileMap):
	# kadar me zanimajo tudi prazne celice

	var tilemap_cells: Array = [] # celice v gridu

	for x in tilemap.get_used_rect().size.x:
		for y in tilemap.get_used_rect().size.y:
			var cell: Vector2 = Vector2(x, y)
			tilemap_cells.append(cell)

	return tilemap_cells


func remove_chidren_and_get_template(node_with_children: Array, delete_all: bool = false):

	# grab template
#	var template = node_with_children.get_child(0).duplicate()
	var template
	if not delete_all:
		template = node_with_children[0].duplicate()

	# reset children
	for child in node_with_children:
		child.queue_free()

	if not delete_all:
		return template


func spawn_polygon_2d(poylgon_points: PoolVector2Array, spawn_parent = get_tree().root, col: Color = Color.blue):

	var new_polygon_shape: Polygon2D = Polygon2D.new()
	new_polygon_shape.polygon = poylgon_points
	new_polygon_shape.color = col
	spawn_parent.add_child(new_polygon_shape)

	return new_polygon_shape


func spawn_line_2d(first_point: Vector2, second_point: Vector2, spawn_parent = get_tree().root, col: Color = Color.blue, line_width: float = 10):

	var new_indikator_line = Line2D.new()
	new_indikator_line.points =[first_point, second_point]
	new_indikator_line.default_color = col
	new_indikator_line.width = line_width
	spawn_parent.call_deferred("add_child", new_indikator_line)

	#	spawn_parent.add_child(new_indikator_line)

	return new_indikator_line


func get_directed_raycast_collision(raycast_node: RayCast2D, check_position: Vector2):

		var distance_to_position: float = (check_position - raycast_node.global_position).length()
		raycast_node.look_at(check_position)
		raycast_node.cast_to.x = distance_to_position
		raycast_node.force_raycast_update()

		return raycast_node.get_collider()


func get_rotating_raycast_collision(raycast_node: RayCast2D, ray_direction: Vector2, raycast_length: float = 450):

	if raycast_length == 0:
		return
	else:
		raycast_node.cast_to = ray_direction * raycast_length
		raycast_node.force_raycast_update()

		return raycast_node.get_collider()


func check_front_back(checker_node: Node2D, position_to_check: Vector2):

	var checker_vector_rotated: Vector2 = Vector2.RIGHT.rotated(checker_node.global_rotation)
	var vector_to_target: Vector2 = position_to_check - checker_node.global_position

	var is_target_in_front: int = checker_vector_rotated.dot(vector_to_target)

	# tole je samo kopirano od levo/desno ... lajhko je obratno
	# FRONT
	if is_target_in_front > 1:
		return Vector2.UP
	# BACK
	elif is_target_in_front < 1:
		return Vector2.DOWN
	# STREJT
	else:
		return Vector2.ZERO


func check_left_right(checker_node: Node2D, position_to_check: Vector2):

	var checker_vector_rotated: Vector2 = Vector2.RIGHT.rotated(checker_node.global_rotation)
	var vector_to_target: Vector2 = position_to_check - checker_node.global_position

	var is_target_on_right: int = checker_vector_rotated.cross(vector_to_target)

	# RIGHT
	if is_target_on_right > 1:
		return Vector2.RIGHT
	# LEFT
	elif is_target_on_right < 1:
		return Vector2.LEFT
	# STREJT
	else:
		return Vector2.ZERO


# DEBUGGING ---------------------------------------------------------------------------------------------------------------


var all_indikators_spawned: Array = []
var all_indikator_lines_spawned: Array = []
onready var indikator: PackedScene = preload("res://common/debug/DebugIndikator.tscn")


func spawn_indikator(pos: Vector2, col: Color = Color.red, rot: float = 0, parent_node = get_tree().root, clear_spawned_before: bool = false, scale_by: float = 50):

	if clear_spawned_before:
		for indi in all_indikators_spawned:
			indi.queue_free()
		all_indikators_spawned.clear()

	var new_indikator = indikator.instance()
	new_indikator.global_position = pos
	new_indikator.global_rotation = rot
	new_indikator.modulate = col
	new_indikator.z_index = 1000
	parent_node.call_deferred("add_child", new_indikator)
#	parent_node.add_child(new_indikator)

	new_indikator.scale *= scale_by
#	all_indikators_spawned.append(new_indikator)

	return new_indikator


func spawn_indikator_line(first_point: Vector2, second_point: Vector2, col: Color = Color.blue, parent_node = get_tree().root, clear_spawned_before: bool = false):

	if clear_spawned_before:
		for line in all_indikator_lines_spawned:
			line.queue_free()
		all_indikator_lines_spawned.clear()

	var new_indikator_line = Line2D.new()
	new_indikator_line.points =[first_point, second_point]
	new_indikator_line.z_index = 100
	new_indikator_line.default_color = col
	parent_node.add_child(new_indikator_line)

	new_indikator_line.width = 10
	all_indikator_lines_spawned.append(new_indikator_line)

	return new_indikator_line
