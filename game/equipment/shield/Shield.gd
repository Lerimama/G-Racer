extends Area2D


var spawner: Node2D # seta se ob spawnu
var shield_loops_counter: int = 0
var shield_loops_limit: int = 3 # poberem jo iz profilov, ali pa kot veleva pickable
var shield_time: float = 10 # spremeni jo lahko spawner

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var shield_collision: CollisionShape2D = $CollisionShape2D
onready var shield_timer: Timer = $ShieldTimer
onready var shield_profile: Dictionary = Pros.equipment_profiles[Pros.EQUIPMENT.SHIELD]


func _ready() -> void:

	animation_player.play("shield_on")
	shield_timer.start(shield_time)


func _process(delta: float) -> void:

	global_position = spawner.global_position


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:

	match anim_name:
		"shield_on":
			animation_player.play("shielding")
			spawner.is_shielded = not spawner.is_shielded
			if not spawner.is_shielded: # pomeni, da je ravnokar končal
				queue_free()


func _on_ShieldTimer_timeout() -> void:

	animation_player.play_backwards("shield_on")

