extends Node2D


enum Weapon {BUL, MIS, MIN} # isto zaporedje kot profili
export (Weapon) var weapon_type: int = Weapon.BUL # RFK ewapon enum v orožju
#export (Pro.WEAPON) var weapon_type_c: int = Pro.WEAPON.BULLET
#var weapon_type: int = 0

var weapon_reloaded: bool = true
var projectile_count: int = 0 setget _update_weapon_stats # napolnems strani bolta ali igre

onready var weapon_profile: Dictionary = Pro.weapon_profiles[weapon_type]
onready var ProjectileScene: PackedScene = weapon_profile["scene"]
onready var reload_time: float = 0.1 #weapon_profile["reload_time"]
onready var counter_name: String = weapon_profile["counter_name"]

onready var projectile_position: Position2D = $GunPosition
#onready var weapon_particles: Particles2D = $GunParticles
onready var reload_timer: Timer = $ReloadTimer
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var weapon_particles: Particles2D = $SpriteTurret/GunParticles
onready var weapon_cover_particles: Particles2D = $SpriteTurret/GunCoverParticles
onready var smoke_particles: Particles2D = $SmokeParticles


func _process(delta: float) -> void:
	
	if owner.is_shooting and projectile_count > 0:
		shoot()
		
		smoke_particles.emitting = true
		weapon_particles.emitting = true
		weapon_cover_particles.emitting = true
		animation_player.play("shooting")
	else:
		smoke_particles.emitting = false
		weapon_particles.emitting = false
		weapon_cover_particles.emitting = false
		animation_player.stop()
		
		
func shoot():
	
	if weapon_reloaded:
		
		# spawn
		var new_projectile = ProjectileScene.instance()
		new_projectile.global_position = projectile_position.global_position
		new_projectile.global_rotation = projectile_position.global_rotation
		new_projectile.spawned_by = owner
		new_projectile.spawned_by_color = owner.bolt_color
		new_projectile.z_index = projectile_position.z_index + 1
		Ref.node_creation_parent.add_child(new_projectile)
		
		# stats
		self.projectile_count = -1
		
		# reload
		if reload_time > 0:
			weapon_reloaded = false
			reload_timer.start(reload_time / owner.reload_ability)

		
func _update_weapon_stats(projectile_count_delta: int):
		
		projectile_count += projectile_count_delta
		owner.update_stat(counter_name, projectile_count_delta)
		
	
func _on_ReloadTimer_timeout() -> void:
	
	weapon_reloaded = true
