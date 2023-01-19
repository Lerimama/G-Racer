extends Node2D


#signal Get_hit (hit_location, bullet_velocity, bullet_owner)

const SPEED: float = 700.00

var hit_particles = preload("res://player/weapons/BulletHitParticles.tscn")


func _ready() -> void:
	
	add_to_group("Bullets")
	set_as_toplevel(true)
	
	
func _process(delta: float) -> void:
	
	position += transform.x * SPEED * delta

#	print($RayCast2D.force_raycast_update())
	$Line2D.rotation = $RayCast2D.rotation


func _on_BulletArea_body_entered(body: Node) -> void:

	if body != owner: # če telo ni od avtorja 
		
#		if $RayCast2D.is_colliding():
#			print("hit")
		# hit efekt
		var new_hit_particles = hit_particles.instance()
		new_hit_particles.position = global_position
		new_hit_particles.rotation = global_rotation - deg2rad(180)
		new_hit_particles.set_emitting(true)
		Global.node_creation_parent.add_child(new_hit_particles)
		
		queue_free()
		
		if body.has_method("on_hit"):
			body.on_hit()
