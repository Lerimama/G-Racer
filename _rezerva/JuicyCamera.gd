extends Camera2D

export (OpenSimplexNoise) var noise
export(float, 0, 1) var trauma = 0.0

export var max_x = 150
export var max_y = 150
export var max_r = 25

export var time_scale = 150

export(float, 0, 1) var decay = 0.6

var time = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func add_trauma(trauma_in):
	trauma = clamp(trauma + trauma_in, 0, 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta
	
	var shake = pow(trauma, 2)
	offset.x = noise.get_noise_3d(time * time_scale, 0, 0) * max_x * shake
	offset.y = noise.get_noise_3d(0, time * time_scale, 0) * max_y * shake
	rotation_degrees = noise.get_noise_3d(0, 0, time * time_scale) * max_r * shake
	
	if trauma > 0: trauma = clamp(trauma - (delta * decay), 0, 1)
	
	$CanvasLayer/ProgressBar.value = trauma
	$CanvasLayer/ProgressBar2.value = shake


func _on_Button_pressed():
	add_trauma(0.33)


func _on_VSlider_value_changed(value):
	Engine.time_scale = value


#extends Camera2D
#
#
#export (OpenSimplexNoise) var noise # noise ima 3 dimenzije
## ena dimenzija je levo-desno 
## ena dimenzija je gor-dol 
## ena dimenzija je rotacija
#
#var time = 0
#export var time_speed = 100 # da povečamo hitrost šibanja noisa
#
#export (float, 0, 1) var trauma = 0
#export  (float, 0, 1) var decay = 0
#
#export var max_x = 150
#export var max_y = 150
#export var max_rot = 45
#
#
#func _ready() -> void:
#	print ("Camera")
#	print ("----------------------")
#
#
## rast travme skozi šejk
#func add_trauma(trauma_in):
#	trauma = clamp(trauma + trauma_in, 0, 1)
#
#
#func _process(delta: float) -> void:
#	time += delta
#
#	var shake = pow(trauma, 2) # trauma se expotencialno veča
#	offset.x = noise.get_noise_3d(time * time_speed, 0, 0) * max_x * shake
#	offset.y = noise.get_noise_3d(0, time * time_speed, 0) * max_y * shake
#	rotation_degrees = noise.get_noise_3d(0, 0, time * time_speed) * max_rot * shake
#	# get_noise_3d skače -1 oz. +1 glede na barvo, zato ga množimo z 
#
#	# decay
#	if trauma > 0:
#		trauma = clamp(trauma - (delta * decay), 0, 1)
#
#	$CanvasLayer/ProgressBar2.value = trauma
#	$CanvasLayer/ProgressBar. value = shake
#
#func _on_TimeSlider_value_changed(value: float) -> void:
#	Engine.time_scale = value
##	print("time changed")
#
#
#func _on_Button_pressed() -> void:
#	add_trauma(0.33)
#
#
#	pass # Replace with function body.
