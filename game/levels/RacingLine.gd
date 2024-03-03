extends Node2D


signal racing_line_changed (path)


onready var start_position: Position2D = $StartPosition
onready var finish_position: Position2D = $FinishPosition
onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
onready var racing_path: Line2D = $RacingPath


func _ready() -> void:
#	printt ("RacingLine", racing_path.get_point_count())
	
	pass
	
	
var all_points_in_line: Array
func draw_racing_line():
	

	all_points_in_line = racing_path.get_points()
	printt ("points", all_points_in_line.size())
	all_points_to_split = all_points_in_line.duplicate()
	split_line()
	printt ("points", all_points_in_line.size())
	return racing_path.get_points()

var all_points_to_split: Array

func split_line():
	
	var points_to_split: Array
	var points_to_add: Array
	
	# za vsako od točk na liniji preverim razdaljo do naslednje
	for point in all_points_to_split:
		var point_index: int = all_points_in_line.find(point)
		if point_index == all_points_in_line.size() - 1:
			break
		var next_point_index: int = point_index + 1
		var next_point: Vector2 = all_points_in_line[next_point_index]
		var vector_between_points: Vector2 = next_point - point
		var new_point_position: Vector2 = vector_between_points
		points_to_add.append(new_point_position)
#		var distance_between_points = (next_point - point).length()
	
		# če je razdalja večja kot, potem jo razpolovim
		if vector_between_points.length() > 50:
			var new_point = point + vector_between_points / 2
			var new_vector_beetwen_points: Vector2 = new_point - point
			if new_vector_beetwen_points.length() > 50:
				points_to_split.append(point)
#			if new_vector_beetwen_points.length() < 100:
#				all_points_to_split.erase(point)
	
	for point_position in points_to_add:
		racing_path.add_point(point_position)
			
			
	all_points_to_split = points_to_split
	
#	if not all_points_to_split.empty():
##		print("še enkrat")
#		split_line()
#	else:
	printt("P",  racing_path.get_points().size())
#			printt ("points", point, next_point)
#			printt ("new_point", new_point)
#			printt ("vec", vector_between_points.length())
#			points_to_split.append()
	
#	var point_1_index = all_points.size() - 1 
#	var point_1 = all_points[point_1_index]
#	var point_2 = all_points[point_1_index - 1]
#
#	var vector_between_points = point_1 - point_2
#	var new_point = point_1 + vector_between_points/2
#	var vector_between_points_2 = point_1 - new_point
#	printt ("point", point_1)
#	printt ("point", point_2)
#	printt ("point 3", new_point)
#	printt ("vec", vector_between_points.length(), vector_between_points_2.length())
	


func split_point(point_to_split): # razdeli med določeno točko in njeno naslednjo 
	print(point_to_split)
	
	

func _on_NavigationAgent2D_path_changed() -> void:
	return
#	emit_signal("racing_line_changed", navigation_agent.get_nav_path())
#	printt("path", navigation_agent.get_nav_path().size())
	
