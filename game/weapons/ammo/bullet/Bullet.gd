extends RigidBody2D
class_name Bullet


export var height: float = 0
export var elevation: float = 5 # elevation se doda elevationu objektu spawnanja

var spawner: Node
var spawner_color: Color
var spawner_speed: float
var in_spawner_area: bool = true # vision zaznava kdaj ga zapusti, ker če ne collision

var bullet_active: bool = true
var direction: Vector2
var velocity: Vector2
var collision: KinematicCollision2D
var bullet_momentum: float # je zmnožek hitrosti in teže
var collider_momentum: float # je zmnožek hitrosti in teže
var new_bullet_trail: Object

onready var trail_position: Position2D = $TrailPosition
onready var BulletTrail: PackedScene = preload("res://game/weapons/ammo/bullet/BulletTrail.tscn")
onready var BulletHit: PackedScene = preload("res://game/weapons/ammo/bullet/BulletHit.tscn")

onready var ammo_profile: Dictionary = Pfs.ammo_profiles[Pfs.AMMO.BULLET]
onready var hit_damage: float = ammo_profile["hit_damage"]
onready var lifetime: float = ammo_profile["lifetime"]
onready var bullet_mass: float = ammo_profile["mass"]
onready var speed: float = ammo_profile["speed"]
onready var vision_ray: RayCast2D = $VisionRay
onready var collision_shape: CollisionShape2D = $BulletCollision
onready var influence_area: Area2D = $InfluenceArea # poligon za brejker detect

# neu
enum DAMAGE_TYPE {KNIFE, HAMMER, PAINT, EXPLODING} # enako kot breaker
var damage_type = DAMAGE_TYPE.EXPLODING


func _ready() -> void:

	add_to_group(Rfs.group_bullets)
#	modulate = spawner_color
	$Sounds/BulletShoot.play()

	mass = bullet_mass
	elevation = spawner.elevation + elevation
	# set movement vector
	direction = Vector2.RIGHT.rotated(rotation)

	# spawn trail
	new_bullet_trail = BulletTrail.instance()
	new_bullet_trail.z_index = trail_position.z_index + 1
	Rfs.node_creation_parent.add_child(new_bullet_trail)


func _physics_process(delta: float) -> void:

	new_bullet_trail.add_points(trail_position.global_position) # premaknjeno iz process

	# preverjam, če se še dotika avtorja
	if vision_ray.is_colliding():
		if vision_ray.get_collider() == spawner:
			in_spawner_area = true
		else:
			in_spawner_area = false
			if vision_ray.get_collider().has_method("on_hit"):
				vision_ray.get_collider().on_hit(self, vision_ray.get_collision_point()) # pošljem node z vsemi podatki in kolizijo

			call_deferred("explode_bullet", vision_ray.get_collision_point(), vision_ray.get_collision_normal())
#			explode_bullet(vision_ray.get_collision_point(), vision_ray.get_collision_normal())
	else:
		in_spawner_area = true

	# collision enable ... tukaj ker drugače collision prehiti vision ray
	if in_spawner_area:
		collision_shape.set_deferred("disabled", true)
	else:
		collision_shape.set_deferred("disabled", false)


func _integrate_forces(state: Physics2DDirectBodyState) -> void:

	speed = 320 # _
	set_applied_force(direction * speed)


func explode_bullet(collision_position: Vector2, collision_normal: Vector2):

	$Sounds/BulletHit.play()

	speed = 0

	# hit partikli
	var new_hit_fx = BulletHit.instance()
	new_hit_fx.global_position = collision_position
	new_hit_fx.global_rotation = deg2rad(180) + collision_normal.angle() # 180 dodatek omogča, da ni na vertikalah naroben kot
	new_hit_fx.get_node("DebryParticles").set_emitting(true) # morem klicat, ker je one šot
	new_hit_fx.get_node("FireParticles").set_emitting(true)
	Rfs.node_creation_parent.add_child(new_hit_fx)
	new_bullet_trail.start_decay(collision_position) # zadnja pika se pripne na mesto kolizije
	queue_free()


func on_out_of_playing_field():

	var bullet_off_screen_time: float = 2
#	yield(get_tree().create_timer(bullet_off_screen_time), "timeout")
	new_bullet_trail.start_decay(global_position) # zadnja pika se pripne na mesto kolizije
	queue_free()


func _exit_tree() -> void:

	if new_bullet_trail and not new_bullet_trail.in_decay:
		new_bullet_trail.start_decay(new_bullet_trail.global_position) # zadnja pika se pripne na mesto kolizije
