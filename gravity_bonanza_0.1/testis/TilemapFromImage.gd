extends Node2D


const TILES = {
	"track_edge": 2,
	"track": 3,
	"offtrack": 4,
}

var path = preload("res://testis/320x460_proga.png")

func _ready() -> void:
	
	var image = path.get_data()
	
	image.lock()
	
	var width = image.get_width()
	var height = image.get_height()
	
	#load map
	for y in range(width):
		for x in range(height):
			var c = str(image.get_pixel(x,y))
			var t = -1 # izbrani tile je "null"
			if (c == "0,1,0,1"):
				t = TILES.track_edge
			if (c == "1,0,0,1"):
				t = TILES.track
			if (c == "1,1,1,1"):
				t = TILES.offtrack
			if (c == "0,0,1,1"):
				t = TILES.offtrack
			if(t == -1):
				print (image.get_pixel(x,y))
			
			$TileMap.set_cell(x,y,t)
#			$TileMap2.update_bitmask_region()
			print($TileMap.set_cell(x,y,t))
	
	image.unlock()

#func _process(delta: float) -> void:
	# mouse follow camera
#	$Camera2D.position += (get_global_mouse_position() - $Camera2D.position).normalized()*100*delta

