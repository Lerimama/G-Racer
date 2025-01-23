extends Node2D


enum WEAPON_AMMO {BULLET, MISILE, MINA} # zaporedje kot v profilih
export (WEAPON_AMMO) var weapon_ammo = 0 # 0 = AMMO.BULLET
export var fx_enabled: bool = true

var weapon_is_set: bool =  false
var weapon_reloaded: bool = true
var ammo_count: int = 0 setget _change_ammo_count # napolnems strani bolta ali igre

onready var shooting_position: Position2D = $WeaponSprite/ShootingPosition
onready var reload_timer: Timer = $ReloadTimer
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var fire_particles: Particles2D = $WeaponSprite/FireParticles
onready var fire_cover_particles: Particles2D = $WeaponSprite/FireCoverParticles
onready var smoke_particles: Particles2D = $WeaponSprite/SmokeParticles

# per weapon
var ammo_stat_key: int
var ammo_profile: Dictionary
var AmmoScene: PackedScene
var reload_time: float


func _ready() -> void:

	smoke_particles.emitting = false
	fire_particles.emitting = false
	fire_cover_particles.emitting = false


func set_weapon(): # kliče bolt

	ammo_profile = Pfs.ammo_profiles[weapon_ammo]

	reload_time = ammo_profile["reload_time"]
	AmmoScene = ammo_profile["scene"]
	ammo_stat_key = ammo_profile["stat_key"]
	# ammo count stat
	ammo_count = owner.driver_stats[ammo_stat_key]
	weapon_is_set = true


func _process(delta: float) -> void:

	var shooting_ready: bool = false
	if owner.is_shooting:
		if weapon_is_set and owner.bolt_hud.selected_feature_index == weapon_ammo:
			if ammo_count > 0 and weapon_reloaded:
				shooting_ready = true

	if shooting_ready:
		shoot()
	else:
		smoke_particles.emitting = false
		fire_particles.emitting = false
		fire_cover_particles.emitting = false
#		animation_player.stop()


func shoot():

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
	if weapon_ammo == Pfs.AMMO.BULLET:
		new_ammo.z_index = shooting_position.z_index + 1
	else:
		new_ammo.z_index = shooting_position.z_index - 1
	Rfs.node_creation_parent.add_child(new_ammo)

	# stats
	self.ammo_count = -1

	# reload
	if reload_time > 0:
		weapon_reloaded = false
		reload_timer.start(reload_time)


func _change_ammo_count(ammo_count_delta: int):

		ammo_count += ammo_count_delta
		owner.update_stat(ammo_stat_key, ammo_count_delta)


func _on_ReloadTimer_timeout() -> void:

	weapon_reloaded = true
