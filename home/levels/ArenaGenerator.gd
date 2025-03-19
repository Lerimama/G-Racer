extends Node2D


#const Player = preload("res://game/player/Player.tscn")
#const Exit = preload("res://ExitDoor.tscn")

var borders = Rect2(1, 1, 158, 88) # velikost viewporta v tiletih - zunanje linija
var room_steps_size: int = 500
var steps_count_limit = 10000
var walker_start_position: Vector2 = Vector2 (78, 43)
#onready var world_camera: Camera2D = $Camera2D

onready var arena_tilemap: TileMap = $ArenaTileMap
export var empty_side_cell_limit = 5


func _ready() -> void:
	randomize() # izključi za pedenanje in debugging
	generate_level()
	print("world_in")

func generate_level():
	# spawnamo walker skript
	var walker = Walker.new(walker_start_position, borders) # hočemo cirka polovico ... tko prav on
	# mu podamo mapo, po kateri naredi korake
	var map = walker.walk(steps_count_limit)

	# --- insert za štart in cilj
#	var player = Player.instance()
#	add_child(player)
#	player.position = map.front()*32
#
#	var exit = Exit.instance()
#	add_child(exit)
#	exit.position = walker.get_end_room().position*32
#	exit.connect("leaving_level", self, "reload_level")
	# ---

	# potem ga zbrišemo
	walker.queue_free()
#	print(map)
	# vse celice sprazni
	for cell_location in map:
#		print(map)
		arena_tilemap.set_cellv(cell_location, -1)
#
	# updejt bitmask v kvadratu od zgoraj levo do spodaj desno
	arena_tilemap.update_bitmask_region(borders.position, borders.end)

func reload_level():
	get_tree().reload_current_scene()


func _input(event):
	if event.is_action_pressed("ui_accept"):
		reload_level()
		cleanup_map()


func cleanup_map():

		# dobi vse polne celice
		var cells_left_after_walker: Array = arena_tilemap.get_used_cells()

		for cell in cells_left_after_walker: # cell je cell location

			var cell_in_check: Vector2
			var empty_cell_counter: int = 0

			# preveri vse sosede, če je dovolj sosed praznih, jo sprazni
			for y in 3:
				for x in 3:
					cell_in_check = cell + Vector2(x - 1, y - 1)

					# štejemo prazne sosede
					if arena_tilemap.get_cellv(cell_in_check) == -1:
						empty_cell_counter += 1

						# če je števec praznih dovolj visok sprazni celico
						if empty_cell_counter == empty_side_cell_limit:
							arena_tilemap.set_cellv (cell, -1) # id 5 so zelene barve
							continue
#				else:

#			print(empty_cell_counter)

		arena_tilemap.update_bitmask_region(borders.position, borders.end)

