extends Node

onready var breaker_body: RigidBody2D = owner

var force_vector: Vector2


func _ready() -> void:
	pass



func fall():
	breaker_body.gravity_scale = 1

func explode():
	pass
	

	
