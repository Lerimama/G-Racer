extends RigidBody2D

export var height = 500 # setget
export var elevation = 0 # setget
export var test: bool = false


onready var navigation_obstacle_2d: NavigationObstacle2D = $NavigationObstacle2D


func on_hit(hitting_node: Node2D, hit_global_position: Vector2):

	$BreakerShape.on_hit(hitting_node, hit_global_position)
