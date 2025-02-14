extends CanvasLayer


onready var shaker: Node = $"../Shaker"

export (OpenSimplexNoise) var noise # tekstura za vizualizacijo ma kopijo tega noisa

#var trauma
#var time_scale
#var max_horizontal
#var shake
#var max_vertical
#var decay
#var max_rotation
#var trauma_time

export(float, 0, 1) var trauma: float = 0.5
export var trauma_time: float = 0 # decay delay
export var max_horizontal: float = 150
export var max_vertical: float = 150
export var max_rotation: float = 25
export(float, 0, 1) var decay: float = 0.5
export var time_scale: float = 150

# traume
export(float, 0, 1) var add_trauma: float = 0.2

# battle shake


var shake_on: bool = false
export (float, 0, 1) var added_shake_trauma: float = 0.5
#export (float, 0, 1) var agent_explosion_shake = 0.5 # explosion add_trauma
#export (float, 0, 1) var bullet_hit_shake = 0.2 # bullet add_trauma
#export (float, 0, 1) var misile_hit_shake = 0.4 # misile add_trauma




var time: float = 0
var test_view_on = false

# mouse drag
var mouse_used: bool = false # če je miška ni redi z dreganje ekrana
var camera_center = Vector2(320, 180)
var mouse_position_on_drag_start: Vector2 # zamik pozicije miške ob kliku
var drag_on: bool = false

var testing_start_camera_zoom: Vector2
var testing_start_camera_position: Vector2
var reset_camera_target: Node2D # ne dela
var mouse_exited_reset_btns: Array = [] # precej bedna začetinška rešitev

onready var parent_camera = get_parent()
onready var trauma_bar = $TestHud/TraumaBar
onready var shake_bar = $TestHud/ShakeBar
onready var shake_btn = $TestHud/ShakeBtn
onready var reset_view_btn = $TestHud/ResetViewBtn
onready var zoom_slider = $TestHud/ZoomSlider
onready var time_slider = $TestHud/TimeSlider
onready var seed_slider = $TestHud/NoiseControl/Seed
onready var octaves_slider = $TestHud/NoiseControl/Octaves
onready var period_slider = $TestHud/NoiseControl/Period
onready var persistence_slider = $TestHud/NoiseControl/Persistence
onready var lacunarity_slider = $TestHud/NoiseControl/Lacunarity



func _ready():

	mouse_exited_reset_btns = [$TestHud/ShakeBtn, $TestHud/ResetViewBtn, $TestHud/ZoomSlider, $TestHud/TimeSlider]
	mouse_exited_reset_btns.append($TestHud/NoiseControl)
	mouse_exited_reset_btns.append_array([$TestHud/NoiseControl/Seed, $TestHud/NoiseControl/Octaves, $TestHud/NoiseControl/Period, $TestHud/NoiseControl/Persistence, $TestHud/NoiseControl/Lacunarity])

	for btn in mouse_exited_reset_btns:
		btn.connect("mouse_exited", self, "_on_interactive_control_mouse_exited")
		btn.connect("mouse_entered", self, "_on_interactive_control_mouse_entered")

	$TestHud.hide()
	$SetupPanel.hide()
	$CameraSetupToggle.set_focus_mode(0)
	$NodeSetupToggle.set_focus_mode(0)

	shake_btn.set_focus_mode(0)
	reset_view_btn.set_focus_mode(0)
	zoom_slider.set_focus_mode(0)
	time_slider.set_focus_mode(0)
	seed_slider.set_focus_mode(0)
	octaves_slider.set_focus_mode(0)
	period_slider.set_focus_mode(0)
	persistence_slider.set_focus_mode(0)
	lacunarity_slider.set_focus_mode(0)

	zoom_slider.value = parent_camera.zoom.x

	# noise setup
	noise.seed = 2
	noise.octaves = 1
	noise.period = 10
	noise.persistence = 0
	noise.lacunarity = 1

	seed_slider.value = noise.seed
	octaves_slider.value = noise.octaves
	period_slider.value = noise.period
	persistence_slider.value = noise.persistence
	lacunarity_slider.value = noise.lacunarity


func _input(event: InputEvent) -> void:

	if test_view_on:
		if Input.is_action_just_pressed("click") and not mouse_used:
			drag_on = true
			mouse_position_on_drag_start = parent_camera.get_global_mouse_position() # definiraj zamik pozicije miške napram centru

		if Input.is_action_just_released("click"):
			drag_on = false

		if Input.is_mouse_button_pressed(BUTTON_WHEEL_UP) and test_view_on:
			parent_camera.zoom -= Vector2(0.1, 0.1)

		if Input.is_mouse_button_pressed(BUTTON_WHEEL_DOWN) and test_view_on:
			parent_camera.zoom += Vector2(0.1, 0.1)

	else:
		drag_on = false


func _process(delta):

	if test_view_on: # _temp ... ker šejk še ne dela

		time += delta
		#	if test_view_on:
		# start decay
		#	var shake = pow(trauma, 2) # narašča s kvadratno funkcijo
		var shake = trauma
		parent_camera.offset.x = noise.get_noise_3d(time * time_scale, 0, 0) * max_horizontal * shake
		parent_camera.offset.y = noise.get_noise_3d(0, time * time_scale, 0) * max_vertical * shake
		parent_camera.rotation_degrees = noise.get_noise_3d(0, 0, time * time_scale) * max_rotation * shake

		# start decay
		if trauma > 0:
			yield(get_tree().create_timer(trauma_time), "timeout")
			trauma = clamp(trauma - (delta * decay), 0, 1)

		# UI
		trauma_bar.value = trauma
		shake_bar.value = shake
		seed_slider.value = noise.seed
		octaves_slider.value = noise.octaves
		period_slider.value = noise.period
		persistence_slider.value = noise.persistence
		lacunarity_slider.value = noise.lacunarity

		# drag
		if drag_on:
			parent_camera.position += mouse_position_on_drag_start - parent_camera.get_global_mouse_position()


func shake_camera(added_trauma):
	trauma = clamp(trauma + added_trauma, 0, 1)



func _on_CheckBox_toggled(button_pressed: bool) -> void:

	$TestHud.visible = button_pressed
	test_view_on = button_pressed


func _on_NodeCheckBox_toggled(button_pressed: bool) -> void:

	$SetupPanel.visible = button_pressed


# SHAKE NOISE ------------------------------------------------------------


func _on_ShakeBtn_pressed() -> void:
	mouse_used = true
	$"../Shaker".shake_camera(add_trauma)

func _on_TimeSlider_value_changed(value: float) -> void:
	Engine.time_scale = value

func _on_ZoomSlider_value_changed(value: float) -> void:
	parent_camera.zoom = Vector2(value, value)

func _on_ResetView_pressed() -> void:
	parent_camera.position = testing_start_camera_position
	parent_camera.zoom = testing_start_camera_zoom

func _on_Seed_value_changed(value: float) -> void:
	noise.seed = value

func _on_Octaves_value_changed(value: float) -> void:
	noise.octaves = value

func _on_Period_value_changed(value: float) -> void:
	noise.period = value

func _on_Persistence_value_changed(value: float) -> void:
	noise.persistence = value

func _on_Lacunarity_value_changed(value: float) -> void:
	noise.lacunarity = value


# UI MOUSE FOKUS ------------------------------------------------------------

func _on_interactive_control_mouse_entered():
	mouse_used = true

func _on_interactive_control_mouse_exited():
	mouse_used = true


#func _on_AddTraumaBtn_mouse_entered() -> void:
#	mouse_used = true
#func _on_AddTraumaBtn_mouse_exited() -> void:
#	mouse_used = false
#
#func _on_ResetView_mouse_entered() -> void:
#	mouse_used = true
#func _on_ResetView_mouse_exited() -> void:
#	mouse_used = false
#
#func _on_ZoomSlider_mouse_entered() -> void:
#	mouse_used = true
#func _on_ZoomSlider_mouse_exited() -> void:
#	mouse_used = false
#
#func _on_TimeSlider_mouse_entered() -> void:
#	mouse_used = true
#func _on_TimeSlider_mouse_exited() -> void:
#	mouse_used = false
#
#func _on_Control_mouse_entered() -> void:
#	mouse_used = true
#func _on_Control_mouse_exited() -> void:
#	mouse_used = false
#
#func _on_Lacunarity_mouse_entered() -> void:
#	mouse_used = true
#func _on_Lacunarity_mouse_exited() -> void:
#	mouse_used = false
#
#func _on_Persistance_mouse_entered() -> void:
#	mouse_used = true
#func _on_Persistance_mouse_exited() -> void:
#	mouse_used = false
#
#func _on_Period_mouse_entered() -> void:
#	mouse_used = true
#func _on_Period_mouse_exited() -> void:
#	mouse_used = false
#
#func _on_Octaves_mouse_entered() -> void:
#	mouse_used = true
#func _on_Octaves_mouse_exited() -> void:
#	mouse_used = false
#
#func _on_SeedSlider_mouse_entered() -> void:
#	mouse_used = true
#func _on_SeedSlider_mouse_exited() -> void:
#	mouse_used = false
#
#func _on_CheckBox_mouse_entered() -> void:
#	mouse_used = true
#func _on_CheckBox_mouse_exited() -> void:
#	mouse_used = false



