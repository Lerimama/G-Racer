extends StaticBody2D


var def_particle_speed: float = 6

var key_as_name: String # poda spawner, uravnava vse ostalo

onready var brick_color: Color = Pro.arena_element_profiles[key_as_name]["color"]
onready var brick_altitude: float = Pro.arena_element_profiles[key_as_name]["altitude"]
onready var reward_points: float = Pro.arena_element_profiles[key_as_name]["value"]
onready var ghost_brake: float = Pro.arena_element_profiles[key_as_name]["parameter"]

onready var detect_area: Area2D = $DetectArea
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var brick_shadow: Sprite = $BrickShadow


func _ready() -> void:

	modulate = brick_color
	brick_shadow.shadow_distance = brick_altitude
	
	
func _on_DetectArea_body_entered(body: Node) -> void:

	if body.is_in_group(Ref.group_bolts):
		body.velocity /= ghost_brake
		animation_player.play("outro")
		body.update_bolt_points(reward_points)
		
		
func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	queue_free()
