extends Node2D


signal fx_timing_node_finished
signal fx_finished (self_to_GM)

export (NodePath) var fx_timing_nodepath

var fx_timing_node: Node
var self_destruct: bool = true


func _ready() -> void:

	if fx_timing_nodepath:
		fx_timing_node = get_node(fx_timing_nodepath)
	elif get_child_count() > 0:
		fx_timing_node = get_child(0)

	if fx_timing_node:
		match fx_timing_node.get_class():
			"Particles2D", "CPUParticles2D", "AudioStreamPlayer":
				fx_timing_node.connect("finished", self, "_on_fx_timing_node_finished")
			"AnimationPlayer", "AnimatedSprite":
				fx_timing_node.connect("animation_finished", self, "_on_fx_timing_node_finished")


func start(does_self_destruct: bool = true):

	self_destruct = does_self_destruct

	for child_fx in get_children():
		match child_fx.get_class():
			"AudioStreamPlayer":
				child_fx.play()
			"Particles2D", "CPUParticles2D":
				child_fx.emitting = true
			"AnimatedSprite", "AnimationPlayer":
				child_fx.play()


func _on_fx_timing_node_finished(): # pošlje na GM

	emit_signal("fx_finished", self) # pošlje na GM

	if self_destruct:
		queue_free()
