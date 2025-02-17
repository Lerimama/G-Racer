extends Node2D


signal fx_timing_node_finished
signal fx_finished (self_to_GM)

export (NodePath) var fx_timing_nodepath

var fx_timing_node: Node
var self_destruct: bool = true
var fx_active: bool = false

var fx_intensity: float = 1 setget _change_fx_intensity


func _ready() -> void:

	if fx_timing_nodepath:
		fx_timing_node = get_node(fx_timing_nodepath)
	elif self_destruct: # če je self destruct nujno rabi tajming
		fx_timing_node = get_child(0)

	# timing node pripišem ne glede na self-destruct
	if fx_timing_node:
		match fx_timing_node.get_class():
			"Particles2D", "CPUParticles2D", "AudioStreamPlayer":
				fx_timing_node.connect("finished", self, "_on_fx_timing_node_finished")
			"AnimationPlayer", "AnimatedSprite":
				fx_timing_node.connect("animation_finished", self, "_on_fx_timing_node_finished")


func start_fx(does_self_destruct: bool = true):

	self_destruct = does_self_destruct

	if not fx_active:
		fx_active = true
		for child_fx in get_children():
			match child_fx.get_class():
				"AudioStreamPlayer":
					child_fx.play()
				"Particles2D", "CPUParticles2D":
					child_fx.emitting = true
				"AnimatedSprite", "AnimationPlayer":
					child_fx.play()


func stop_fx():

	if fx_active:
		fx_active = false
		for child_fx in get_children():
			match child_fx.get_class():
				"AudioStreamPlayer", "AnimatedSprite", "AnimationPlayer":
					child_fx.stop()
				"Particles2D", "CPUParticles2D":
					child_fx.emitting = false


func _change_fx_intensity(new_fx_intensity: float = 1): # delež def intensity
	# pred spremembo na samem efektu , izračunam def vrednost in spremenim glede na to

	var prev_intensity: float = fx_intensity
	fx_intensity = new_fx_intensity
	fx_intensity = clamp(fx_intensity, 0, 1)


	for child_fx in get_children():
		match child_fx.get_class():
			"AudioStreamPlayer":
				var volume_to_zero_span: float = child_fx.volume_db + 80
#				var def_volume: float = volume_to_zero_span * prev_intensity
				var new_volume: float = volume_to_zero_span * new_fx_intensity
				child_fx.volume_db = new_volume - 80
#				printt("velume", new_fx_intensity, prev_intensity, "/", new_volume, volume_to_zero_span, "/", child_fx.volume_db)
				if child_fx.volume_db < -79:
					child_fx.volume_db = -80
			"Particles2D", "CPUParticles2D":
				var def_amount: int = child_fx.amount * prev_intensity
				child_fx.amount = def_amount * fx_intensity
			"AnimatedSprite", "AnimationPlayer":
				pass

	# na koncu da lahko prej primerjam z def vrednostmi


func _on_fx_timing_node_finished(): # pošlje na GM

	stop_fx()
	if self_destruct:
		queue_free()
	else:
		emit_signal("fx_finished", self) # pošlje na GM

