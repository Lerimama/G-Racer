extends Node2D


signal equipment_used

enum EQUIPMENT_TYPE {GUN, TURRET, LAUNCHER, DROPPER, MALA}
export (EQUIPMENT_TYPE) var equipment_type: int = 0

export var fx_enabled: bool = true
export var ai_enabled: bool = false # spawner lahko povozi

var is_set: bool = false
var equipment_reloaded: bool = true
var equipment_count: int = 0 # napolnems strani agenta ali igre

onready var fx_position: Position2D = $WeaponSprite/ShootingPosition
onready var reload_timer: Timer = $ReloadTimer
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var fire_particles: Particles2D = $WeaponSprite/FireParticles
onready var fire_cover_particles: Particles2D = $WeaponSprite/FireCoverParticles
onready var smoke_particles: Particles2D = $WeaponSprite/SmokeParticles
onready var equipment_ai: RayCast2D = $WeaponAI

# per weapon
var equipment_stat_key: int
var reload_time: float
var equipment_owner: Node2D
var power_usage: float = 0 # še ni implementirano


func _ready() -> void:

	hide()

	#	smoke_particles.emitting = false
	#	fire_particles.emitting = false
	#	fire_cover_particles.emitting = false


func setup(owner_node: Node2D, with_ai: bool = ai_enabled): # kliče agent

## še ne uporabljam kode


	equipment_owner = owner_node

	reload_time = 0 #Pfs.ammo_profiles[weapon_ammo]["reload_time"]
	equipment_stat_key = 0 # Pfs.ammo_profiles[weapon_ammo]["stat_key"]
	equipment_count = equipment_owner.driver_stats[equipment_stat_key]

	# upošteva setano, razen, če je določena od spawnerja
	if with_ai:
		ai_enabled = with_ai
		equipment_ai.setup(equipment_owner)

	show()
	is_set = true


func _process(delta: float) -> void:

	if is_set:
		equipment_count = equipment_owner.driver_stats[equipment_stat_key]

func _on_weapon_triggered():

	if is_set:
		if equipment_count > 0 and equipment_reloaded:
			_use()


func _use():

	if fx_enabled:
		smoke_particles.one_shot = true
		fire_particles.one_shot = true
		smoke_particles.emitting = true
		fire_particles.emitting = true
		fire_cover_particles.one_shot = true
		fire_cover_particles.emitting = true
		var current_weapon_animation: String = animation_player.get_animation_list()[1] # 0 je RESET
		animation_player.play(current_weapon_animation)

	# reload
	if reload_time > 0:
		equipment_reloaded = false
		reload_timer.start(reload_time)

	# odštejem samo v glavnem slovarju, ker se tukaj kopira v procesu
	emit_signal("equipment_used", equipment_stat_key, -1)


func _on_ReloadTimer_timeout() -> void:

	equipment_reloaded = true
