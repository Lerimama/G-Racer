extends StaticBody2D


var level_object_key: int # poda spawner, uravnava vse ostalo

onready var brick_color: Color = Pro.level_object_profiles[level_object_key]["color"]
onready var brick_altitude: float = Pro.level_object_profiles[level_object_key]["altitude"]
onready var reward_points: float = Pro.level_object_profiles[level_object_key]["value"]
onready var bounce_strength: float = Pro.level_object_profiles[level_object_key]["bounce_strength"]

onready var ai_target_rank: int = Pro.level_object_profiles[level_object_key]["ai_target_rank"]

onready var sprite: Sprite = $Sprite
onready var brick_shadow: Sprite = $BrickShadow


func _ready() -> void:

	sprite.modulate = brick_color
	brick_shadow.shadow_distance = brick_altitude
	

func _on_DetectArea_body_entered(body: Node) -> void:

	if body.is_in_group(Ref.group_bolts):
		body.set_process_input(false)
		body.bounce_size = bounce_strength
		sprite.modulate = Color.white
		# varovalka, da ne obtiči
		yield(get_tree().create_timer(0.2), "timeout")
		body.set_process_input(true)
	elif body.is_in_group(Ref.group_thebolts):
		body.modulate = Color.yellow
		
		
func _on_DetectArea_body_exited(body: Node) -> void:

	if body.is_in_group(Ref.group_bolts): 
		# sprite.modulate = bouncer_color
		body.bounce_size = Pro.bolt_profiles[body.bolt_type]["bounce_size"]
		body.set_process_input(true)
		sprite.modulate = brick_color
		body.update_bolt_points(reward_points)
	elif body.is_in_group(Ref.group_thebolts):
		body.modulate = Color.white	
