extends StaticBody2D


var ghost_color = Set.color_green
var ghost_brake = 10

var def_particle_speed: float = 6

onready var detect_area: Area2D = $DetectArea
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var ghost_points: int = Set.default_game_settings["ghost_brick_points"]

func _ready() -> void:

	modulate = ghost_color


func _on_DetectArea_body_entered(body: Node) -> void:

	if body is Bolt:
		body.velocity /= ghost_brake
		animation_player.play("outro")


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	queue_free()
