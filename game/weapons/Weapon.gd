extends Node2D
class_name Weapon

#signal weapon_shot

enum WEAPON_TYPE {GUN, TURRET, LAUNCHER, DROPPER, MALA}
enum WEAPON_AMMO {BULLET, MISILE, MINA, SMALL, HOMER} # kot v profilih

export (WEAPON_TYPE) var weapon_type: int = 0
export (WEAPON_AMMO) var weapon_ammo: int = 0 # 0 = AMMO.BULLET
export var fx_enabled: bool = true
export var use_ai: bool = false # spawner lahko povozi

var weapon_owner: Node2D
var is_set: bool = false
var weapon_reloaded: bool = true

onready var shooting_position: Position2D = $WeaponSprite/ShootingPosition
onready var reload_timer: Timer = $ReloadTimer
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var fire_particles: Particles2D = $WeaponSprite/FireParticles
onready var fire_cover_particles: Particles2D = $WeaponSprite/FireCoverParticles
onready var smoke_particles: Particles2D = $WeaponSprite/SmokeParticles
onready var weapon_ai: RayCast2D = $WeaponAI


# neu
export (float, 0, 1, 0.1) var power_usage: float = 0 # še ni implementirano
export (float, 0.1)var reload_time: float = 0
export (PackedScene) var Ammo: PackedScene
export var start_load_count: int = 50
export var start_magazines_count: int = 1
# uni vars
export (Texture) var load_icon: Texture = null
var load_count: int = start_load_count  * start_magazines_count # _temp.. ime naj bo univerzalno za item


func _ready() -> void:

	hide()

	smoke_particles.emitting = false
	fire_particles.emitting = false
	fire_cover_particles.emitting = false


func set_weapon(owner_node: Node2D, with_ai: bool = use_ai): # kliče vehil

	weapon_owner = owner_node
	weapon_owner.weapon_stats[self] = load_count # bolje če raje pobere vehicle ob spawnu?

	# upošteva setano, razen, če je določena od spawnerja
	if with_ai:
		use_ai = with_ai
		weapon_ai.set_ai(weapon_owner)

	show()
	is_set = true


func _on_weapon_triggered(): # kliče controller, za prepoznavanje "triggering_weapon"

	if is_set:
		if load_count > 0 and weapon_reloaded:
			_shoot()
			load_count -= 1
			weapon_owner.weapon_stats[self] = load_count


func _shoot():

	if fx_enabled:
		smoke_particles.one_shot = true
		fire_particles.one_shot = true
		smoke_particles.emitting = true
		fire_particles.emitting = true
		fire_cover_particles.one_shot = true
		fire_cover_particles.emitting = true
		var current_weapon_animation: String = animation_player.get_animation_list()[1] # 0 je RESET
		animation_player.play(current_weapon_animation)

	# spawn ammo
	var new_ammo = Ammo.instance()
	new_ammo.global_position = shooting_position.global_position
	new_ammo.global_rotation = shooting_position.global_rotation
	new_ammo.spawner = weapon_owner
	new_ammo.z_index = shooting_position.z_index - 1 # _temp
	Refs.node_creation_parent.add_child(new_ammo)

	# reload
	if reload_time > 0:
		weapon_reloaded = false
		reload_timer.start(reload_time)


func _on_ReloadTimer_timeout() -> void:

	weapon_reloaded = true
