extends KinematicBody2D


signal Get_hit_by_bullet (hit_location, bullet_velocity, bullet_owner)

var spawned_by: String

export var speed: float = 1400.00
var direction: Vector2
var velocity: Vector2
var collision: KinematicCollision2D

var away_from_owner_time_limit: float = 0.030 # za pedenanje kontakta z lastnikom
var away_from_owner: bool 
var away_from_owner_time: float

var new_bullet_trail: Object

#onready var detect_area: Area2D = $DetectArea
onready var trail_position: Position2D = $TrailPosition
onready var collision_shape: CollisionShape2D = $BulletCollision

onready var BulletTrail: PackedScene = preload("res://player/weapons/fx/BulletTrail.tscn") 
onready var HitParticles: PackedScene = preload("res://player/weapons/fx/BulletHitParticles.tscn")


func _ready() -> void:
	
	add_to_group("Bullets")
	
	collision_shape.disabled = true # da ne trka z avtorjem ... ga vključimo ko area zazna izhod
		
	# set movement vector
	direction = Vector2(cos(rotation), sin(rotation))
	velocity = direction * speed	
	
	# spawn trail
	new_bullet_trail = BulletTrail.instance()
#	new_bullet_trail.global_position = position
#	new_bullet_trail.rotation = global_rotation
	AutoGlobal.effects_creation_parent.add_child(new_bullet_trail)
#	new_bullet_trail.set_as_toplevel(true)
	
	
func _process(delta: float) -> void:
	
	new_bullet_trail.add_points(global_position)
	
	away_from_owner_time += 1.5 * delta
	if away_from_owner_time >= away_from_owner_time_limit:
		collision_shape.disabled = false
		print ("taJM")		
		print (collision_shape.disabled)

func _physics_process(delta: float) -> void:

	move_and_slide(velocity)

	# preverjamo obstoj kolizije ... prvi kontakt, da odstranimo morebitne erorje v debuggerju
	if get_slide_count() != 0:
		collision = get_slide_collision(0) # we wan't to take the first collision
		destroy_bullet()
		
	# če kolizija obstaja in ima collider metodo ...
	if collision != null && collision.collider.has_method("on_hit_by_bullet"):
		
#		emit_signal("Get_hit_by_bullet", collision_data.position + velocity.normalized()) 

		# pošljem podatek o lokaciji, smer in hitrost
		collision.collider.on_hit_by_bullet(velocity, spawned_by)


func destroy_bullet():	
		
	# hit partikli
	var new_hit_particles = HitParticles.instance()
	new_hit_particles.position = collision.position
	new_hit_particles.rotation = collision.normal.angle() # rotacija partiklov glede na normalo površine 
	new_hit_particles.set_emitting(true)
	AutoGlobal.effects_creation_parent.add_child(new_hit_particles)
	
	new_bullet_trail.global_position = collision.position
	new_bullet_trail.start_decay()
#		print ("KUFRI - Bullet")
	print("destroy")
	queue_free()
	
	
# za onemogočanje kolizije z avtorjem
func _on_DetectArea_body_exited(body: Node) -> void:
	
	if body.name == spawned_by:
#		collision_shape.disabled = false # v ready ga setamo true
		print ("collision_shape.disabled")
		print (collision_shape.disabled)
