extends StaticBody2D


var ghost_score = 100
var ghost_color = Color.aquamarine
var ghost_brake = 3

var def_particle_speed: float = 6

onready var detect_area: Area2D = $DetectArea
onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:

#	name = "Pointer"
#	add_to_group("pointers")

	modulate = ghost_color


func _on_DetectArea_body_entered(body: Node) -> void:

	if body.is_in_group (Config.group_bolts):

		body.velocity /= ghost_brake
		animation_player.play("outro")


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	queue_free()
