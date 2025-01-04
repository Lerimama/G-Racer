extends Node2D


enum WEAPON_AMMO {BULLET, MISILE, MINA}
export (WEAPON_AMMO) var ammo_key = 0
export var fx_enabled: bool = true

var is_set: bool =  false
var weapon_reloaded: bool = true
var ammo_count: int = 0 setget _update_weapon_stats # napolnems strani bolta ali igre

onready var shooting_position: Position2D = $WeaponSprite/ShootingPosition
onready var reload_timer: Timer = $ReloadTimer
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var fire_particles: Particles2D = $WeaponSprite/FireParticles
onready var fire_cover_particles: Particles2D = $WeaponSprite/FireCoverParticles
onready var smoke_particles: Particles2D = $WeaponSprite/SmokeParticles

# per weapon
var ammo_count_key: String#  = ammo_profile["ammo_count_key"] # na prvi load
var ammo_profile: Dictionary# = Pros.ammo_profiles[weapon_key] # na prvi load
var AmmoScene: PackedScene# = ammo_profile["scene"]
var reload_time: float = 0.15 # weapon_profile["reload_time"] # PRO dodaj weapons


func _ready() -> void:

	smoke_particles.emitting = false
	fire_particles.emitting = false
	fire_cover_particles.emitting = false


func set_weapon(): # kliče bolt

	ammo_profile = Pros.ammo_profiles[ammo_key]

	reload_time = ammo_profile["reload_time"] # PRO dodaj v nove weapon_profile
	AmmoScene = ammo_profile["scene"]

	# ammo count
	ammo_count_key = ammo_profile["ammo_count_key"]
	ammo_count = owner.player_stats[ammo_count_key]

	is_set = true


func _process(delta: float) -> void:

	if owner.is_shooting and ammo_count > 0 and is_set and owner.bolt_hud.actived_weapon_key == ammo_key:
		shoot()
	else:
		smoke_particles.emitting = false
		fire_particles.emitting = false
		fire_cover_particles.emitting = false
#		animation_player.stop()
#

func shoot():

	if weapon_reloaded:
		if fx_enabled:
			smoke_particles.emitting = true
			fire_particles.emitting = true
			fire_cover_particles.emitting = true
			var current_weapon_animation: String = animation_player.get_animation_list()[1] # 0 je RESET
			animation_player.play(current_weapon_animation)
#			animation_player.play("shooting_motion")

		# spawn
		var new_ammo = AmmoScene.instance()
		new_ammo.global_position = shooting_position.global_position
		new_ammo.global_rotation = shooting_position.global_rotation
		new_ammo.spawner = owner
		new_ammo.spawner_color = owner.bolt_color
		if ammo_key == Pros.AMMO.BULLET:
			new_ammo.z_index = shooting_position.z_index + 1
		else:
			new_ammo.z_index = shooting_position.z_index - 1
		Refs.node_creation_parent.add_child(new_ammo)

		# stats
		self.ammo_count = -1

		# reload
		if reload_time > 0:
			weapon_reloaded = false
			reload_timer.start(reload_time)


func _update_weapon_stats(ammo_count_delta: int):

		ammo_count += ammo_count_delta
		owner.update_stat(ammo_count_key, ammo_count_delta)


func _on_ReloadTimer_timeout() -> void:

	weapon_reloaded = true
