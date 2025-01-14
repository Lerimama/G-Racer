extends RigidBody2D
# testni brejker in shadow holder

export var height = 500 # setget
export var elevation = 0 # setget


func on_hit(hitting_node: Node2D, hit_global_position: Vector2):

	$BreakerShape.on_hit(hitting_node, hit_global_position)
