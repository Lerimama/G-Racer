extends KinematicBody2D


var speed: float = -32 # regulacija v animaciji
var direction: Vector2
var acceleration: Vector2 = Vector2.ZERO


func _ready() -> void:
	
	add_to_group("Players")
	pass # Replace with function body.
	direction = transform.x # rotacija smeri ob štartu

	print ("Fejkplayer")


func _process(delta: float) -> void:

	position += direction * speed * delta

func on_hit_by_misile():
	pass

func on_hit_by_blast():
#	motion_enabled == false
	modulate = Color.red
	speed = 0
	
