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

# NEW

onready var weapon_profile: Dictionary = Pro.weapon_profiles["bullet"]
onready var reload_time: float = weapon_profile["reload_time"]
onready var hit_damage: float = weapon_profile["hit_damage"]
onready var speed: float = weapon_profile["speed"]
onready var lifetime: float = weapon_profile["lifetime"]
onready var inertia: float = weapon_profile["inertia"]
#onready var direction_start_range: Array = misile_profile["direction_start_range"] # natančnost misile

var force: float

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
#	Ref.effects_creation_parent.add_child(new_bullet_trail)
	Ref.node_creation_parent.add_child(new_bullet_trail)
	
	velocity = direction * speed	# velocity is the velocity vector in pixels per second?
	
	
func _physics_process(delta: float) -> void:
	
	time += delta
	
	new_bullet_trail.add_points(trail_position.global_position) # premaknjeno iz process
	
	# detect avtorja ... prva je zato, ker se zgodi hitreje
	for body in spawner_detect.get_overlapping_bodies():
		if body == spawned_by:
#		if body.name == spawned_by:
			collision_shape.disabled = true
		elif body != spawned_by:
#		elif body.name != spawned_by:
			collision_shape.disabled = false
		
	move_and_slide(velocity) # ma delto že vgrajeno
	
	if get_slide_count() != 0: # preverjamo obstoj kolizije
		
		collision = get_slide_collision(0) # prva kolizija, da odstranimo morebitne erorje v debuggerju
		destroy_bullet()

		if collision.collider.has_method("on_hit"):

			# tilemap prevede pozicijo na najbližjo pozicijo tileta v tilempu  
			# to pomeni da lahko izbriše prazen tile
			# s tem ko poziciji dodamo nekaj malega v smeri gibanja izstrelka, poskrbimo, da je izbran pravi tile 

			# pošljem kolizijo in node ... tam naredimo isto kot v zgornjem signalu
			collision.collider.on_hit(self)
			

func destroy_bullet():	
	
	# hit partikli
	var new_hit_particles = HitParticles.instance()
	new_hit_particles.position = collision.position
	new_hit_particles.rotation = collision.normal.angle() # rotacija partiklov glede na normalo površine 
	new_hit_particles.color = spawned_by_color
	new_hit_particles.z_index = z_index + Set.explosion_z_index
	new_hit_particles.set_emitting(true)
	Ref.node_creation_parent.add_child(new_hit_particles)
	new_bullet_trail.start_decay(collision.position) # zadnja pika se pripne na mesto kolizije
	queue_free()
	

