extends StaticBody2D


export var height: float = 40 # PRO
export var elevation: float = 20 # PRO

var hit_count: int = 0
var def_particle_speed = 5
var level_object_key: int # poda spawner, uravnava vse ostalo

onready var brick_color: Color = Pros.level_object_profiles[level_object_key]["color"]
#onready var elevation: float = Pros.level_object_profiles[level_object_key]["elevation"]
onready var reward_points: float = Pros.level_object_profiles[level_object_key]["value"]
onready var ai_target_rank: int = Pros.level_object_profiles[level_object_key]["ai_target_rank"]
onready var explode_particles: Particles2D = $ExplodeParticles
onready var sprite: Sprite = $Sprite
onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:

	sprite.modulate = brick_color


func on_hit(hit_by: Node, hit_global_position: Vector2):

	if hit_by is Bullet:
		hit_count += 1
		match hit_count:
			1:
				sprite.modulate = Refs.color_brick_target_hit_1
			2:
				sprite.modulate = Refs.color_brick_target_hit_2
			3:
				animation_player.play("outro")
				modulate = Refs.color_brick_target_hit_3
				hit_by.spawner.update_bolt_points(reward_points)
	elif hit_by is Misile:
		modulate = Refs.color_red
		animation_player.play("outro")
		hit_by.spawner.update_bolt_points(reward_points)


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	queue_free()


func pause_me():
	explode_particles.speed_scale = 0
	animation_player.stop(false)


func unpause_me():
	explode_particles.speed_scale = def_particle_speed
	animation_player.play()
