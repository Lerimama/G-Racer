tool
extends KinematicBody2D
# testni brejker in shadow holder

export var height = 500 setget _change_height
export var elevation = 0
export var transparency: float = 1


func _process(delta: float) -> void:

	$Label.text = str(height)

func _change_height(new_height: float):

	height = new_height
	$Label.text %= str(height)


func on_hit(hitting_node: Node2D, hit_global_position: Vector2):

	$BreakerShape.on_hit(hitting_node, hit_global_position)
