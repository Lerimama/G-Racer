extends Node2D


func _ready() -> void:
	var noise = OpenSimplexNoise.new()

	# Configure
	noise.seed = randi()
	noise.octaves = 4
	noise.period = 20.0
	noise.persistence = 0.8

	# Sample
	print(noise.get_noise_2d(1.0, 1.0))
	print(noise.get_noise_3d(0.5, 3.0, 15.0))
	print(noise.get_noise_4d(0.5, 1.9, 4.7, 0.0))


	# This creates a 512x512 image filled with simplex noise (using the currently set parameters)
	var noise_image = noise.get_image(512, 512)

	# You can now access the values at each position like in any other image
	print(noise_image.get_pixel(10, 20))



## MAPA

#var noise
#var map_size = Vector2(00,00)
#var edge_cap = 0.5
#var road_caps = Vector2(0.3, 0.05)
#var enviroment_caps = Vector3(0.4, 0.3, 0.04)
#
#func _ready() -> void:
##	randomize()
#	noise = OpenSimplexNoise.new()
##	noise.seed = randi()
#	noise.octaves = 1.0
##	Number of OpenSimplex noise layers that are sampled to get the fractal noise. Higher values result in more detailed noise but take more time to generate. Max 9.
#
#	noise.period = 12
##	Period of the base octave. A lower period results in a higher-frequency noise (more value changes across the same distance).
#
##	noise.persistance = 1.0
##	Contribution factor of the different octaves. A persistence value of 1 means all the octaves have the same contribution, a value of 0.5 means each octave contributes half as much as the previous one.
#
#	noise.get_image( 500, 500, Vector2( 0, 0 ) )	
##	make_edge_map()
#
#func make_edge_map():
#	for x in map_size.x:
#		for y in map_size.y:
#			var a = noise.get_noise_2d(x,y)
#			if a < edge_cap:
#				$TrackEdge.set_cell(x,y,0)
#
##	$TrackEdge.update_bitmask_region(Vector2(0.0,0.0), Vector2(map_size.x, map_size.y))
	




### PREGLEJ


#var noise = OpenSimplexNoise.new()
#
## Configure
#noise.seed = randi()
#noise.octaves = 4
#noise.period = 20.0
#noise.persistence = 0.8
#
## Sample
#print("Values:")
#print(noise.get_noise_2d(1.0, 1.0))
#print(noise.get_noise_3d(0.5, 3.0, 15.0))
#print(noise.get_noise_4d(0.5, 1.9, 4.7, 0.0))
