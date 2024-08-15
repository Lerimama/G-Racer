extends Node2D


func _ready() -> void:
	
	pass
	
#func draw_racing_line():
#
#	var racing_line: Line2D = $RacingPath
#	split_line($RacingPath)
#	printt("P", racing_line.get_points().size())
#	return racing_line.get_points()


	
func draw_racing_lines():
	
	var racing_lines_points: Array
	var all_racing_lines: Array
	var all_racing_lines_points: Array
	
	for racing_line in get_children():
		split_line(racing_line)
		for point in racing_line.get_points():
			all_racing_lines_points.append(point)
		all_racing_lines.append(racing_line)
	
	return all_racing_lines
	
	
func split_line(racing_path: Line2D):
	
	var cut_distance: float = 5 # dolžina, ki jo želim med pikami
	var cut_count_limit: int = 1000 # največ tolikokrat razreže vsak segment
	
	# za vsako piko v original liniji, razdelim njen vektor do naslednje pike
	var original_racing_line_points: Array = racing_path.get_points()
	for original_point in original_racing_line_points:
		
		# vsakič znova zajamem vse pike v trenutni liniji
		var updated_racing_line_points = racing_path.get_points()
		var updated_original_point_index = updated_racing_line_points.find(original_point)
		var updated_last_original_point_index = updated_racing_line_points.size() - 1
		# če je pika zadnja v celi liniji, je ne splitam
		if updated_original_point_index == updated_last_original_point_index: 
			return # prekinem, če je original zadnja pika enaka zadnji piki trenutne linije
		
		# za vsak rez dodam novo točko na razdalji
		for cut_count in cut_count_limit:
			# vsakič znova zajamem vse pike v trenutni liniji
			var current_points_in_line: Array = racing_path.get_points()
			# določim vektor od trenutne do naslednje točke v liniji
			var current_point: Vector2 = current_points_in_line[updated_original_point_index + cut_count]
			var next_point: Vector2 = current_points_in_line[updated_original_point_index + cut_count + 1]
			var vector_to_next_point: Vector2 = next_point - current_point
			# če je razdalja do naslednje točke manjša od določene minimalne ustavim rezanje
			if vector_to_next_point.length() < 5:
				break
			# dodam novo točko na določeni dolžini vektorja
			var new_point: Vector2 = current_point + vector_to_next_point.normalized() * 5
			var new_point_index: int = updated_original_point_index + cut_count + 1
			racing_path.add_point(new_point, new_point_index)
	
	return racing_path	
#			Met.spawn_indikator(new_point, 0)
		
