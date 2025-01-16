extends HTTPRequest

signal guest_authenticated # zase
signal leaderboard_updated # pove kdaj je konec celotnega procesa "apdejtanja"
signal connection_closed # pove kdaj je konec celotnega procesa "apdejtanja"
signal unpublished_score_published # na vrsti je naslednji score

var player_id: String # setam pred avtentikacijo
var session_token: String # dobim ob avtentikaciji
var lootlocker_leaderboard: Array
var guest_is_authenticated: bool = false
var anonymous_guest_name: String = "anonymous" # ko čekiraš HS v home
var final_panel_open_time: float = 1
var multipublish_count: int = 0	# da ve kdaj je prvi in ga avtenticira ...
var random_id_length: int = 10
var random_id_delimiter: String = "_#"

# game data
var lootlocker_live_mode: bool = true
var lootlocker_game_key_staging: String = "dev_5a1cab01df0641c0a5f76450761ce292"
var lootlocker_game_key_live: String = "prod_b0c04c071a114b35b9c38157e86de64c"
var lootlocker_game_version: String = "0.93"
var lootlocker_score_check_limit: int = 200 # če bi blo več, ne paše na %02d


func _ready() -> void:

	timeout = 5.0 # ker je autoload mu ne moram settat settingsih


func publish_score_to_lootlocker(player_name: String, player_score: float, game_data: Dictionary): # ko objaviš nov skor z novim imenom, se je potrebno pononvno povezat

	guest_is_authenticated = false

	var game_leaderboard_key = Profiles.Games.keys()[game_data["game"]]
	if Profiles.tilemap_paths[game_data["game"]].size() > 1:
		game_leaderboard_key = Profiles.Games.keys()[game_data["game"]] + "_" + game_data["level_name"]

	_authenticate_guest_session(player_name, true)
	yield(self, "guest_authenticated")

	ConnectCover.cover_label_text = "Publishing ..."

	var url: String = "https://api.lootlocker.io/game/leaderboards/%s/submit" % game_leaderboard_key
	var header: Array = ["Content-Type: application/json", "x-session-token: %s" % session_token]
	var method = HTTPClient.METHOD_POST
	var request_data: Dictionary = {
		"score": player_score,
		"member_id": player_id, # player ID je ime opredeljeno pred avtentikacijo
	}

	request(url, header,false, method, to_json(request_data))
	# čakam na odgovor od lootlockerja ... zato dam yield
	yield(self, "request_completed")

	update_lootlocker_leaderboard(game_data)


func multipublish_scores_to_lootlocker(player_name: String, player_score: float, game_data: Dictionary, last_in_row: bool = false): # ko objaviš nov skor z novim imenom, se je potrebno pononvno povezat

	multipublish_count += 1
	guest_is_authenticated = false

	var game_leaderboard_key = Profiles.Games.keys()[game_data["game"]]
	if Profiles.tilemap_paths[game_data["game"]].size() > 1:
		game_leaderboard_key = Profiles.Games.keys()[game_data["game"]] + "_" + game_data["level_name"]

	if multipublish_count == 1: # avtenticiram na ime prvega rezultata v vrsti
		_authenticate_guest_session(player_name, true)
		yield(self, "guest_authenticated")

	ConnectCover.cover_label_text = "Publishing score %s" % str(multipublish_count)

	var url: String = "https://api.lootlocker.io/game/leaderboards/%s/submit" % game_leaderboard_key
	var header: Array = ["Content-Type: application/json", "x-session-token: %s" % session_token]
	var method = HTTPClient.METHOD_POST
	var request_data: Dictionary = {
		"score": player_score,
		"member_id": player_name, # player ID je ime opredeljeno pred avtentikacijo
		#		"member_id": player_id, # player ID je ime opredeljeno pred avtentikacijo
	}

	request(url, header,false, method, to_json(request_data))
	# čakam na odgovor od lootlockerja ... zato dam yield
	yield(self, "request_completed")

	if last_in_row:
		multipublish_count = 0

	emit_signal("unpublished_score_published")


func update_lootlocker_leaderboard(game_data: Dictionary, last_in_row: bool = true, update_string: String = "", update_in_background: bool = false):

	if not guest_is_authenticated:
		_authenticate_guest_session(anonymous_guest_name, last_in_row, update_in_background)
		yield(self, "guest_authenticated")
	else:
		ConnectCover.open_cover(update_in_background)


	ConnectCover.cover_label_text = "Updating " + update_string

	var game_leaderboard_key: String = Profiles.Games.keys()[game_data["game"]]
	if Profiles.tilemap_paths[game_data["game"]].size() > 1:
		game_leaderboard_key = Profiles.Games.keys()[game_data["game"]] + "_" + game_data["level_name"]

	var url_without_count: String = "https://api.lootlocker.io/game/leaderboards/%s/list?count=" % game_leaderboard_key
	var url: String = url_without_count + str(lootlocker_score_check_limit)
	var header: Array = ["Content-Type: application/json", "x-session-token: %s" % session_token]
	var method = HTTPClient.METHOD_GET

	request(url, header, false, method)

	# čakam ... get method ... convert body to string
	var response = yield(self, "request_completed")[3]
	response = JSON.parse(response.get_string_from_utf8()).result # dobimo session token key

	if response == null:
		if last_in_row:
			_on_connection_failed(last_in_row)
	else:
		if "items" in response:
			if response["items"] == null: # če v tabeli ni items arraya, generiram enega fejk
				var item: Dictionary = {"member_id": "No score", "rank": 1,"score": 0,}
				response["items"] = [item]
			lootlocker_leaderboard = response["items"]

		_save_lootlocker_leaderboard_to_local_highscore(game_data)

		# printt ("Leaderboard updated (get,save)", game_leaderboard_key)

		if last_in_row:
			emit_signal("connection_closed")
		else:
			emit_signal("leaderboard_updated")


func _save_lootlocker_leaderboard_to_local_highscore(game_data: Dictionary):

	# spremenim board v HS slovar
	var global_game_highscores: Dictionary = {}
	var new_leaderboard: Array = lootlocker_leaderboard # Dictionary ali object

	for item in new_leaderboard:
		# poberem podatke iz borda
		var item_dictionary: Dictionary = item
		# ločim random id string, ki sem ga uporabil ob sejvanju imena
		# če je string brez delimiterja, potem uporabi cel string (to se na koncu ne bo več odgajalo)
		var item_player_name_with_random_string: String = item_dictionary["member_id"]
		var item_player_name: String = item_player_name_with_random_string.get_slice(random_id_delimiter, 0) # slajsa ob indexu prve črke delimiterja
		var item_player_score = item_dictionary["score"]
		var item_player_rank = "%03d" % item_dictionary["rank"]
		# zapišem v obliko kokalnih HS
		var highscores_player_name: String = str(item_player_name)
		var highscores_player_line: Dictionary
		highscores_player_line[highscores_player_name] = item_player_score
		# add player dict to higscores dict
		global_game_highscores[item_player_rank] = highscores_player_line

	# dodam level name za ime save fileta in sejvam
	Data.write_highscores_to_file(game_data, global_game_highscores)


func _authenticate_guest_session(player_name: String, last_attempt_in_row: bool, update_in_background: bool = false):

	ConnectCover.cover_label_text = "Connecting ..."
	ConnectCover.open_cover(update_in_background)


	player_id = player_name
	# dodam random id string, ki sem ga uporabil ob sejvanju imena
	player_id += random_id_delimiter + Global.generate_random_string(10)

	# authenticate guest session
	var url: String = "https://api.lootlocker.io/game/v2/session/guest"
	var header: Array = ["Content-Type: application/json"]
	var method = HTTPClient.METHOD_POST
	var lootlocker_game_key: String = lootlocker_game_key_staging
	if lootlocker_live_mode:
		lootlocker_game_key = lootlocker_game_key_live

	var request_body: Dictionary = {
		"game_key": lootlocker_game_key,
		"game_version": lootlocker_game_version,
		"player_identifier": player_id, # če je prazen je samo random id (se ne zgodi, ker se prazen input tretira kot esc)
	}
	request(url, header, false, method, to_json(request_body))

	# čakam na odgovor od lootlockerja ... zato dam yield
	var response = yield(self, "request_completed")[3]
	response = JSON.parse(response.get_string_from_utf8()).result # dobimo session token key

	# CONNECTION FAILED
	if response == null or not "session_token" in response:
		_on_connection_failed(last_attempt_in_row)
	# CONNECTED
	else:
		session_token = response["session_token"]
		ConnectCover.cover_label_text = "Connected to server"
		yield(get_tree().create_timer(final_panel_open_time), "timeout")
		guest_is_authenticated = true
		emit_signal("guest_authenticated")


func _on_connection_failed(last_attempt_in_row: bool):

	printt("Connection failed:", last_attempt_in_row)
	if last_attempt_in_row:
		ConnectCover.cover_label_text = "Connecting failed" # tukaj zato, da prepiše tekst pozitivne reštve
		yield(get_tree().create_timer(final_panel_open_time), "timeout")
		emit_signal("connection_closed")
	else:
		emit_signal("leaderboard_updated")
