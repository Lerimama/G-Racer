extends VBoxContainer


var editing_player_btn: Button
var selected_player_names: Dictionary = {}
onready var player_popup: PopupDialog = $"../PlayerPopup"


func _set_btn_display(btn: Button, is_on: bool):

	btn.get_node("Edge").visible = is_on


func _ready() -> void:

	player_popup.connect("input_finished", self, "_on_name_input_finished")

	for btn in get_children():

		btn.connect("pressed", self, "_on_player_btn_pressed", [btn])

		# pressed?
		var btn_index: int = get_children().find(btn)
		var driver_index_among_drivers: int = btn_index
		if driver_index_among_drivers in Sts.players_on_game_start:
			if not btn in selected_player_names:
				selected_player_names[btn] = btn.text
			_set_btn_display(btn, true)
		else:
			_set_btn_display(btn, false)


func _on_name_input_finished(new_name_text: String):

	# dissabled
	if new_name_text == "":
		selected_player_names.erase(editing_player_btn)
		_set_btn_display(editing_player_btn, false)
	# enabled
	elif new_name_text == editing_player_btn.text:
		pass
	else:
		editing_player_btn.text = new_name_text.to_upper()
		if not editing_player_btn in selected_player_names:
			selected_player_names[editing_player_btn] = new_name_text
		_set_btn_display(editing_player_btn, true)

	_set_activated_players()


func _set_activated_players():

	for btn_index in get_child_count():
		var btn: Button = get_children()[btn_index]
		if btn in selected_player_names:
			if not btn_index in Sts.players_on_game_start:
				Sts.players_on_game_start.append(btn_index)
		else:
			Sts.players_on_game_start.erase(btn_index)

		Pfs.driver_profiles[btn_index]["driver_name"] = btn.text

	printt ("selected_player_names", Sts.players_on_game_start)


func _on_player_btn_pressed(btn: Button):

	var btn_index: int = get_children().find(btn)

	player_popup.text_on_open = btn.text
	player_popup.color_on_open = Pfs.driver_profiles[btn_index]["driver_color"]
	player_popup.popup_centered()
	editing_player_btn = btn
