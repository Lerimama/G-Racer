extends Node2D

#export var krneki: int = 0
#export (Pro.AMMO) var ammo_type = 0

var is_set: bool =  false
var weapon_reloaded: bool = true
var ammo_count: int = 0 setget _update_weapon_stats # napolnems strani bolta ali igre

onready var shooting_position: Position2D = $ShootingPosition
onready var reload_timer: Timer = $ReloadTimer
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var fire_particles: Particles2D = $WeaponSprite/FireParticles
onready var fire_cover_particles: Particles2D = $WeaponSprite/FireCoverParticles
onready var smoke_particles: Particles2D = $SmokeParticles

# per weapon
var ammo_key: int# = Pro.AMMO.BULLET  # na prvi load
var counter_name: String#  = ammo_profile["counter_name"] # na prvi load
var ammo_profile: Dictionary# = Pro.ammo_profiles[weapon_key] # na prvi load
var AmmoScene: PackedScene# = ammo_profile["scene"]
var reload_time: float = 0.15 # weapon_profile["reload_time"] # PRO dodaj weapons


func set_weapon(new_ammo_key: int):
	
	ammo_key = new_ammo_key
	ammo_profile = Pro.ammo_profiles[ammo_key]
	counter_name = ammo_profile["counter_name"]
	AmmoScene = ammo_profile["scene"]
	counter_name = ammo_profile["counter_name"]
	reload_time = ammo_profile["reload_time"] # PRO dodaj weapon_profile
	ammo_count = owner.player_stats[counter_name]
	
	is_set = true


func _process(delta: float) -> void:
	
	var current_active_weapon_key: int = owner.bolt_hud.selected_active_weapon_index
	
	if owner.is_shooting and ammo_count > 0 and is_set and current_active_weapon_key == ammo_key:
		shoot()
#		smoke_particles.emitting = true
#		fire_particles.emitting = true
#		fire_cover_particles.emitting = true
#		animation_player.play("shooting")
	else:
		smoke_particles.emitting = false
		fire_particles.emitting = false
		fire_cover_particles.emitting = false
		animation_player.stop()
		
		
func shoot():
	
	if weapon_reloaded:
		smoke_particles.emitting = true
		fire_particles.emitting = true
		fire_cover_particles.emitting = true
		animation_player.play("shooting")

		# spawn
		var new_ammo = AmmoScene.instance()
		new_ammo.global_position = shooting_position.global_position
		new_ammo.global_rotation = shooting_position.global_rotation
		new_ammo.spawner = owner
		new_ammo.spawner_color = owner.bolt_color
		if ammo_key == Pro.AMMO.BULLET:
			new_ammo.z_index = shooting_position.z_index + 1
		elif ammo_key == Pro.AMMO.MISILE:
			new_ammo.z_index = shooting_position.z_index - 1
		Ref.node_creation_parent.add_child(new_ammo)
		
		# stats
		self.ammo_count = -1
		
		# reload
		if reload_time > 0:
			weapon_reloaded = false
			reload_timer.start(reload_time / owner.reload_ability)

		
func _update_weapon_stats(ammo_count_delta: int):
		
		ammo_count += ammo_count_delta
		owner.update_stat(counter_name, ammo_count_delta)
		
	
func _on_ReloadTimer_timeout() -> void:
	
	weapon_reloaded = true
