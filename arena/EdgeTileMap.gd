extends TileMap


onready var lucka: PackedScene = preload("res://pixel.tscn")
onready var neonka: PackedScene = preload("res://EdgeLight.tscn")


func _ready() -> void:
	call_deferred("setup_tiles")	# funkcijo "setup_tiles" se izvede šele, ko se celotn drevo naloži

func setup_tiles():
	
	var cells = get_used_cells()	# dobi index vseh tiletov ... će  ima - 1 ni uporabljen

	for cell in cells:
		var index = get_cell(cell.x, cell.y)
		
		create_point(cell)
		
#		match index:
#			MAGNET:
#				create_instance_from_tilemap (cell, magnet, self, Vector2 (20,19))	# dodamo v isto drevo kot je trnutni Brickset
#				print ("magnet dodan")
#			BOUNCER:
#				create_instance_from_tilemap (cell, bouncer, self, Vector2 (20,19))	# dodamo v isto drevo kot je trnutni Brickset
#				print ("bouncer dodan")
#			POINTER:
#				create_instance_from_tilemap (cell, pointer, self, Vector2 (20,19))	# dodamo v isto drevo kot je trnutni Brickset
#				print ("pointer dodan")
#			EXPLODER:
#				create_instance_from_tilemap (cell, exploder, self, Vector2 (20,19))	# dodamo v isto drevo kot je trnutni Brickset
#				print ("exploder dodan")

func create_point(celica):
	# convert position
	
#	$Edge.set_cell(coord.x, coord.y, -1 )	# zbrišeš trenutni tile tako da ga zamenjaš z indexom -1 (prazen tile)
	var pikica = lucka.instance()
	pikica.position = map_to_world(celica)
	add_child(pikica)
	
	
#	var pikica = lucka.instance()
#	pikica.position = map_to_world(celica)
#	add_child(pikica)

#	$EDgeLight.add_point(celica)
	
	
	pass
func create_instance_from_tilemap(coord:Vector2, prefab:PackedScene, parent: Node2D, origin_zamik:Vector2 = Vector2.ZERO):	# primer dobre prakse ... static typing
	$BrickSet.set_cell(coord.x, coord.y, -1 )	# zbrišeš trenutni tile tako da ga zamenjaš z indexom -1 (prazen tile)
	var pf = prefab.instance()
	pf.position = $BrickSet.map_to_world(coord) - origin_zamik
	parent.add_child(pf)

#	var local_position = my_tilemap.map_to_world(map_position)
#	var global_position = my_tilemap.to_global(local_position)
