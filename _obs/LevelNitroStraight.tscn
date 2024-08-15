extends KinematicBody2D
class_name Bullet


var spawned_by: Node
var spawned_by_color: Color

#export var speed: float = 1000.00
var direction: Vector2
var velocity: Vector2
var collision: KinematicCollision2D

var time: float = 0
#var hit_damage: float = 1
#var lifetime: float = 1
var new_bullet_trail: Object

onready var trail_position: Position2D = $TrailPosition
onready var collision_shape: CollisionShape2D = $BulletCollision
onready var spawner_detect: Area2D = $DetectArea

onready var BulletTrail: PackedScene = preload("res://game/weapons/BulletTrail.tscn") 
onready var HitParticles: PackedScene = preload("res://game/weapons/BulletHitParticles.tscn")

var bullet_momentum: float # je zmnožek hitrosti in teže
var collider_momentum: float # je zmnožek hitrosti in teže

# neu
var force: float

onready var weapon_profile: Dictionary = Pro.weapon_profiles["bullet"]
onready var reload_time: float = weapon_profile["reload_time"]
onready var hit_damage: float = weapon_profile["hit_damage"]
onready var lifetime: float = weapon_profile["lifetime"]
onready var inertia: float = weapon_profile["inertia"]
onready var speed: float = weapon_profile["speed"]
#onready var direction_start_range: Array = misile_profile["direction_start_range"] # natančnost misile

onready var vision_ray: RayCast2D = $RayCast2D
var bullet_active: bool = true

func _ready() -> void:
	
	add_to_group(Ref.group_bullets)
	modulate = spawned_by_color
	collision_shape.disabled = true # da ne trka z avtorjem ... ga vključimo, ko raycast zazna izhod
		
	# set movement vector
	direction = Vector2(cos(rotation), sin(rotation))
	
	# spawn trail
	new_bullet_trail = BulletTrail.instance()
	new_bullet_trail.gradient.colors[1] = spawned_by_color
	new_bullet_trail.z_index = z_index + Set.trail_z_index
	Ref.node_creation_parent.add_child(new_bullet_trail)
	
	# speed = 10
	velocity = direction * speed	# velocity is the velocity vector in pixels per second?

			
func _physics_process(delta: float) -> void:
	
	time += delta
	new_bullet_trail.add_points(trail_position.global_position) # premaknjeno iz process
		
	move_and_slide(velocity) # ma delto že vgrajeno
	
	# način na kolizije
	#	# detect avtorja ... prva je zato, ker se zgodi hitreje
	#	for body in spawner_detect.get_overlapping_bodies():
	#		if body == spawned_by:
	##		if body.name == spawned_by:
	#			collision_shape.disabled = true
	#		elif body != spawned_by:
	##		elif body.name != spawned_by:
	#			collision_shape.disabled = false
	#	
	#	if get_slide_count() != 0: # preverjamo obstoj kolizije
	#
	#		collision = get_slide_collision(0) # prva kolizija, da odstranimo morebitne erorje v debuggerju
	#		destroy_bullet()
	#
	#		if collision.collider.has_method("on_hit"):
	#
	#			# tilemap prevede pozicijo na najbližjo pozicijo tileta v tilempu  
	#			# to pomeni da lahko izbriše prazen tile
	#			# s tem ko poziciji dodamo nekaj malega v smeri gibanja izstrelka, poskrbimo, da je izbran pravi tile 
	#
	#			# pošljem kolizijo in node ... tam naredimo isto kot v zgornjem signalu
	#			collision.collider.on_hit(self)
			
	if vision_ray.is_colliding():
		collide()
	
func collide():
	
#	vision_ray.force_raycast_update() # ni glih učinka
	var current_collider = vision_ray.get_collider()
	destroy_bullet(vision_ray.get_collision_point(), vision_ray.get_collision_normal())
	if current_collider.has_method("on_hit"):
		# pošljem kolizijo in node ... tam naredimo isto kot v zgornjem signalu
		current_collider.on_hit(self)	
	velocity = Vector2.ZERO
	
			
func destroy_bullet(collision_position: Vector2, collision_normal: Vector2):	
	
	#func destroy_bullet():	
	#	new_hit_particles.position = collision.position
	#	new_hit_particles.rotation = collision.normal.angle() # rotacija partiklov glede na normalo površine 
	#	...
	#	new_bullet_trail.start_decay(collision.position) # zadnja pika se pripne na mesto kolizije
	#	...
	
	# hit partikli
	var new_hit_particles = HitParticles.instance()
	new_hit_particles.position = collision_position
	new_hit_particles.rotation = collision_normal.angle() # rotacija partiklov glede na normalo površine 
	new_hit_particles.color = spawned_by_color
	new_hit_particles.z_index = z_index + Set.explosion_z_index
	new_hit_particles.set_emitting(true)
	Ref.node_creation_parent.add_child(new_hit_particles)
	new_bullet_trail.start_decay(collision_position) # zadnja pika se pripne na mesto kolizije
	queue_free()
	
