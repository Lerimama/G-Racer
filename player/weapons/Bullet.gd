extends KinematicBody2D


signal Get_hit_by_bullet (hit_location, bullet_velocity, bullet_owner)

export var speed: float = 800.00
var direction: Vector2
var velocity: Vector2
var collision: KinematicCollision2D

var bullet_trail: Object

onready var BulletTrail = preload("res://player/weapons/BulletTrail.tscn") 
onready var HitParticles = preload("res://player/weapons/BulletHitParticles.tscn")
onready var TrailPosition = $TrailPosition




func _ready() -> void:
	
	add_to_group("Bullets")
	set_as_toplevel(true)
	
	# set movement vector
	direction = Vector2(cos(rotation), sin(rotation))
	velocity = direction * speed	
	
	bullet_trail = BulletTrail.instance()
	AutoGlobal.effects_creation_parent.add_child(bullet_trail)
	bullet_trail.set_as_toplevel(true)
	
	
func _process(delta: float) -> void:
	
	bullet_trail.add_points(global_position)
	
	 
func _physics_process(delta: float) -> void:

	move_and_slide(velocity)

	# preverjamo obstoj kolizije ... prvi kontakt, da odstranimo morebitne erorje v debuggerju
	if get_slide_count() != 0:
		collision = get_slide_collision(0) # we wan't to take the first collision
		
		# hit partikli
		var hit_particles = HitParticles.instance()
		hit_particles.position = global_position
		hit_particles.rotation = collision.normal.angle() # rotacija partiklov glede na normalo površine 
		hit_particles.set_emitting(true)
		AutoGlobal.effects_creation_parent.add_child(hit_particles)
		
		bullet_trail.stop()
		queue_free()
		
		
		
	# če kolizija obstaja in ima collider metodo ...
	if collision != null: # and collision.collider.has_method("on_got_hit"):
		
		# pošljem podatek o lokaciji, smer in hitrost
		# zakaj je normalizirano? https://www.youtube.com/watch?v=dNb0L2hu3m0
#		emit_signal("Get_hit_by_bullet", collision_data.position + velocity.normalized()) 
		print("Get_hit_by_bullet")
		
		pass
