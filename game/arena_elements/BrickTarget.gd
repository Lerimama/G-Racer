extends StaticBody2D


var target_points = 100

var hit_count: int = 0
var brick_color_1: Color = Set.color_blue
var brick_color_2: Color = Color.cyan
var brick_color_3: Color = Color.greenyellow

var def_particle_speed = 5

onready var explode_particles: Particles2D = $ExplodeParticles
onready var sprite: Sprite = $Sprite
onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:

	sprite.modulate = brick_color_1


func on_hit(hit_by: Node):
	
	if hit_by is Bullet:
		hit_count += 1
		match hit_count:
			1:
				sprite.modulate = Set.color_green
			2:
				sprite.modulate = Set.color_red
			3:
				animation_player.play("outro")
				modulate = Set.color_gray0
	elif hit_by is Misile:
		modulate = Set.color_red
		animation_player.play("outro")
	

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	queue_free()


func pause_me():
	explode_particles.speed_scale = 0
	animation_player.stop(false)


func unpause_me():
	explode_particles.speed_scale = def_particle_speed
	animation_player.play()

