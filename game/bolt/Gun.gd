extends Sprite


var weapon_reloaded: bool = true

#onready var ProjectileScene: PackedScene = Pro.weapon_profiles[Pro.WEAPON.BULLET]["scene"]

onready var weapon_profile: Dictionary = Pro.weapon_profiles[Pro.WEAPON.BULLET]
onready var ProjectileScene: PackedScene = weapon_profile["scene"]
onready var reload_time: float = 0.2#weapon_profile["reload_time"]

onready var projectile_position: Position2D = $GunPosition
onready var weapon_particles: Particles2D = $GunParticles
onready var reload_timer: Timer = $ReloadTimer


func _ready() -> void:
	pass


func shoot():
	
	if weapon_reloaded:
		var new_projectile = ProjectileScene.instance()
		new_projectile.global_position = projectile_position.global_position
		new_projectile.global_rotation = projectile_position.global_rotation
		new_projectile.spawned_by = owner
		new_projectile.spawned_by_color = owner.bolt_color
		new_projectile.z_index = projectile_position.z_index
		Ref.node_creation_parent.add_child(new_projectile)
		
		weapon_particles.emitting = true
		if reload_time > 0:
			weapon_reloaded = false
			reload_timer.start(reload_time / owner.reload_ability)
		return true
	else:
		return false


func _on_ReloadTimer_timeout() -> void:
	
	weapon_reloaded = true
