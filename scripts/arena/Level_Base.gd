extends Node2D


#var tile_position: Vector2

#onready var edge: TileMap = $Edge
#onready var broken_edge: TileMap = $EdgeBroken
#
#
#var krneki
#
#func _ready() -> void:
#
#	edge.connect("on_tile_hit", self, "brake_tile")
#
#
#func break_tile(tile_position):
#	print ("juhej")
#
#
#
#
#
#func _on_Edge_on_tile_hit(cell_position, autotile_coord) -> void:
#	print ("juhej")
#	print (autotile_coord)
#	print (cell_position)
#
##	(position: Vector2, tile: int, flip_x: bool = false, flip_y: bool = false, transpose: bool = false, autotile_coord: Vector2 = Vector2( 0, 0 ))	
##	if broken_edge.get_cellv(tile_position) == -1:
#
##	broken_edge.replace_tile(tile_position)
#
#	var broken_cell_index: int = broken_edge.get_cellv(cell_position) # vektor2 koordinate
#
#	if broken_cell_index == -1:
##		set_cellv(cell_position, -1) # sprazneš ... nadomestiš s prazno
#		broken_edge.set_cellv(cell_position, 2, false, false, false, autotile_coord) # sprazneš ... nadomestiš s prazno
#		print("broken_edge.get_cellv(cell_position)")
#		print(broken_edge.get_cellv(cell_position))
##		print(broken_edge.cell_index)
