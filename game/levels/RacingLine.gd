extends Node2D


signal racing_line_changed (path)


onready var start_position: Position2D = $StartPosition
onready var finish_position: Position2D = $FinishPosition
onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
onready var racing_path: Line2D = $RacingPath


func _ready() -> void:
	
#	printt ("RacingLine", racing_path.get_point_count())
	
	pass
	
	
func draw_racing_line():
	
#	printt ("Racing line", racing_path.get_points().size())
	return racing_path.get_points()
#	navigation_agent.set_target_location(finish_position.global_position)


func _on_NavigationAgent2D_path_changed() -> void:
	emit_signal("racing_line_changed", navigation_agent.get_nav_path())
	printt("path", navigation_agent.get_nav_path().size())
	
