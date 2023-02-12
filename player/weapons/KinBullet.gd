extends KinematicBody2D

signal get_hit(at_position)

const speed: float = 200.00
const SPEED: float = 800.00

var direction: Vector2
var velocity: Vector2
var collision_data: KinematicCollision2D



func _ready() -> void:
	add_to_group("Bullets")
	set_as_toplevel(true)
	set_movement_vector()
	pass

func _process(delta: float) -> void:
	position += transform.x * speed * delta
	
func _physics_process(delta: float) -> void:
	move_and_slide(velocity)

	# preverjamo obstoj kolizije ... prvi kontakt, da odstranimo morebitne erorje v debuggerju
	if get_slide_count() != 0:
		collision_data = get_slide_collision(0) # we wan't to take the first collision

	# če kolizija obstaja in ima collider metodo ...
	if collision_data != null and collision_data.collider.has_method("on_got_hit"):
		# pošljem podatek o lokaciji, smer in hitrost
		# zakaj je normalizirano? https://www.youtube.com/watch?v=dNb0L2hu3m0
		emit_signal("get_hit", collision_data.position + velocity.normalized()) 

#		queue_free()	
#		print ("get_hit")
		
func set_movement_vector():

	direction = Vector2(cos(rotation), sin(rotation))
	velocity = direction * SPEED
