extends StaticBody2D


export var height: float = 40 # PRO
export var elevation: float = 20 # PRO

var magnet_color_on: Color = Refs.color_brick_magnet_on # opredeli se v animaciji
var magnet_on: bool
var def_particle_speed: float = 0.5
var time: float = 0
var off_time: float = 2
var on_time: float = 2
var level_object_key: int # poda spawner, uravnava vse ostalo

#onready var elevation: float = Pros.level_object_profiles[level_object_key]["elevation"]
onready var reward_points: float = Pros.level_object_profiles[level_object_key]["value"]
onready var target_rank: int = Pros.level_object_profiles[level_object_key]["target_rank"]
onready var magnet_color_off: Color = Pros.level_object_profiles[level_object_key]["color"]
onready var magnet_gravity_force: float = Pros.level_object_profiles[level_object_key]["gravity_force"]
onready var forcefield: Area2D = $ForceField
onready var forcefield_collision: CollisionShape2D = $ForceField/CollisionShape2D
onready var sprite: Sprite = $Sprite
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var magnet_timer: Timer = $MagnetTimer


func _ready() -> void:

	sprite.modulate = magnet_color_off
	forcefield.gravity = magnet_gravity_force
	activate_magnet()


func activate_magnet():

		#		animation_player.play("intro")
		var tween_time: float = 0.5
		var magnet_on_tween = get_tree().create_tween()#.set_ease(Tween.EASE_IN).set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
		magnet_on_tween.tween_property(self, "modulate", magnet_color_on, tween_time)
		#		magnet_on_tween.tween_property(self, "modulate:a", 1, intro_time)
		yield(magnet_on_tween, "finished")
		forcefield_collision.set_deferred("disabled", false)
		#		forcefield_collision.disabled = false
		magnet_timer.start(on_time)


func deactivate_magnet():

		#		animation_player.play("outro")
		#		forcefield_collision.disabled = true
		forcefield_collision.set_deferred("disabled", true)
		var tween_time: float = 0.5
		var magnet_off_tween = get_tree().create_tween()#.set_ease(Tween.EASE_IN).set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
		magnet_off_tween.tween_property(self, "modulate", magnet_color_off, tween_time)
		#		magnet_off_tween.tween_property(self, "modulate:a", 0.4, intro_time)
		yield(magnet_off_tween, "finished")
		magnet_timer.start(on_time)


func pause_me():

	#	animation_player.stop(false)
	set_physics_process(false)


func unpause_me():

	#	animation_player.play()
	set_physics_process(true)



func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:

	match anim_name:
		"intro":
			pass


func _on_MagnetTimer_timeout() -> void:

	if forcefield_collision.disabled:
		activate_magnet()
	else:
		deactivate_magnet()
