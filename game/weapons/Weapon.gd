extends Node2D
class_name Weapon

signal weapon_shot

enum WEAPON_TYPE {GUN, TURRET, LAUNCHER, DROPPER, MALA}
enum WEAPON_AMMO {BULLET, MISILE, MINA, SMALL} # kot v profilih

export (WEAPON_TYPE) var weapon_type: int = 0
export (WEAPON_AMMO) var weapon_ammo: int = 0 # 0 = AMMO.BULLET
export var fx_enabled: bool = true
export var ai_enabled: bool = false # spawner lahko povozi

var is_set: bool = false
var weapon_reloaded: bool = true
var ammo_count: int = 0 # napolnems strani vehila ali igre

onready var shooting_position: Position2D = $WeaponSprite/ShootingPosition
onready var reload_timer: Timer = $ReloadTimer
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var fire_particles: Particles2D = $WeaponSprite/FireParticles
onready var fire_cover_particles: Particles2D = $WeaponSprite/FireCoverParticles
onready var smoke_particles: Particles2D = $WeaponSprite/SmokeParticles
onready var weapon_ai: RayCast2D = $WeaponAI

# per weapon
var ammo_stat_key: int
var AmmoScene: PackedScene
var reload_time: float
var weapon_owner: Node2D
var power_usage: float = 0 # še ni implementirano


func _ready() -> void:

	hide()

	smoke_particles.emitting = false
	fire_particles.emitting = false
	fire_cover_particles.emitting = false


func set_weapon(owner_node: Node2D, with_ai: bool = ai_enabled): # kliče vehil

	weapon_owner = owner_node

	reload_time = Pfs.ammo_profiles[weapon_ammo]["reload_time"]
	AmmoScene = Pfs.ammo_profiles[weapon_ammo]["scene"]
	ammo_stat_key = Pfs.ammo_profiles[weapon_ammo]["stat_key"]
	ammo_count = weapon_owner.driver_stats[ammo_stat_key]

	# upošteva setano, razen, če je določena od spawnerja
	if with_ai:
		ai_enabled = with_ai
		weapon_ai.set_ai(weapon_owner)

	show()
	is_set = true


func _process(delta: float) -> void:

	if is_set:
		ammo_count = weapon_owner.driver_stats[ammo_stat_key]


func _on_weapon_triggered():

	if is_set:
		if ammo_count > 0 and weapon_reloaded:
			_shoot()


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
	var new_ammo = AmmoScene.instance()
	new_ammo.global_position = shooting_position.global_position
	new_ammo.global_rotation = shooting_position.global_rotation
	new_ammo.spawner = weapon_owner
	if weapon_ammo == Pfs.AMMO.BULLET:
		new_ammo.z_index = shooting_position.z_index + 1
	else:
		new_ammo.z_index = shooting_position.z_index - 1
	Rfs.node_creation_parent.add_child(new_ammo)

	# reload
	if reload_time > 0:
		weapon_reloaded = false
		reload_timer.start(reload_time)

	# odštejem samo v glavnem slovarju, ker se tukaj kopira v procesu
	emit_signal("weapon_shot", ammo_stat_key, -1)


func _on_ReloadTimer_timeout() -> void:

	weapon_reloaded = true
