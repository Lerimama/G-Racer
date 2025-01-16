extends Node2D


signal http_post_request_done # ne dela
signal session_saved

var session_tracking: bool = false # za preprečit prekrivanje ukazov
var game_tracking: bool = false # za preprečit prekrivanje ukazov

var btns_clicked: Array = []
var games_played: Array = []
var session_data: Dictionary = {
	"sheet_name": "SESSION_DATA", # case INsensitive
	"session_id": 0, # na prvi sejv od ApiScripta
	"device_id": "ABC",
	"session_date": "01/12/2024",
	"session_time": "00:00:00",
	"os_name": "OS",
	"os_language": "nn",
	"ui_clicks": "", # on click
	"session_length": 0, # secs ... on session end
	"games_played_count": 0, # on ready
	"games_finished_count": 0, # on GO
	"total_playing_time": 0,
	"games_played": "",
	# _temp
	"current_game_data": {"dede": 0},
}
var def_game_data: Dictionary = { # ime ob zaprtju spremeni v številko in doda v games_played
	"sheet_name": "game_data",
	"game_name": "",
	"game_started": false,
	"game_played": false,
	"game_finished": false,
	"stray_count": 0,
	"playing_time": 0, # če je 0 je prehitro končana igra
}

var current_game_data: Dictionary = def_game_data

# api
var sheetbook_id: String = "1KfrvMCaqh65EGN_YEUrck8RyKGVbEUERathC6_VnRLQ" # link string
var app_url: String = "https://script.google.com/macros/s/AKfycbzh4UlcCgQ3pOBDE-uQJW8WRtWV-uB4OMKEq06v9uebj2o2xVzVzMY8CwrGL4BR1b1Edg/exec"
var script_action_new_row: String = "create_new_row"
var script_action_save_row: String = "save_existing_row"
var script_action_get_rows_list: String = "fetch_rows_list"


# on load game
func start_new_session(): # kliče main ... pošlje podatke na Gsheet

	if Profiles.analytics_mode and not session_tracking:
		#		print("> starting new session")
		session_tracking = true
		var date_dict: Dictionary = Time.get_date_dict_from_system()
		var date_string: String = str(date_dict["day"]) + "/" + str(date_dict["month"]) + "/" + str(date_dict["year"])
		session_data["session_date"] = date_string
		session_data["session_time"] = Time.get_time_string_from_system()
		if Profiles.html5_mode:
			session_data["device_id"] = "html"
		else:
			session_data["device_id"] = OS.get_unique_id()
		session_data["os_language"] = OS.get_locale_language()
		session_data["os_name"] = OS.get_name()
		_save_new_row()
	elif session_tracking:
		session_tracking = false
		call_deferred("start_new_session")


# on scene change
func update_session(): # pošlje podatke na Gsheet
#	print("update_session")

	if Profiles.analytics_mode and session_tracking:
		#		print("> updating session")
		session_data["current_game_data"] = current_game_data
		_save_existing_row(session_data["session_id"])


# on quit game
func end_session(): # kliče main ... pošlje podatke na Gsheet
#	print("end_session")

	if Profiles.analytics_mode and session_tracking:
		#		print("> ending session")
		session_data["session_length"] = round(Time.get_ticks_msec() / 1000)
		_save_existing_row(session_data["session_id"])
		session_tracking = false


func save_selected_game_data(game_parameter = null): # parameter je lahko ime igre, končano/nekončano
#	print("save_selected_game_data")

	# error Jason parse 0
	# trenutno se funkcija kliče samo ob stisku game/level batna in na GM set_game()
	if Profiles.analytics_mode:

		match typeof(game_parameter):
			TYPE_STRING: # game started ... save and update
				# select games btnz
				# select sweeper level btns
				# restart main reload > pred game_in
				if not game_tracking:
					game_tracking = true
					 # reset
					session_data["games_played_count"] += 1
					current_game_data["game_name"] = game_parameter
					current_game_data["game_started"] = true
					update_session() #... povzorča json parse error
			TYPE_NIL: # game played ... save to dict
				# GM pre hud.slidein
				if game_tracking:
					current_game_data["playing_time"] = Time.get_ticks_msec() / 1000
					current_game_data["game_played"] = true
			TYPE_ARRAY: # game finished ... save and update
				# game over na open
				# pause restart, quit
				if game_tracking:
					session_data["total_playing_time"] += current_game_data["playing_time"]
					# game
					var game_start_time: int = current_game_data["playing_time"]
					current_game_data["playing_time"] = Time.get_ticks_msec() / 1000 - game_start_time
					current_game_data["stray_count"] =  game_parameter[1]
					var game_finished: bool = game_parameter[0]
					if game_finished == true:
						session_data["games_finished_count"] += 1
						current_game_data["game_finished"] = true

					session_data["games_played"] += current_game_data["game_name"]
					session_data["games_played"] += " - Fin " + str(current_game_data["game_finished"])
					session_data["games_played"] += ", Strays " + str(current_game_data["stray_count"])
					session_data["games_played"] +=", Time " + str(current_game_data["playing_time"]) + "s"
					session_data["games_played"] +="\n"

					update_session()
					game_tracking = false


func save_ui_click(ui_action):
	# podatki se nabirajo iz ui gumbov (global), keyboard input
	# specials: intro, home ESC keyboard input, settings volume slider, GO name_input & publish
#	print("save_ui_click")

	if Profiles.analytics_mode:

		var save_string: String
		match typeof(ui_action):
			TYPE_STRING: # key input
				save_string = ui_action
			TYPE_OBJECT: # btn
				save_string = ui_action.name
			TYPE_ARRAY: # toggle/slider >  btn in bool/value
				#				print(ui_action)
				var btn_name: String = ui_action[0].name
				var btn_bool = ui_action[1]
				save_string = btn_name + " " + str(btn_bool)

		if session_data["ui_clicks"] == "":
			session_data["ui_clicks"] += save_string
		session_data["ui_clicks"] +=" > " + save_string
		#	printt("ui_clicks", session_data["ui_clicks"])
		btns_clicked.append(save_string)


# ROW ACTIONS --------------------------------------------------------------------------------------------------


func _save_new_row() -> void: # id se seta v tabeli

	_write_row_content(script_action_new_row)
	yield(self, "session_saved")
	_read_row_list() # da dobim ID (zadnje) sejvane vrstice ... list.size() - 1


func _save_existing_row(row_id: int) -> void:

	_write_row_content(script_action_save_row, row_id)


# API SCRIPT CALL ---------------------------------------------------------------------------------------------


func _read_row_list() -> void:

	_make_http_GET_request(script_action_get_rows_list)


func _write_row_content(action: String, id = null) -> void:

	if id: # id rabim samo za apdejt ... nov filet dobi ID od gugla
		session_data["session_id"] = id

	#	print("write game data ", current_game_data)
	#	print("write session data ", session_data)

	_make_http_POST_request(action, session_data)
	yield(get_tree().create_timer(1), "timeout")
	#	yield(self, "http_post_request_done") # OPT ...post signal ne dela
	emit_signal("session_saved")


# HTTP REQUESTS ---------------------------------------------------------------------------------------------


func _make_http_GET_request(endpoint: String, params: Dictionary = {}) -> void: # Make a GET request to the API ... endpoint je akcija

	var url = app_url + "?action=" + endpoint
	for key in params.keys():
		url += "&" + key + "=" + str(params[key])

	#	printt("http_GET_request: ", url)

	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_on_request_completed")
	# zakaj ni take oblike ... request.request(url, ["Content-Type: application/json"], false, HTTPClient.METHOD_GET)
	request.request(url)


func _make_http_POST_request(endpoint: String, data: Dictionary) -> void: # Make a POST request to the API

	var url = app_url + "?action=" + endpoint
	var json_data = JSON.print(data)

	#	printt("http_POST_request: ", url)

	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_on_request_completed")
	var headers = ["Content-Type: application/json"]
	request.request(url, headers, true, HTTPClient.METHOD_POST, json_data)

	emit_signal("http_post_request_done") # ... ne dela
	#	print ("emit signal > http_post_request_done")


func _on_request_completed(result, response_code, headers, body) -> void: # Handles the request completion

	if response_code == 200:
		var res = body.get_string_from_utf8()
		var json_result = JSON.parse(res).result

		if json_result:
			var returned_data = json_result
			# preverim id trenutne seanse na google tabeli (last row id)
			var current_row_index = returned_data.size() - 1
			var current_session_id: int = returned_data[current_row_index]["session_id"]
			session_data["session_id"] = current_session_id
			#			print("OK! _on_request_completed")
			#			print("New session id: ", session_data["session_id"] )
		else:
			print("Error! JSON parse", res)
			#			print("Result UTF8: ", res)
	else:
		print("Error! _on_request_completed: ", response_code)
		#		if response_code != 405:
		#			print("Response code: ", response_code)
		#			print("Result: ", result)
		#			print("Headers: ", headers.size())
		#			#		print("Bs", body)

	#	print("--- request end ---")
