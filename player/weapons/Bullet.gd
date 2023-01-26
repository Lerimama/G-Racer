extends Node2D


#signal Get_hit (hit_location, bullet_velocity, bullet_owner)

var speed: float = 700.00

var hit_particles = preload("res://player/weapons/BulletHitParticles.tscn")
onready var raycast = $RayCast2D

func _ready() -> void:
	
	add_to_group("Bullets")
	set_as_toplevel(true)
	
	
func _process(delta: float) -> void:
	
	position += transform.x * speed * delta

#	print($RayCast2D.force_raycast_update())
#	$Line2D.rotation = $RayCast2D.rotation

	 
func _physics_process(delta: float) -> void:
	
	# ker so navadne kolizije prepočasne, uporabim raycast
	if raycast.is_colliding():
		
		var collision_position = raycast.get_collision_point()
		var distance_to_collision = raycast.get_collision_point() - global_position
		var part_location = global_position + distance_to_collision
		
		# rotacija partiklov glede na kot zadete površine
		var new_hit_particles = hit_particles.instance()
		new_hit_particles.position = part_location
		new_hit_particles.rotation = raycast.get_collision_normal().angle() # rotacija partiklov glede na normalo površine
		new_hit_particles.set_emitting(true)
		Global.node_creation_parent.add_child(new_hit_particles)
		
		queue_free()


func _on_BulletArea_body_entered(collider: Object) -> void:
	
	if collider != owner: # če telo ni od avtorja 
		
		print("colided")
#		if $RayCast2D.is_colliding():
#			print("hit")
		# hit efekt
#		var new_hit_particles = hit_particles.instance()
#		new_hit_particles.position = global_position
#		new_hit_particles.rotation = global_rotation - deg2rad(180)
#		new_hit_particles.set_emitting(true)
#		Global.node_creation_parent.add_child(new_hit_particles)
		
#		queue_free()
		
		if collider.has_method("on_hit"):
			collider.on_hit()
