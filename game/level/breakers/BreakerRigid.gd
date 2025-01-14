extends RigidBody2D


export var height = 500 # setget
export var elevation = 0 # setget

var rot = 0 setget _change_rotation


func on_hit(hitting_node: Node2D, hit_global_position: Vector2):

	$BreakerShape.on_hit(hitting_node, hit_global_position)


func _physics_process(delta: float) -> void:
#	printt ("rotation", rotation)

	rot = rotation

func _change_rotation(new_rot):

	if not new_rot == rot:
		rot = new_rot

		$ShapeShadows.update_all_shadows()
