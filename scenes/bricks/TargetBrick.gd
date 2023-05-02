extends StaticBody2D


var target_points = 100

var brick_color_1 = Color.purple
var brick_color_2 = Color.pink
var brick_color_3 = Color.white

var def_particle_speed = 5

onready var explode_particles: Particles2D = $ExplodeParticles
onready var sprite: Sprite = $Sprite
onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:

#	name = "Exploder"
#	add_to_group("exploders")

	sprite.modulate = brick_color_1


func _on_ForceField_body_entered(body: Node) -> void:
	print(body.get_groups())
	
	if body.is_in_group(Config.group_bullets):

		if sprite.modulate == brick_color_1:
			sprite.modulate = brick_color_2
		elif sprite.modulate == brick_color_2:
			sprite.modulate = brick_color_3
		elif sprite.modulate == brick_color_3:
			explode_particles.modulate = brick_color_3
			animation_player.play("outro")


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	queue_free()


func pause_me():
	explode_particles.speed_scale = 0
	animation_player.stop(false)


func unpause_me():
	explode_particles.speed_scale = def_particle_speed
	animation_player.play()

