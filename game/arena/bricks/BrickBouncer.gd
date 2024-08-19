extends StaticBody2D


var key_as_name: String = "BRICK_BOUNCER"# poda spawner, uravnava vse ostalo

onready var brick_color: Color = Pro.arena_element_profiles[key_as_name]["color"]
onready var brick_altitude: float = Pro.arena_element_profiles[key_as_name]["altitude"]
onready var reward_points: float = Pro.arena_element_profiles[key_as_name]["value"]
onready var bounce_strenght: float = Pro.arena_element_profiles[key_as_name]["parameter"]

onready var sprite: Sprite = $Sprite
onready var brick_shadow: Sprite = $BrickShadow


func _ready() -> void:

	sprite.modulate = brick_color
	brick_shadow.shadow_distance = brick_altitude
	

func _on_DetectArea_body_entered(body: Node) -> void:

	if body.is_in_group(Ref.group_bolts):
		body.set_process_input(false)
		body.bounce_size = bounce_strenght
		sprite.modulate = Color.white
		# varovalka, da ne obtiči
		yield(get_tree().create_timer(0.2), "timeout")
		body.set_process_input(true)
		
		
func _on_DetectArea_body_exited(body: Node) -> void:

	if body.is_in_group(Ref.group_bolts): 
		# sprite.modulate = bouncer_color
		body.bounce_size = Pro.bolt_profiles[body.bolt_type]["bounce_size"]
		body.set_process_input(true)
		sprite.modulate = brick_color
		body.update_bolt_points(reward_points)
