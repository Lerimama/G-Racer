extends Node


signal highscores_updated # ko je vnešeno ime igralca

var data_file: = File.new()
var current_player_ranking: int # da ob rendriranju HS, lahko označim aktualni rezultat ... v GM
var default_highscores: Dictionary = { # slovar, ki se uporabi, če še ni nobenega v filetu
	"1": {"Nobody": 0,},
	"2": {"Nobody": 0,},
	"3": {"Nobody": 0,},
	"4": {"Nobody": 0,},
	"5": {"Nobody": 0,},
	"6": {"Nobody": 0,},
	"7": {"Nobody": 0,},
	"8": {"Nobody": 0,},
	"9": {"Nobody": 0,},
}


func _ready() -> void:
	Global.data_manager = self

	
func get_top_highscore(current_game: int):
	
	# load highscore
	var loaded_game_highscores = read_highscores_from_file(current_game) # ... v odprtem filetu se potem naloži highscore
	
	# current higscore in lastnik
	var all_scores: Array = []
	var all_score_owners: Array = []
	
	for hs_position_key in loaded_game_highscores:
		# dodam vrednost s pozicija
		var current_position_dict = loaded_game_highscores[hs_position_key]
		
		all_scores += current_position_dict.values()
		all_score_owners += current_position_dict.keys()
		
	# setam top score
	var current_highscore: float = all_scores.max()
	var current_highscore_index: int = all_scores.find(current_highscore)
	var current_highscore_owner: String = all_score_owners[current_highscore_index]
	
	# za GM hud
	return [current_highscore, current_highscore_owner]


func manage_gameover_highscores(current_score_points: int, current_score_time: int, current_game_data: Dictionary): # iz GM
	# med izvajanjem te kode GM čaka na RESUME 1
	
	var current_game: int = Global.game_manager.game_data["game"]
	var current_game_highscores: Dictionary # zaenkrat samo pri G-O
	var all_ranking_scores: Array = []
	var all_ranking_score_owners: Array = []
	
	current_game_highscores = read_highscores_from_file(current_game) # ... v odprtem filetu se potem naloži highscore
	
	# poberemo lestvico v arraye
	for hs_position_key in current_game_highscores:
		var current_position_dict = current_game_highscores[hs_position_key]
		all_ranking_scores += current_position_dict.values()
		all_ranking_score_owners += current_position_dict.keys()
	
	
	var better_positions_count: int
	var current_value_to_rank: int
	var current_secondary_value: int
	
	
	# izračun uvrstitve na lestvico ... štejem pozicije pred mano 
	# trenutno je setano, da se da uporabit sekundarno vrednost za dodatno ločevanje
	
	better_positions_count = 0 # 0 je 1. mesto
	for ranking_score in all_ranking_scores:
		match current_game_data["highscore_type"]:
			Profiles.HighscoreTypes.HS_POINTS:
				current_value_to_rank = current_score_points
				current_secondary_value = current_score_time
				if ranking_score >= current_value_to_rank:
					better_positions_count += 1				
			Profiles.HighscoreTypes.HS_TIME_LOW:
				current_value_to_rank = current_score_time
				current_secondary_value = current_score_points
				if ranking_score <= current_value_to_rank and not ranking_score <= 0:
					better_positions_count += 1				
			Profiles.HighscoreTypes.HS_TIME_HIGH:
				current_value_to_rank = current_score_time
				current_secondary_value = current_score_points
				if ranking_score >= current_value_to_rank:
					better_positions_count += 1
		
	current_player_ranking = better_positions_count + 1 # za označitev linije na lestvici
	
	# NI na lestvici
	if better_positions_count >= all_ranking_scores.size():
		return false
	# JE na lestvici
	else:
		# YIELD 2 ... čaka na novo ime, ki bo prišlo iz GM, ki ga dobi od GO
		yield(Global.gameover_menu, "name_input_finished")
		
		# RESUME 2
		# nova highscore lestvica		
		var current_score_owner_name = Global.gameover_menu.p1_final_stats["player_name"]
		
		# dodam plejer score v array
		all_ranking_scores.insert(better_positions_count, current_value_to_rank)
		all_ranking_score_owners.insert(better_positions_count, current_score_owner_name)

		# odstranim zadnjega ... najnižjega
		all_ranking_scores.pop_back()
		all_ranking_score_owners.pop_back()
		
		# sestavim nov hs slovar
		var new_game_highscores: Dictionary
		var highscore_index = 0
		for ranking_score in all_ranking_scores:
			var highscores_position_key: String = str(highscore_index + 1)
			var highscores_value: float = ranking_score
			var highscores_owner: String = all_ranking_score_owners[highscore_index]
			var position_dict: Dictionary = {
				highscores_owner: highscores_value,	
			}

			new_game_highscores[highscores_position_key] = position_dict
			highscore_index += 1

		# sejvam hs slovar v filet
		write_highscores_to_file(current_game, new_game_highscores)
		
		emit_signal("highscores_updated")


func read_highscores_from_file(current_game_key: int):
	
	var current_game_name = Profiles.Games.keys()[current_game_key]
	printt("read hs from game name", current_game_name)
	
	# preverjam obstoj fileta ... ob prvem nalaganju igre
	var error = data_file.open("user://game_%s_highscores.save" % current_game_name, File.READ)
	# The file is created if it does not exist, and truncated if it does.
	
	# če fileta ni, ga ustvarim in zapišem default hs dict
	if error != OK: # OK je 0
		# printt("Error loading file", error)
		data_file.open("user://game_%s_highscores.save" % current_game_name, File.WRITE) # vsak game ma svoj filet
		# vnesem default HS
		data_file.store_line(to_json(default_highscores))
		data_file.close()
		# printt("Default file created", data_file)
		# ko je filet ustvarjen grem naprej na podajanje vse HSjev
	
	data_file.open("user://game_%s_highscores.save" % current_game_name, File.READ)
	# printt("File loaded", data_file)
		
	# prepiši podatke iz fileta v igro
	var current_game_highscores = parse_json(data_file.get_line())
	data_file.close()
	
	return current_game_highscores
	

func write_highscores_to_file(current_game_key: int, new_game_highscores: Dictionary):
	
	var current_game_name = Profiles.Games.keys()[current_game_key]
	printt("write hs to game name", current_game_name)
	
	# podam novi HS v json obliko
	var json_string = JSON.print(new_game_highscores)
	printt("save json_string", json_string)
	
	# preverjam obstoj fileta ... v tem primeru že obstaja, ker ga igra ustvari ob prvem nalaganju
	var error = data_file.open("user://game_%s_highscores.save" % current_game_name, File.READ)
	
	# če fileta ni, ga ustvarim in zapišem novi HS
	if error != OK:
		# printt("Error opening file", error)
		data_file.open("user://game_%s_highscores.save" % current_game_name, File.WRITE) # vsak game ma svoj filet
		printt("Empty file created", data_file)
	else:
		# printt("File opened", error)
		data_file.open("user://game_%s_highscores.save" % current_game_name, File.WRITE) # vsak game ma svoj filet
	
	# vnesem novi HS
	data_file.store_line(to_json(new_game_highscores))
	
	data_file.close()
		
