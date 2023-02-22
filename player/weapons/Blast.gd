extends Node2D


#signal Get_hit (hit_location, misile_velocity, misile_owner)

var speed: float = 0 # regulacija v animaciji
var direction: Vector2

# domet
var is_active: bool# zadetek ali domet
export var is_active_time: float = 2 # zadetek ali domet

#animacije
var animation_loop_counter: int = 0 # resetiraš po vsakem maxu
var max_activated_loops: int = 5
var max_blink_loops: int = 10

var new_blast_trail: Object

onready var explosion_particles: Particles2D = $ExplosionParticles
onready var blast_sprite: AnimatedSprite = $BlastSprite
onready var BlastTrail: PackedScene = preload("res://player/weapons/fx/BlastTrail.tscn") 


func _ready() -> void:
	
	add_to_group("Blasts")
	
	is_active = true
	randomize()
	blast_sprite.play("flight_loop")
	
	direction = transform.x # rotacija smeri ob štartu
	$AnimationPlayer.play("flight")

#	explosion_particles.emitting = true
	
		
	# spawn trail
	new_blast_trail = BlastTrail.instance()
	AutoGlobal.effects_creation_parent.add_child(new_blast_trail)
	new_blast_trail.set_as_toplevel(true)
	
	
	
func _process(delta: float) -> void:
	
	if speed > 5: # da konča že dolj pred kuefri nodeta
		new_blast_trail.add_points(global_position)
	
	position += direction * speed * delta # * accelaration


func _on_BlastSprite_animation_finished() -> void: # prvič klicano iz animacije
	
	animation_loop_counter += 1
	
	# prehodi animacij
	match blast_sprite.animation:
		# flight
		"flight_loop":
			blast_sprite.play("expand")
			new_blast_trail.start_decay()
		# expand
		"expand":
			blast_sprite.play("activated_loop")
		# activate
		"activated_loop":
			if animation_loop_counter >= max_activated_loops && animation_loop_counter < max_blink_loops:	
				blast_sprite.play("blink_loop")
		# explode
		"blink_loop":
			if animation_loop_counter >= max_blink_loops:	
#				blast_sprite.stop() # true je za reverse 
				explode()
	
	print (blast_sprite.animation)
	print(animation_loop_counter)


#func expand_animation_start(): # klicano iz animacije
#
#	blast_sprite.play("expand")
#	new_blast_trail.start_decay()
	
	
func explode(): 
	
	$AnimationPlayer.play("explode")	
	explosion_particles.emitting = true


func kuefri():
	print ("KUEFRI - Blast")
	queue_free()
