extends Node2D

const WIDTH = 500
const HEIGHT = 500

const TILES = {
	"track_edge": 2,
	"track": 3,
	"offtrack": 4,
}

var noise
var path = preload("res://resources/320x460_proga.png")

func _ready() -> void:
	
	#from image
	
	var image = path.get_data()
	image.lock()
	var Ww = image.get_width()
	var Hh = image.get_height()
	
	print("image size" + str(Ww) + str(Hh))
	
	#load map
	for y in range(Ww):
		for x in range(Hh):
			var c = str(image.get_pixel(x,y))
			var t = -1 # izbrani tile je "null"
			
			if (c == "0,1,0,1"):
				t = 2
			if (c == "1,0,0,1"):
				t = 3
			if (c == "1,1,1,1"):
				t = 4
			if (c == "0,0,1,1"):
				t = 4
			if(t == -1):
				print (image.get_pixel(x,y))
#			place_tile(x,y,t)
			$TileMap2.set_cell(x,y,t)
#			$TileMap2.update_bitmask_region()
			print($TileMap2.set_cell(x,y,t))
	
	image.unlock()
	
	randomize()
	noise = OpenSimplexNoise.new()

	# Configure
	noise.seed = randi()
	noise.octaves = 1
	noise.period = 32.0
	noise.persistence = 0.8

#	_generate_world()
	

	# Sample
#	print(noise.get_noise_2d(1.0, 1.0))
#	print(noise.get_noise_3d(0.5, 3.0, 15.0))
#	print(noise.get_noise_4d(0.5, 1.9, 4.7, 0.0))

func _process(delta: float) -> void:
	
	# mouse follow camera
#	$Camera2D.position += (get_global_mouse_position() - $Camera2D.position).normalized()*100*delta
	pass
	
func place_tile(var x, var y, var t):
	$TileMap2.set_cell(x,y,y,t)
	
	
	

func _generate_world():
	
	for x in WIDTH:
		for y in HEIGHT:
			$TileMap.set_cellv(Vector2(x - WIDTH / 2, y - HEIGHT / 2), _get_tile_index(noise.get_noise_2d(float(x),float(y))))
	
	$TileMap.update_bitmask_region()
	
			
# pridobim index tileta			
func _get_tile_index(noise_sample):
	
#	print(noise_sample)
#	print($TileMap.tile_set.get_tiles_ids())
	
	if noise_sample < -0.5:
		return TILES.offtrack
	if noise_sample > 0:
		return TILES.track
	return TILES.track_edge
