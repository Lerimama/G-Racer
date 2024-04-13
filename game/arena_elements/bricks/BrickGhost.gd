extends StaticBody2D


var ghost_color = Set.color_red
var ghost_brake = 10
var brick_altitude: float = 5
var def_particle_speed: float = 6

onready var detect_area: Area2D = $DetectArea
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var brick_shadow: Sprite = $BrickShadow


func _ready() -> void:

	modulate = ghost_color
	brick_shadow.shadow_distance = brick_altitude
	
	
func _on_DetectArea_body_entered(body: Node) -> void:

	if body.is_in_group(Ref.group_bolts):
		body.velocity /= ghost_brake
		animation_player.play("outro")
		# points
		var points_reward: float = Ref.game_manager.game_settings["ghost_brick_points"]
		body.points = points_reward # setget
#		body.score_points(points_reward)
		
		
func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	queue_free()
