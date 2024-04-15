extends StaticBody2D


var bouncer_color: Color = Set.color_brick_bouncer
var bouncer_bounce_strenght: float = 2
var brick_altitude: float = 5

onready var sprite: Sprite = $Sprite
onready var brick_shadow: Sprite = $BrickShadow


func _ready() -> void:

	sprite.modulate = bouncer_color
	brick_shadow.shadow_distance = brick_altitude
	

func _on_DetectArea_body_entered(body: Node) -> void:

	if body.is_in_group(Ref.group_bolts):
		body.set_process_input(false)
		body.bounce_size = bouncer_bounce_strenght
		sprite.modulate = Color.white
		# varovalka, da ne obtiči
		yield(get_tree().create_timer(0.2), "timeout")
		body.set_process_input(true)
		
		
func _on_DetectArea_body_exited(body: Node) -> void:

	if body.is_in_group(Ref.group_bolts): 
		# sprite.modulate = bouncer_color
		body.bounce_size = Pro.bolt_profiles[body.bolt_type]["bounce_size"]
		body.set_process_input(true)
		sprite.modulate = bouncer_color
		# points
		var points_reward: float = Ref.game_manager.game_settings["bouncer_brick_points"]
		body.points = points_reward # setget
#		body.score_points(points_reward)
