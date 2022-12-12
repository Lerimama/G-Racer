extends Node2D

const WIDTH = 101 # 1 dodaš, ker godot gre znotraj meje od 1 do 499
const HEIGHT = 101

const TILES = {
	"track_edge": 2,
	"track": 3,
	"offtrack": 4,
}

var noise: OpenSimplexNoise

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()
		
func _ready() -> void:
	
	randomize()
	noise = OpenSimplexNoise.new()

	# Configure noise
	noise.seed = randi()
	noise.octaves = 1
	noise.period = 32.0
	noise.persistence = 0.8

	_generate_world()
	
#func _process(delta: float) -> void:
#
#	# mouse follow camera
#	$Camera2D.position += (get_global_mouse_position() - $Camera2D.position).normalized()*500*delta
	

func _generate_world():
	
	for x in WIDTH:
		for y in HEIGHT:
			# v1
#			$TileMap.set_cellv(Vector2(x - WIDTH / 2, y - HEIGHT / 2), _get_tile_index(noise.get_noise_2d(float(x),float(y))))
			
			# v2 ... tukaj je narejeno tako, da se index tileta generira iz številke v noisu, ki jo pretvorimo v cel števila
			var id_from_noise := floor((abs(noise.get_noise_2d(x, y)))*5)
			$TileMap.set_cell(x, y, id_from_noise)
			print(id_from_noise)
			
	$TileMap.update_bitmask_region()
	
			
func _get_tile_index(noise_sample):
	
#	print(noise_sample)
#	print($TileMap.tile_set.get_tiles_ids())
	
	if noise_sample < -0.5:
		return TILES.offtrack
	if noise_sample > 0:
		return TILES.track
	return TILES.track_edge
