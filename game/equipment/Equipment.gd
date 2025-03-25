extends Node2D
class_name Equipment

signal equipment_used

enum EQUIPMENT_TYPE {GUN, TURRET, LAUNCHER, DROPPER, MALA}
export (EQUIPMENT_TYPE) var equipment_type: int = 0

export var fx_enabled: bool = true
export var ai_enabled: bool = false # spawner lahko povozi

var is_set: bool = false
var equipment_reloaded: bool = true
var equipment_count: int = 0 # napolnems strani vehila ali igre

onready var fx_position: Position2D = $WeaponSprite/ShootingPosition
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var fire_particles: Particles2D = $WeaponSprite/FireParticles
onready var fire_cover_particles: Particles2D = $WeaponSprite/FireCoverParticles
onready var smoke_particles: Particles2D = $WeaponSprite/SmokeParticles
onready var equipment_ai: RayCast2D = $WeaponAI

# per weapon
var equipment_stat_key: int
var equipment_owner: Node2D
var power_usage: float = 0 # še ni implementirano


func _ready() -> void:

	hide()

	#	smoke_particles.emitting = false
	#	fire_particles.emitting = false
	#	fire_cover_particles.emitting = false

