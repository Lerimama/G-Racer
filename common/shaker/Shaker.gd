extends Node
class_name Shaker

export var enable: bool = true
export (Array, NodePath) var shaking_nodes_paths: Array = []

export (Resource) var shake_profile setget _change_shake_profile# presetan resource ... povozi spodnje nastavitve

var is_enabled: bool = false
var current_trauma: float = 0.5 # current
var time: float = 0
var in_decay: bool = false
var shaking_nodes: Array = []
var one_shaking_node: Node = null

# resource prepiše
var add_trauma: float = 0.5
var trauma_time: float = 0.1 # decay delay
var decay_factor: float = 0.5
var max_horizontal: float = 150
var max_vertical: float = 150
var max_rotation: float = 25
var time_scale: float = 150
var max_trauma: float = 1
var used_noise: OpenSimplexNoise

onready var visualizer_layer: CanvasLayer = $VisualizerLayer
onready var texture_button: TextureButton = $VisualizerLayer/VBoxContainer/TextureButton


#func _input(event: InputEvent) -> void:
#
#	if is_enabled:
#		if Input.is_action_pressed("ui_accept"):
#			shake_it(add_trauma)


func _ready() -> void:

	if enable:

		if shake_profile:
			self.shake_profile = shake_profile
			#			yield(get_tree(), "idle_frame")

		# če ni določene, se uporabi tekstura iz gumba
		if not used_noise:
			used_noise = texture_button.texture_normal.noise
		# debug
		texture_button.texture_normal.noise = used_noise
		# dodam šejkane, če jih ni je šejkan parent
		for path in shaking_nodes_paths:
			shaking_nodes.append(get_node(path))
		if shaking_nodes.empty():
			shaking_nodes.append(get_parent())

		yield(get_tree(), "idle_frame")
		activate()


func activate():

	texture_button.texture_normal.noise = used_noise
	is_enabled = true


func _process(delta):

	# shake
	if is_enabled:

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
		labels_holder.get_node("Label_9").text = "Shake profile:  %s" % str(shake_profile)


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


func shake_it(add_trauma_amount: float = add_trauma, the_one_shaking_node: Node = null):

	one_shaking_node = the_one_shaking_node
	current_trauma += add_trauma_amount
	current_trauma = clamp(current_trauma, 0, max_trauma) # ne delaj bolj pregledno ker ne deluje ... ne vem zakaj?


func _change_shake_profile(new_shake_profile: Resource):

	shake_profile = new_shake_profile

	if shake_profile.noise:
		used_noise = shake_profile.noise

	add_trauma = shake_profile.add_trauma

	max_trauma = shake_profile.max_trauma
	trauma_time = shake_profile.trauma_time
	decay_factor = shake_profile.decay_factor

	max_horizontal = shake_profile.max_horizontal
	max_vertical = shake_profile.max_vertical
	max_rotation = shake_profile.max_rotation

	time_scale = shake_profile.time_scale

	if texture_button:
		texture_button.texture_normal.noise = used_noise
