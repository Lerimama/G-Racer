extends Node2D


var tag_owner: Node

var hor_offset: float = 0
var ver_offset: float = 0

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var label: Label = $Tag/Label


func _ready() -> void:

	modulate.a = 1
	animation_player.play("float_lap")
	# KVEFRI je v animaciji


func _physics_process(delta: float) -> void:
	
	if tag_owner:
		global_position = tag_owner.global_position
