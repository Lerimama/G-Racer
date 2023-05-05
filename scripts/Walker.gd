extends Node
class_name Walker


const DIRECTIONS = [Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN]

export var turn_chance: float = 0.2
export var steps_limit: int = 10
export var room_random_size: Array = [1, 3]

var walker_position = Vector2.ZERO
var walker_direction = Vector2.RIGHT
var borders = Rect2()
var step_history = []
var steps_since_turn = 0
var rooms = []

func _init(starting_position, new_borders):
	assert(new_borders.has_point(starting_position))
	walker_position = starting_position
	step_history.append(walker_position)
	borders = new_borders

func walk(steps):
#	place_room(walker_position)
	for step in steps:
		if randf() <= turn_chance or steps_since_turn >= steps_limit:
#		if steps_since_turn >= 6:
			change_direction()
		
		if step():
			step_history.append(walker_position)
		else:
			change_direction()
	return step_history

func step():
	var target_position = walker_position + walker_direction
	if borders.has_point(target_position):
		steps_since_turn += 1
		walker_position = target_position
		return true
	else:
		return false

func change_direction():
#	place_room(walker_position)
	steps_since_turn = 0
	var directions = DIRECTIONS.duplicate()
	directions.erase(walker_direction)
	directions.shuffle()
	walker_direction = directions.pop_front()
	while not borders.has_point(walker_position + walker_direction):
		walker_direction = directions.pop_front()





func create_room(new_room_position, room_size):
	return {new_room_position = walker_position, room_size = room_size}


func place_room(room_position):
	var room_size = Vector2(randi() % room_random_size[0] + room_random_size[1], randi() % room_random_size[0] + room_random_size[1]) # random integer med 2 in 5 (4 -> 0,1,2,3,4 torej 5 cifr)
	var current_top_left_corner = (room_position - room_size/2).ceil() # top left corner je naša trenutna pozicija ... ceil zaokroži naš float
	rooms.append(create_room(room_position, room_size))
	
	# loopaj po gridu za velikost sobe
	for y in room_size.y:
		for x in room_size.x:
			var new_step = current_top_left_corner + Vector2(x, y)
			# step dodaj v zgoodovino, če je znotraj meja tilemapa
			if borders.has_point(new_step): 
				step_history.append(new_step)

func get_end_room():
	var end_room = rooms.pop_front()
	var starting_position = step_history.front()
	for room in rooms:
		if starting_position.distance_to(room.position) > starting_position.distance_to(end_room.position):
			end_room = room
	return end_room







