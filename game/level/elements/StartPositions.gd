tool
extends Node2D


export (int, 1, 20) var position_count: int = 1 setget _change_positions_count

enum POSITIONS_SHAPE {GRID, CIRCLE, CUSTOM, RANDOM}
export (POSITIONS_SHAPE) var positions_shape: int = 0 setget _change_positions_shape

enum ROTATION_TYPE {NONE, RANDOM, FOLLOW_LEFT, FOLLOW_RIGHT, LOOK_AWAY, TO_CENTER}
export (ROTATION_TYPE) var circle_rotation_type: int = 0 setget _change_rotation_type

var active_position_2ds: Array = []
onready var driver_position_template: Control = $DriverPosition

var current_positions_holder: Control # za adaptiranje ob grebanju iz levela

func _ready() -> void:

	# debug reset
	_delete_all_spawned_positions()
	hide()


func _change_positions_count(new_positions_count: int):

	if not is_node_ready(): # za tool mora bit včasih off
		return

	position_count = new_positions_count
	driver_position_template = $DriverPosition # za tool
	var rotation_per_position_deg: float = 360 / float(position_count)

	# reset
	_delete_all_spawned_positions()
	active_position_2ds.clear()

	match positions_shape:

		POSITIONS_SHAPE.GRID:
			current_positions_holder = $PositionsGrid # za tool je node
			for count in position_count: # template je že notri
				var new_start_position: Control = driver_position_template.duplicate()
				var start_position_2d: Position2D = new_start_position.get_child(0).get_child(0)
				start_position_2d.global_rotation = _get_rotatation_by_type(rotation_per_position_deg * count)
				current_positions_holder.add_child(new_start_position)
				active_position_2ds.append(start_position_2d)
				new_start_position.show() # za tool ... itak je v igri cel node skrit

		POSITIONS_SHAPE.CIRCLE:
			current_positions_holder = $PositionsCirco # za tool je node
			# rotacija radij vektorja
			var center_position: Vector2 = Vector2(current_positions_holder.rect_size.x/2, current_positions_holder.rect_size.y/2)
			var vector_from_center_to_position: Vector2 = Vector2(0, current_positions_holder.rect_size.y/2)
			# spawn
			for count in position_count: # template je že notri
				var spawn_position: Vector2 = vector_from_center_to_position.rotated(deg2rad(rotation_per_position_deg) * count)# + center_position
				spawn_position += center_position
				var new_start_position: Control = driver_position_template.duplicate()
				new_start_position.rect_position = spawn_position
				var start_position_2d: Position2D = new_start_position.get_child(0).get_child(0)
				start_position_2d.global_rotation = _get_rotatation_by_type(rotation_per_position_deg * count)
				current_positions_holder.add_child(new_start_position)
				active_position_2ds.append(start_position_2d)
				new_start_position.show() # za tool ... itak je v igri cel node skrit

		POSITIONS_SHAPE.RANDOM:
			randomize()
			current_positions_holder = $PositionsRandom # za tool je node
			# random position
			var random_hor_positions: Array = []
			var random_ver_positions: Array = []
			for x_pos in int(current_positions_holder.rect_size.x):
				random_hor_positions.append(x_pos)
			for x_pos in int(current_positions_holder.rect_size.x):
				random_ver_positions.append(x_pos)
			# spawn
			for count in position_count: # template je že notri
				var spawn_position_x: float = random_hor_positions.pick_random()
				var spawn_position_y: float = random_ver_positions.pick_random()
				random_hor_positions.erase(spawn_position_x)
				random_hor_positions.erase(spawn_position_y)
				var random_spawn_position: Vector2 = Vector2(spawn_position_x, spawn_position_y)
				var new_start_position: Control = driver_position_template.duplicate()
				new_start_position.rect_position = random_spawn_position
				var start_position_2d: Position2D = new_start_position.get_child(0).get_child(0)
				start_position_2d.global_rotation = _get_rotatation_by_type(rotation_per_position_deg * count)
				current_positions_holder.add_child(new_start_position)
				active_position_2ds.append(start_position_2d)
				new_start_position.show() # za tool ... itak je v igri cel node skrit

		POSITIONS_SHAPE.CUSTOM: pass # ročno postavljanje v editorju


func _get_rotatation_by_type(rotation_angle: float):

	var new_rotation: float = 0
	match circle_rotation_type:
		ROTATION_TYPE.NONE:
			new_rotation = deg2rad(-90)
		ROTATION_TYPE.RANDOM:
			new_rotation = rand_range(0, 360)
		ROTATION_TYPE.FOLLOW_RIGHT:
			new_rotation = deg2rad(rotation_angle -180)
		ROTATION_TYPE.FOLLOW_LEFT:
			new_rotation = deg2rad(rotation_angle)
		ROTATION_TYPE.LOOK_AWAY:
			new_rotation = deg2rad(rotation_angle + 90)
		ROTATION_TYPE.TO_CENTER:
			new_rotation = deg2rad(rotation_angle - 90)

	return new_rotation


func _change_rotation_type(new_rotation_type: int):

	circle_rotation_type = new_rotation_type
	self.position_count = position_count


func _change_positions_shape(new_positions_shape: int):

	_delete_all_spawned_positions()

	positions_shape = new_positions_shape
	self.position_count = position_count


func _delete_all_spawned_positions():
	# CUSTOM brišeš in dodajaš ročno

	if not is_node_ready(): # za tool
		return
	for child in $PositionsGrid.get_children():
		child.queue_free()
	for child in $PositionsCirco.get_children():
		child.queue_free()
	for child in $PositionsRandom.get_children():
		child.queue_free()
