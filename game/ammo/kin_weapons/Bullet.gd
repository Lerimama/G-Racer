extends KinematicBody2D
#class_name Bullet


export var height: float = 0 # PRO
export var elevation: float = 10 # PRO

var spawner: Node
var spawner_color: Color
var spawner_speed: float
var in_spawner_area: bool = true # vision zaznava kdaj ga zapusti


var bullet_active: bool = true
var direction: Vector2
var velocity: Vector2
var collision: KinematicCollision2D
var bullet_momentum: float # je zmnožek hitrosti in teže
var collider_momentum: float # je zmnožek hitrosti in teže
var new_bullet_trail: Object

onready var trail_position: Position2D = $TrailPosition
onready var BulletTrail: PackedScene = preload("res://game/ammo/bullet/BulletTrail.tscn") 
#onready var HitParticles: PackedScene = preload("res://game/ammo/bullet/BulletHitParticles.tscn")
onready var HitParticles: PackedScene = preload("res://game/ammo/bullet/BulletHit.tscn")

onready var weapon_profile: Dictionary = Pro.ammo_profiles[Pro.AMMO.BULLET]
#onready var reload_time: float = weapon_profile["reload_time"]
onready var hit_damage: float = weapon_profile["hit_damage"]
onready var lifetime: float = weapon_profile["lifetime"]
onready var mass: float = weapon_profile["mass"]
onready var speed: float = 700#weapon_profile["speed"]
onready var vision_ray: RayCast2D = $VisionRay
onready var collision_shape: CollisionShape2D = $BulletCollision


func _ready() -> void:
	
	add_to_group(Ref.group_bullets)
	modulate = spawner_color
	$Sounds/BulletShoot.play()
		
	# set movement vector
	direction = Vector2(cos(rotation), sin(rotation))
	
	# spawn trail
	new_bullet_trail = BulletTrail.instance()
#	new_bullet_trail.gradient.colors[1] = spawner_color
	new_bullet_trail.z_index = trail_position.z_index
	Ref.node_creation_parent.add_child(new_bullet_trail)
	
	velocity = direction * speed # velocity is the velocity vector in pixels per second?
	
#	Ref.sound_manager.play_sfx("bullet_shoot")
			
			
func _physics_process(delta: float) -> void:
	
	new_bullet_trail.add_points(trail_position.global_position) # premaknjeno iz process
		
	# preverjam, če se še dotika avtorja
	if vision_ray.is_colliding():
		var current_collider = vision_ray.get_collider()
		if current_collider == spawner:
			in_spawner_area = true
		else:
			in_spawner_area = false
	if in_spawner_area:
		collision_shape.set_deferred("disabled", true)
	else:
		collision_shape.set_deferred("disabled", false)
		
	# preverjamo obstoj kolizije ... prvi kontakt, da odstranimo morebitne erorje v debuggerju
	collision = move_and_collide(velocity * delta, false)
	if collision:
		if collision.collider != spawner: # sam sebe lahko ubiješ
			if collision.collider.has_method("on_hit"):
				collision.collider.on_hit(self) # pošljem node z vsemi podatki in kolizijo
			var vision_current_collider = vision_ray.get_collider()
			destroy_bullet(vision_ray.get_collision_point(), vision_ray.get_collision_normal())
			velocity = Vector2.ZERO

			
func destroy_bullet(collision_position: Vector2, collision_normal: Vector2):	
	
	#func destroy_bullet():	
	#	new_hit_particles.position = collision.position
	#	new_hit_particles.rotation = collision.normal.angle() # rotacija partiklov glede na normalo površine 
	#	...
	#	new_bullet_trail.start_decay(collision.position) # zadnja pika se pripne na mesto kolizije
	#	...
	
	Ref.sound_manager.play_sfx("bullet_hit")
	
	# hit partikli
	var new_hit_fx = HitParticles.instance()
	new_hit_fx.position = collision_position
	new_hit_fx.rotation = collision_normal.angle() # rotacija partiklov glede na normalo površine 
#	new_hit_particles.color = spawner_color
#	new_hit_particles.set_emitting(true)
	Ref.node_creation_parent.add_child(new_hit_fx)
	new_bullet_trail.start_decay(collision_position) # zadnja pika se pripne na mesto kolizije
	queue_free()


func on_out_of_playing_field():
	var bullet_off_screen_time: float = 2 
	yield(get_tree().create_timer(bullet_off_screen_time), "timeout")
	new_bullet_trail.start_decay(global_position) # zadnja pika se pripne na mesto kolizije
	queue_free()