extends StaticBody2D


var bouncer_color: Color = Color.violet
var bouncer_strenght: float = 2
var default_bounce_size: float

onready var sprite: Sprite = $Sprite


func _ready() -> void:

#	name = "Bouncer"
#	add_to_group("bouncers")

	sprite.modulate = bouncer_color


func _on_DetectArea_body_entered(body: Node) -> void:

	if body.is_in_group (Config.group_bolts):
		body.control_enabled = false
		sprite.modulate = Color.white
		default_bounce_size = body.bounce_size
		body.bounce_size = bouncer_strenght


func _on_DetectArea_body_exited(body: Node) -> void:

	if body.is_in_group (Config.group_bolts):
		sprite.modulate = bouncer_color
		body.bounce_size = default_bounce_size
		body.control_enabled = true
