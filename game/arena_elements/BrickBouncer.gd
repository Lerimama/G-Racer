extends StaticBody2D


var bouncer_color: Color = Set.color_yellow
var bouncer_bounce_strenght: float = 2

onready var sprite: Sprite = $Sprite
onready var bouncer_points: int = Set.default_game_settings["bouncer_brick_points"]

func _ready() -> void:

	sprite.modulate = bouncer_color


func _on_DetectArea_body_entered(body: Node) -> void:

	if body is Bolt:
		body.bolt_active = false
		body.bounce_size = bouncer_bounce_strenght
		sprite.modulate = Color.white


func _on_DetectArea_body_exited(body: Node) -> void:

	if body is Bolt:
		# sprite.modulate = bouncer_color
		body.bounce_size = Pro.bolt_profiles[body.bolt_type]["bounce_size"]
		body.bolt_active = true
		body.get_points(bouncer_points)
		sprite.modulate = bouncer_color
