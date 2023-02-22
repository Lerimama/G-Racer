extends KinematicBody2D


signal Get_hit_by_bullet (hit_location, bullet_velocity, bullet_owner)

export var speed: float = 1400.00
var direction: Vector2
var velocity: Vector2
var collision: KinematicCollision2D

var away_from_owner_time_limit: float = 0.041 # za pedenanje kontakta z lastnikom
var away_from_owner: bool 
var away_from_owner_time: float

var new_bullet_trail: Object

onready var BulletTrail: PackedScene = preload("res://player/weapons/fx/BulletTrail.tscn") 
onready var HitParticles: PackedScene = preload("res://player/weapons/fx/BulletHitParticles.tscn")
onready var TrailPosition: Position2D = $TrailPosition
onready var Collision2D: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	
	add_to_group("Bullets")
#	set_as_toplevel(true)
	
	
	Collision2D.disabled = true # da ne trka z avtorjem ... ga vključimo kmalu za tem
		
	# set movement vector
	direction = Vector2(cos(rotation), sin(rotation))
	velocity = direction * speed	
	
	# spawn trail
	new_bullet_trail = BulletTrail.instance()
	AutoGlobal.effects_creation_parent.add_child(new_bullet_trail)
	new_bullet_trail.set_as_toplevel(true)
	
#	modulate.a = 0
	
	
func _process(delta: float) -> void:
	
	new_bullet_trail.add_points(global_position)
	
	away_from_owner_time += 1.5 * delta
	if away_from_owner_time >= away_from_owner_time_limit:
		Collision2D.disabled = false
		

func _physics_process(delta: float) -> void:

	move_and_slide(velocity)

	# preverjamo obstoj kolizije ... prvi kontakt, da odstranimo morebitne erorje v debuggerju
	if get_slide_count() != 0:
		collision = get_slide_collision(0) # we wan't to take the first collision
		
		# hit partikli
		var new_hit_particles = HitParticles.instance()
		new_hit_particles.position = collision.position
		new_hit_particles.rotation = collision.normal.angle() # rotacija partiklov glede na normalo površine 
		new_hit_particles.set_emitting(true)
		AutoGlobal.effects_creation_parent.add_child(new_hit_particles)
		
		new_bullet_trail.start_decay()
		
		print ("KUEFRI - Bullet")
		queue_free()
		
		
		
	# če kolizija obstaja in ima collider metodo ...
	if collision != null: # and collision.collider.has_method("on_got_hit"):
		
		# pošljem podatek o lokaciji, smer in hitrost
		# zakaj je normalizirano? https://www.youtube.com/watch?v=dNb0L2hu3m0
#		emit_signal("Get_hit_by_bullet", collision_data.position + velocity.normalized()) 
		print("Get_hit_by_bullet")
		
		pass
