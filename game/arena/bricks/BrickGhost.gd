extends StaticBody2D


var def_particle_speed: float = 6

var element_key: int # poda spawner, uravnava vse ostalo

onready var brick_color: Color = Pro.level_elements_profiles[element_key]["color"]
onready var brick_altitude: float = Pro.level_elements_profiles[element_key]["altitude"]
onready var reward_points: float = Pro.level_elements_profiles[element_key]["value"]
onready var speed_brake_div: float = Pro.level_elements_profiles[element_key]["speed_brake_div"]

onready var ai_target_rank: int = Pro.level_elements_profiles[element_key]["ai_target_rank"]

onready var detect_area: Area2D = $DetectArea
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var brick_shadow: Sprite = $BrickShadow


func _ready() -> void:

	modulate = brick_color
	brick_shadow.shadow_distance = brick_altitude
	
	
func _on_DetectArea_body_entered(body: Node) -> void:

	if body.is_in_group(Ref.group_bolts):
		body.velocity /= speed_brake_div
		animation_player.play("outro")
		body.update_bolt_points(reward_points)
		
		
func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	queue_free()
