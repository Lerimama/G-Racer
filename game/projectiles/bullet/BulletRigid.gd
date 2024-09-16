extends RigidBody2D
#class_name Bullet


export var height: float = 0 # PRO
export var elevation: float = 10 # PRO

var spawned_by: Node
var spawned_by_color: Color
var spawned_by_speed: float
var in_spawned_by_area: bool = true # vision zaznava kdaj ga zapusti, ker če ne collision


var bullet_active: bool = true
var direction: Vector2
var velocity: Vector2
var collision: KinematicCollision2D
var bullet_momentum: float # je zmnožek hitrosti in teže
var collider_momentum: float # je zmnožek hitrosti in teže
var new_bullet_trail: Object

onready var trail_position: Position2D = $TrailPosition
onready var BulletTrail: PackedScene = preload("res://game/projectiles/bullet/BulletTrail.tscn") 
#onready var HitParticles: PackedScene = preload("res://game/projectiles/bullet/BulletHitParticles.tscn")
onready var HitParticles: PackedScene = preload("res://game/projectiles/bullet/BulletHit.tscn")

onready var weapon_profile: Dictionary = Pro.weapon_profiles[Pro.WEAPON.BULLET]
#onready var reload_time: float = weapon_profile["reload_time"]
onready var hit_damage: float = weapon_profile["hit_damage"]
onready var lifetime: float = weapon_profile["lifetime"]
onready var bullet_mass: float = weapon_profile["mass"]
onready var speed: float = 700#weapon_profile["speed"]
onready var vision_ray: RayCast2D = $VisionRay
onready var collision_shape: CollisionShape2D = $BulletCollision


func _ready() -> void:
	
	add_to_group(Ref.group_bullets)
	modulate = spawned_by_color
	$Sounds/BulletShoot.play()
	
	mass = bullet_mass
		
	# set movement vector
	direction = Vector2(cos(rotation), sin(rotation))
	
	# spawn trail
	new_bullet_trail = BulletTrail.instance()
#	new_bullet_trail.gradient.colors[1] = spawned_by_color
	new_bullet_trail.z_index = trail_position.z_index
	Ref.node_creation_parent.add_child(new_bullet_trail)
	
	velocity = direction * speed # velocity is the velocity vector in pixels per second?
	
#	Ref.sound_manager.play_sfx("bullet_shoot")
			
			
func _physics_process(delta: float) -> void:
	
	new_bullet_trail.add_points(trail_position.global_position) # premaknjeno iz process
		
	# preverjam, če se še dotika avtorja
	if vision_ray.is_colliding():
		if vision_ray.get_collider() == spawned_by:
			in_spawned_by_area = true
		else:
			in_spawned_by_area = false
			if vision_ray.get_collider().has_method("on_hit"):
				vision_ray.get_collider().on_hit(self) # pošljem node z vsemi podatki in kolizijo
			destroy_bullet(vision_ray.get_collision_point(), vision_ray.get_collision_normal())
			print(vision_ray.get_collision_point(), vision_ray.get_collision_normal())
#			vision_ray.get_collider().modulate.a = 0.5
	else:
		in_spawned_by_area = true
	
	# collision enable ... tukaj ker drugače collision prehiti vision ray
	if in_spawned_by_area:
		collision_shape.set_deferred("disabled", true)
	else:
		collision_shape.set_deferred("disabled", false)
			

func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	
	set_applied_force(direction * speed)
#	set_applied_force(Vector2.RIGHT.rotated(spawned_by.bolt_global_rotation) * speed)
		
				
func destroy_bullet(collision_position: Vector2, collision_normal: Vector2):	
	
#	vision_ray.get_collider().modulate.a = 1
	
	#func destroy_bullet():	
	#	new_hit_particles.position = collision.position
	#	new_hit_particles.rotation = collision.normal.angle() # rotacija partiklov glede na normalo površine 
	#	...
	#	new_bullet_trail.start_decay(collision.position) # zadnja pika se pripne na mesto kolizije
	#	...
	speed = 0
	
	Ref.sound_manager.play_sfx("bullet_hit")
	
	# hit partikli
	var new_hit_fx = HitParticles.instance()
	new_hit_fx.global_position = collision_position
	new_hit_fx.global_rotation = -collision_normal.angle() # rotacija partiklov glede na normalo površine 
#	new_hit_particles.color = spawned_by_color
	new_hit_fx.get_node("DebryParticles").set_emitting(true) # morem klicat, ker je one šot
	new_hit_fx.get_node("FireParticles").set_emitting(true) # morem klicat, ker je one šot
#	add_child(new_hit_fx)
	Ref.node_creation_parent.add_child(new_hit_fx)
	print("hi", new_hit_fx)
	new_bullet_trail.start_decay(collision_position) # zadnja pika se pripne na mesto kolizije
	queue_free()


func on_out_of_screen():
	var bullet_off_screen_time: float = 2 
	yield(get_tree().create_timer(bullet_off_screen_time), "timeout")
	new_bullet_trail.start_decay(global_position) # zadnja pika se pripne na mesto kolizije
	queue_free()


func _on_Bullet_body_entered(body: Node) -> void: # VEN ne uporabljam 
	
	return 
	
	if body.has_method("on_hit"):
		vision_ray.get_collider().on_hit(self) # pošljem node z vsemi podatki in kolizijo
		destroy_bullet(vision_ray.get_collision_point(), vision_ray.get_collision_normal())

func _exit_tree() -> void:
	print("BUM")
