extends RigidBody2D

func _ready() -> void:
	pass

onready var rigid_bolt: Node2D = $".."



	
func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	get_global_rotation()
#	print("SPID")
	if rigid_bolt:
		if not rigid_bolt.current_engine_power == 0:
			set_applied_force(Vector2.RIGHT.rotated(rigid_bolt.wheel_rotation) * 100 * rigid_bolt.current_engine_power)
#			set_applied_force(Vector2.RIGHT.rotated(rigid_bolt.wheel_rotation) * rigid_bolt.current_engine_power)
		else:
			set_applied_force(Vector2.ZERO)
		pass
