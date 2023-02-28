extends Node2D

#from simplex noise
func _ready() -> void:
	var noise = OpenSimplexNoise.new()

	# Configure
	noise.seed = randi()
	noise.octaves = 4
	noise.period = 20.0
	noise.persistence = 0.8

	print(noise.get_noise_2d(1.0, 1.0))
	print(noise.get_noise_3d(0.5, 3.0, 15.0))
	print(noise.get_noise_4d(0.5, 1.9, 4.7, 0.0))


	# This creates a 512x512 image filled with simplex noise (using the currently set parameters)
	var noise_image = noise.get_image(512, 512)

	# You can now access the values at each position like in any other image
	print(noise_image.get_pixel(10, 20))
