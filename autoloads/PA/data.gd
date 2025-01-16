extends Node


signal scores_saved

var data_file: = File.new()

var settings_file_name: String = "user_settings"

var data_game_settings: Dictionary = {
#	"pregame_screen_on": Profiles.pregame_screen_on,
#	"camera_shake_on": Profiles.camera_shake_on,
#	"tutorial_mode": Profiles.tutorial_mode,
#	"vsync_on": Profiles.vsync_on,
}


func get_saved_highscore(current_game_data: Dictionary):
	# najprej preverjam globalne
	# potem preverjam lokalne
	# potem oba me sabo, kateri je boljši
	# load highscore ...
	# na koncu najvišjega globalnega primerjam z top lokalnim (neobjavljenim) in pokažem boljšega
	var loaded_global_highscores: Dictionary = read_highscores_from_file(current_game_data)
	var loaded_local_highscores: Dictionary = read_highscores_from_file(current_game_data, true)

	# globalni
	var global_first_rank_key: String = loaded_global_highscores.keys()[0]
	var global_hs_owner: String = loaded_global_highscores[global_first_rank_key].keys()[0]
	var global_hs_score: float = loaded_global_highscores[global_first_rank_key].values()[0]

	# lokalni
	var local_first_rank_key: String = loaded_local_highscores.keys()[0]
	var local_hs_owner: String = loaded_local_highscores[local_first_rank_key].keys()[0]
	var local_hs_score: float = loaded_local_highscores[local_first_rank_key].values()[0]

	var top_highscore: float
	var top_highscore_owner: String

	# če globalni ni 0 ga primerjam (zraven izločam lokalni 0 score)
	if global_hs_score > 0:
		top_highscore = global_hs_score
		top_highscore_owner = global_hs_owner
		# preverim, če je lokalni skor boljši (samo neobjavljeni je lahko višji)
		if current_game_data["highscore_type"] == Profiles.HighscoreTypes.POINTS:
			if local_hs_score > global_hs_score:
				top_highscore = local_hs_score
				top_highscore_owner = local_hs_owner
		elif current_game_data["highscore_type"] == Profiles.HighscoreTypes.TIME:
			if local_hs_score < global_hs_score and local_hs_score > 0:
				top_highscore = local_hs_score
				top_highscore_owner = local_hs_owner
	# če je globalni 0 pa lokalni ni ... ne primerjam > zapišem lokalnega
	elif local_hs_score > 0:
		top_highscore = local_hs_score
		top_highscore_owner = local_hs_owner
	# če ni nobenega rezultata
	else:
		top_highscore = 0
		top_highscore_owner = "Nobody"

	return [top_highscore, top_highscore_owner]


func delete_highscores_file(file_game_data: Dictionary):

	var file_game_name: String
	var local_highscores = true

	if Profiles.tilemap_paths[file_game_data["game"]].size() > 1:
		file_game_name = Profiles.Games.keys()[file_game_data["game"]] + "_" + file_game_data["level_name"]
	else:
		file_game_name = Profiles.Games.keys()[file_game_data["game"]]

	if not local_highscores:
		file_game_name += "_Global"

	var file_directory: Directory = Directory.new()
	var file_path: String = "user://%s_highscores.save" % file_game_name
	var error = file_directory.remove(file_path)


func save_player_score(current_score: float, current_game_data: Dictionary):
	# med izvajanjem te kode GM čaka
	# poberem trenutno lestvico (potem generiram novo z dodanim trenutnim skorom)

	var all_ranking_scores: Array = []
	var all_ranking_score_owners: Array = []
	var local_game_highscores: Dictionary = read_highscores_from_file(current_game_data, true) # ... v odprtem filetu se potem naloži highscore
	var score_local_ranking: int = _check_player_ranking(current_score, local_game_highscores, current_game_data)

	for hs_position_key in local_game_highscores:
		var current_position_dict: Dictionary = local_game_highscores[hs_position_key]
		var current_pos_score: float = current_position_dict.values()[0]
		if current_pos_score > 0:
			all_ranking_scores.append_array(current_position_dict.values())
			all_ranking_score_owners.append_array(current_position_dict.keys())

	# ime plejerja
	var current_score_owner_name: String = Global.gameover_gui.p1_final_stats["player_name"]
	current_score_owner_name = current_score_owner_name

	# zgradim novo lestvico z dodanim plejerjem in scorom
	all_ranking_scores.insert(score_local_ranking - 1, current_score) # -1, ker rank nima 0 index, size pa ga ima
	all_ranking_score_owners.insert(score_local_ranking - 1, current_score_owner_name)

	# sestavim nov slovar za lestvico
	var new_game_highscores: Dictionary
	var highscore_index = 0
	for ranking_score in all_ranking_scores:
		var highscores_position_key: String = "%03d" % (highscore_index + 1)
		var highscores_value: float = ranking_score
		var highscores_owner: String = all_ranking_score_owners[highscore_index]
		var position_dict: Dictionary = {
			highscores_owner: highscores_value,
		}
		new_game_highscores[highscores_position_key] = position_dict
		highscore_index += 1

	# sejvam hs slovar v filet
	write_highscores_to_file(current_game_data, new_game_highscores, true)

	#	emit_signal("scores_saved") # OPT trenutno se ne uporablja, čeprav bi bilo dobra praksa


# READ & WRITE ------------------------------------------------------------------------------------------------------------------------


func write_settings_to_file():
	# slovar prikličem v profilih
	data_game_settings["pregame_screen_on"] = Profiles.pregame_screen_on
	data_game_settings["camera_shake_on"] = Profiles.camera_shake_on
	data_game_settings["tutorial_mode"] = Profiles.tutorial_mode
	data_game_settings["analytics_mode"] = Profiles.analytics_mode
	data_game_settings["vsync_on"] = Profiles.vsync_on
	# neu
	data_game_settings["touch_controller"] = Profiles.set_touch_controller
	data_game_settings["touch_sensitivity"] = Profiles.screen_touch_sensitivity

	# podam novi HS v json obliko
	var json_string = JSON.print(data_game_settings)

	# če fileta ni, ga funkcija ustvari iz File.new()
	data_file.open("user://%s.save" % settings_file_name, File.WRITE) # vsak game ma svoj filet

	# vnesem novi HS
	data_file.store_line(to_json(data_game_settings))
	data_file.close()


func read_settings_from_file():

	# preverjam obstoj fileta ... ob prvem nalaganju igre
	var error = data_file.open("user://%s.save" % settings_file_name, File.READ)
	if error != OK:
		write_settings_to_file()
	# odprem filet za branje
	data_file.open("user://%s.save" % settings_file_name, File.READ)

	# prepiši podatke iz fileta v igro
	var read_game_settings = parse_json(data_file.get_line())
	data_file.close()

	return read_game_settings


func write_highscores_to_file(write_game_data: Dictionary, new_game_highscores: Dictionary, local_highscores: bool = false):

	# get hs name
	var write_game_name: String
	if Profiles.tilemap_paths[write_game_data["game"]].size() > 1:
		write_game_name = Profiles.Games.keys()[write_game_data["game"]] + "_" + write_game_data["level_name"]
	else:
		write_game_name = Profiles.Games.keys()[write_game_data["game"]]

	# če je global HS
	if not local_highscores:
		write_game_name += "_Global"

	# podam novi HS v json obliko
	var json_string = JSON.print(new_game_highscores)

	# če fileta ni, ga funkcija ustvari iz File.new()
	data_file.open("user://%s_highscores.save" % write_game_name, File.WRITE) # vsak game ma svoj filet

	# vnesem novi HS
	data_file.store_line(to_json(new_game_highscores))
	data_file.close()


func read_highscores_from_file(read_game_data: Dictionary, local_highscores: bool = false):
	# global HS filet ALI lokal HS filet ALI nov filet

	var read_game_name: String

	if Profiles.tilemap_paths[read_game_data["game"]].size() > 1:
		read_game_name = Profiles.Games.keys()[read_game_data["game"]] + "_" + read_game_data["level_name"]
	else:
		read_game_name = Profiles.Games.keys()[read_game_data["game"]]

	if not local_highscores:
		read_game_name += "_Global"

	# preverjam obstoj fileta ... ob prvem nalaganju igre
	var error = data_file.open("user://%s_highscores.save" % read_game_name, File.READ)
	if error != OK:
		# če iščem lokalnega in ga ni, naredim nov filet
		if local_highscores:
			data_file.open("user://%s_highscores.save" % read_game_name, File.WRITE)
			var default_highscores: Dictionary = _build_default_highscores()
			data_file.store_line(to_json(default_highscores))
			data_file.close()
		# če iščem globalnega in ga ni, probam z lokalnim
		else:
			if Profiles.tilemap_paths[read_game_data["game"]].size() > 1:
				read_game_name = Profiles.Games.keys()[read_game_data["game"]] + "_" + read_game_data["level_name"]
			else:
				read_game_name = Profiles.Games.keys()[read_game_data["game"]]
			var local_error = data_file.open("user://%s_highscores.save" % read_game_name, File.READ)
			# če tudi lokalnega ni, naredim nov lokalni filet
			if local_error != OK:
				data_file.open("user://%s_highscores.save" % read_game_name, File.WRITE)
				var default_highscores: Dictionary = _build_default_highscores()
				data_file.store_line(to_json(default_highscores))
				data_file.close()
	# odprem filet za branje
	data_file.open("user://%s_highscores.save" % read_game_name, File.READ)

	# prepiši podatke iz fileta v igro
	var current_game_highscores = parse_json(data_file.get_line())
	data_file.close()

	return current_game_highscores


# INSIDERS ---------------------------------------------------------------------------------------------------------------------------


func _check_player_ranking(current_score: float, local_highscores: Dictionary, current_game_data: Dictionary):

	var all_ranking_scores: Array = []
	var all_ranking_score_owners: Array = []
	# current_score_time je že zaokrožen na 2 decimalki

	# poberemo lestvico v arraye
	for hs_position_key in local_highscores:
		var current_position_dict = local_highscores[hs_position_key]
		all_ranking_scores += current_position_dict.values()
		all_ranking_score_owners += current_position_dict.keys()

	# izračun uvrstitve na lestvico ... preštejem pozicije pred plejerjem
	var better_positions_count: int = 0
	for ranking_score in all_ranking_scores:
		if current_game_data["highscore_type"] == Profiles.HighscoreTypes.TIME: # edinkrat ko se šteje nižje število
			if ranking_score <= current_score and not ranking_score <= 0:
				better_positions_count += 1
		else:
			if ranking_score > current_score:
				better_positions_count += 1

	var player_ranking: int = better_positions_count + 1 # za označitev linije na lestvici

	return player_ranking


func _build_default_highscores():

	var new_highscores: Dictionary
	var highscore_line_key_as_rank: String = "%03d" % (1)
	new_highscores[highscore_line_key_as_rank] = {Global.default_highscore_line_name: 0}

	return new_highscores
