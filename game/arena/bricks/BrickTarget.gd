extends StaticBody2D


var hit_count: int = 0
var def_particle_speed = 5

var level_object_key: int # poda spawner, uravnava vse ostalo

onready var brick_color: Color = Pro.level_object_profiles[level_object_key]["color"]
onready var brick_altitude: float = Pro.level_object_profiles[level_object_key]["altitude"]
onready var reward_points: float = Pro.level_object_profiles[level_object_key]["value"]

onready var ai_target_rank: int = Pro.level_object_profiles[level_object_key]["ai_target_rank"]

onready var explode_particles: Particles2D = $ExplodeParticles
onready var sprite: Sprite = $Sprite
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var brick_shadow: Sprite = $BrickShadow


func _ready() -> void:

	sprite.modulate = brick_color
	brick_shadow.shadow_distance = brick_altitude
	

func on_hit(hit_by: Node):
	
	if hit_by is Bullet:
		hit_count += 1
		match hit_count:
			1:
				sprite.modulate = Ref.color_brick_target_hit_1
			2:
				sprite.modulate = Ref.color_brick_target_hit_2
			3:
				animation_player.play("outro")
				modulate = Ref.color_brick_target_hit_3
				hit_by.spawned_by.update_bolt_points(reward_points)
	elif hit_by is Misile:
		modulate = Ref.color_red
		animation_player.play("outro")
		hit_by.spawned_by.update_bolt_points(reward_points)


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	queue_free()


func pause_me():
	explode_particles.speed_scale = 0
	animation_player.stop(false)


func unpause_me():
	explode_particles.speed_scale = def_particle_speed
	animation_player.play()

