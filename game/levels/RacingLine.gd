extends Node2D


onready var start_position: Position2D = $StartPosition
onready var finish_position: Position2D = $FinishPosition
onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
onready var racing_path: Line2D = $RacingPath


func _ready() -> void:
	
	printt ("RACING LINE", racing_path.get_point_count())
	pass
	
func draw_racing_line():

	split_line()
	return racing_path.get_points()


func split_line():
	
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
		
		# za vsak rez dodam novo točko na razdaljij
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
			
#			Met.spawn_indikator(new_point, 0)
		
