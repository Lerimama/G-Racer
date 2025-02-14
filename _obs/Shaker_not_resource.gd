extends Node
#class_name Shaker

export var enable: bool = true
export (Array, NodePath) var shaking_nodes_paths: Array = []

export (Resource) var settings_override_resource # presetan resource ... povozi spodnje nastavitve

export (Texture) var shake_pattern # tekstura za vizualizacijo ma kopijo tega noisa
export (float, 0, 10) var add_trauma: float = 0.5
export var trauma_time: float = 0.1 # decay delay
export(float, 0, 1) var decay_factor: float = 0.5
export var max_horizontal: float = 150
export var max_vertical: float = 150
export var max_rotation: float = 25
export (float, 0, 300, 0.5)var time_scale: float = 150
export var max_trauma: float = 1

var used_noise: OpenSimplexNoise
var is_active: bool = false
var current_trauma: float = 0.5 # current
var time: float = 0
var in_decay: bool = false
var shaking_nodes: Array = []
var one_shaking_node: Node = null

onready var visualizer_layer: CanvasLayer = $VisualizerLayer
onready var texture_button: TextureButton = $VisualizerLayer/VBoxContainer/TextureButton


func _input(event: InputEvent) -> void:

	if is_active:
		if Input.is_action_pressed("ui_accept"):
			shake_camera(add_trauma)


func _ready() -> void:

	if enable:

		if settings_override_resource:
			_override_settings()
			yield(get_tree(), "idle_frame")

		# če ni določene, se uporabi tekstura iz gumba
		if shake_pattern:
			if shake_pattern is NoiseTexture:
				used_noise = shake_pattern.noise
		else:
			if texture_button.texture_normal is NoiseTexture:
				used_noise = texture_button.texture_normal.noise

		# dodam šejkane, če jih ni je šejkan parent
		for path in shaking_nodes_paths:
			shaking_nodes.append(get_node(path))
		if shaking_nodes.empty():
			shaking_nodes.append(get_parent())

		yield(get_tree(), "idle_frame")
		activate()

func _override_settings():

	printt ("used_noise", max_horizontal)
	shake_pattern = settings_override_resource.shake_pattern # tekstura za vizualizacijo ma kopijo tega noisa
	add_trauma = settings_override_resource.add_trauma
	trauma_time = settings_override_resource.trauma_time
	decay_factor = settings_override_resource.decay_factor
	max_trauma = settings_override_resource.max_trauma
	max_horizontal = settings_override_resource.max_horizontal
	max_vertical = settings_override_resource.max_vertical
	max_rotation = settings_override_resource.max_rotation
	time_scale = settings_override_resource.time_scale





func activate():

	texture_button.texture_normal.noise = used_noise
	is_active = true


func _process(delta):

	# shake
	if is_active:

		if one_shaking_node:
			_shake_node(one_shaking_node)
		else:
			for shaking_node in shaking_nodes:
				_shake_node(shaking_node)

		# decay ... ko je trauma, začne štopat do decaya
		if current_trauma == 0:
			time = 0
		elif current_trauma > 0:
			time += delta
			if time > trauma_time:
				current_trauma -= delta * decay_factor
				current_trauma = clamp(current_trauma, 0, max_trauma)

	# display
	if visualizer_layer.visible:
		var labels_holder: Control = $VisualizerLayer/VBoxContainer/VBoxContainer
		labels_holder.get_node("Label").text = "Added trauma: %d" % add_trauma
		labels_holder.get_node("Label_2").text = "Trauma time: %d ... decay delay" % trauma_time
		labels_holder.get_node("Label_3").text = "Decay factor: %d" % decay_factor
		labels_holder.get_node("Label_4").text = "Max hor: %d" % max_horizontal
		labels_holder.get_node("Label_5").text = "Max ver: %d" % max_vertical
		labels_holder.get_node("Label_6").text = "Max rot: %d" % max_rotation
		labels_holder.get_node("Label_7").text = "Time scale: %d" % time_scale
		labels_holder.get_node("Label_8").text = "Current trauma:  %d" % current_trauma



func _shake_node(node_to_shake: Node):

	if "offset" in node_to_shake: # sprite (animated), camera, light, polygon, canvas layer, path follow
		node_to_shake.offset.x = used_noise.get_noise_3d(time * time_scale, 0, 0) * max_horizontal * current_trauma
		node_to_shake.offset.y = used_noise.get_noise_3d(0, time * time_scale, 0) * max_vertical * current_trauma
		node_to_shake.rotation_degrees = used_noise.get_noise_3d(0, 0, time * time_scale) * max_rotation * current_trauma
	elif "position" in node_to_shake: # preostalo kar ima pozicijo
		node_to_shake.position.x += used_noise.get_noise_3d(time * time_scale, 0, 0) * max_horizontal * current_trauma
		node_to_shake.position.y += used_noise.get_noise_3d(0, time * time_scale, 0) * max_vertical * current_trauma
	elif node_to_shake is Control:
		node_to_shake.rect_position.x += used_noise.get_noise_3d(time * time_scale, 0, 0) * max_horizontal * current_trauma
		node_to_shake.rect_position.y += used_noise.get_noise_3d(0, time * time_scale, 0) * max_vertical * current_trauma


func shake_camera(add_trauma_amount: float = add_trauma, the_one_shaking_node: Node = null):
	print("šejkam", add_trauma_amount)
	one_shaking_node = the_one_shaking_node
	current_trauma += add_trauma_amount
	current_trauma = clamp(current_trauma, 0, max_trauma) # ne delaj bolj pregledno ker ne deluje ... ne vem zakaj?
