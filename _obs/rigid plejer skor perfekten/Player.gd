extends RigidBody2D


## ----------------------------------------------------------------

## - gibanje plejerja sem hotel narediti bolj podobnega avtomobilu 
## - original koda je ful kompleksna in upošteva razdaljo me osmi pogona
## - na koncu sem stvari popreprostil in gibanje naredil precej simple
## - stvar, ki jih simuliram sta gradualno obračanje vozila z vožnjo (na mestu se tudi obrača, ker ni avto ampak "raketa")
## - ostal je tudi drift efekt ... ko držiš gas, vozilo drži smer gibanje, če samo obračaš  zavijanje ne pomaga več

## ----------------------------------------------------------------


export var rotation_per_frame = 200  # rotacija je narejena tako, da na vsak frejm obrača za določen kot
var current_rotation : float

var velocity = Vector2()
export var engine_power = 0.5  # pospešek

export var drag_coefficient = 1 # količlnik upora zraka 1 je 0
export var drift_factor = 0.01 # opredeli vektor stranskega gibanja 


func get_input():
	
	var rotation_multiplier = 0
	
	if Input.is_action_pressed("ui_right"):
		rotation_multiplier = 1
	if Input.is_action_pressed("ui_left"):
		rotation_multiplier = -1
		
	current_rotation = rotation_multiplier * deg2rad(rotation_per_frame)
	
	if Input.is_action_pressed("ui_up"):
#		engine_power += 0.1
		velocity += forward_direction() * engine_power
#		print(velocity)
	else:
#		velocity += forward_direction() * engine_power
#		velocity = Vector2.ZERO
		set_applied_force(Vector2.ZERO)
#		engine_power = 0
#		print(velocity)
	if Input.is_action_pressed("ui_down"):
		velocity = forward_direction() * engine_power/4
	
	velocity = forward_velocity() + (side_velocity() * drift_factor) # skupna hitrost gibanja je seštevek x in y vektorjev
	velocity *= drag_coefficient # upoštevam upor zraka, ki raste s hitrostjo

func _process(delta: float) -> void:
	get_input()
#	set_linear_velocity(velocity)
#	set_angular_velocity(current_rotation)
#	print(forward_direction())
	set_linear_velocity(velocity)


#func _integrate_forces(state: Physics2DDirectBodyState) -> void:
#
##	get_input()
##	set_linear_velocity(velocity)
#	set_angular_velocity(current_rotation)
##	set_applied_force (velocity)
#	apply_central_impulse(forward_direction()*engine_power)

	
func _physics_process(delta):

#	get_input()
#	set_linear_velocity(velocity)

	set_angular_velocity(current_rotation)
#	applied_force = velocity
#	apply_central_impulse(forward_velocity() + (side_velocity() * drift_factor))
#	apply_impulse(velocity)
#	add_force(side_velocity(),forward_direction())

 
## računanje vektorjev smeri in hitrosti

func forward_direction():
# smer vektorja "naprej"
	return Vector2(cos(-get_rotation() + PI/2.0), sin(-get_rotation() - PI/2.0))

func side_direction():
# smer vektorja "desno"
	return Vector2(cos(-get_rotation()), sin(get_rotation()))

func forward_velocity():
# smer in moč vektorja gor
	return forward_direction() * velocity.dot(forward_direction())

func side_velocity():
# smer in moč vektorja desno
	return side_direction() * velocity.dot(side_direction())
