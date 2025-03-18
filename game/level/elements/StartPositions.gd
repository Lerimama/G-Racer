tool
extends Node2D


export (int, 1, 20) var position_count: int = 4 setget _change_positions_count

onready var positions_flow: HFlowContainer = $PositionsFlow


func _ready() -> void:
	pass


func _change_positions_count(new_positions_count: int):

	if positions_flow:
		for position_index in positions_flow.get_child_count():
			if position_index > 0:
				positions_flow.get_child(position_index).queue_free()

		position_count = new_positions_count

		for count in position_count - 1: # template je že notri
			var new_driver_position: Control = positions_flow.get_child(0).duplicate()
			positions_flow.add_child(new_driver_position)
