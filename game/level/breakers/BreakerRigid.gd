extends RigidBody2D

export var height = 500 # setget
export var elevation = 0 # setget
export var test: bool = false


onready var navigation_obstacle_2d: NavigationObstacle2D = $NavigationObstacle2D

func _ready() -> void:

	if test:
		Rfs.temp_object == self


func on_hit(hitting_node: Node2D, hit_global_position: Vector2):

	$BreakerShape.on_hit(hitting_node, hit_global_position)
