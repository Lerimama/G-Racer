extends StaticBody2D


export var height: float = 40 # PRO
export var elevation: float = 20 # PRO

var def_particle_speed: float = 6
var level_object_key: int # poda spawner, uravnava vse ostalo

onready var brick_color: Color = Pros.level_object_profiles[level_object_key]["color"]
#onready var elevation: float = Pros.level_object_profiles[level_object_key]["elevation"]
onready var reward_points: float = Pros.level_object_profiles[level_object_key]["value"]
onready var speed_brake_div: float = Pros.level_object_profiles[level_object_key]["speed_brake_div"]


onready var detect_area: Area2D = $DetectArea
onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:

	modulate = brick_color


func _on_DetectArea_body_entered(body: Node) -> void:

	if body.is_in_group(Refs.group_drivers):
		animation_player.play("outro")
		body.update_stat(Pros.STAT.POINTS, reward_points)
		#		print("ghost - manipulate eng power")
#		body.manipulate_engine_power(0, 0.5)


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	queue_free()
