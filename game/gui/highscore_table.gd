extends VBoxContainer


onready var highscore_table_title: Label = $Title

func get_highscore_table(current_game_data: Dictionary, current_player_ranking: int):
	
	# malo spremenjeno, ko sem dal lestvico v meni ... če bodo game bo treba malce drugače 
	var current_game = current_game_data["game"]
	var current_game_name = current_game_data["game_name"]
	var current_game_level = current_game_data["level"]
	var current_game_hs_type = current_game_data["highscore_type"]
	
	var current_game_highscores = Global.data_manager.read_highscores_from_file(current_game)
	
	# naslov tabele
	highscore_table_title.text = "Best " + current_game_name + "s"  + " " + current_game_level
	
	# za vsako pozicijo vpišemo vrednost, ime in pozicijo
	var score_lines: Array = get_children()
	for scoreline in score_lines:
		var scoreline_index: int = score_lines.find(scoreline)
		var scoreline_position_key: String = str(scoreline_index)
		
		if scoreline_index != 0: # glava tabele
			# izberem position slovar glede na pozicijo score lineta
			var current_position_dict: Dictionary = current_game_highscores[scoreline_position_key]
			var current_position_dict_values: Array = current_position_dict.values()
			var current_position_dict_owners: Array = current_position_dict.keys()
			scoreline.get_node("Position").text = str(scoreline_index) + "."
			scoreline.get_node("Owner").text = str(current_position_dict_owners[0])
			
			if current_game_hs_type == Profiles.HighscoreTypes.HS_TIME_LOW or current_game_hs_type == Profiles.HighscoreTypes.HS_TIME_HIGH:
				scoreline.get_node("Score").text = str(current_position_dict_values[0]) + "s"
			elif current_game_hs_type == Profiles.HighscoreTypes.HS_POINTS:
				scoreline.get_node("Score").text = str(current_position_dict_values[0])
		
		# povdarim trenuten rezultat
		if scoreline_index == current_player_ranking and not scoreline_index == 0: # 0 je da izločim naslov
			scoreline.modulate = Global.color_green
			
