extends VBoxContainer


var on_btn_color: Color = Color("#f2e4c4")
var off_btn_color: Color = Color("#f92c00")
var editing_player_btn: Button
var selected_player_names: Dictionary = {}

onready var player_popup: PopupDialog = $"../PlayerPopup"



func _ready() -> void:

	player_popup.connect("input_finished", self, "_on_name_input_finished")

	for btn in get_children():

		btn.connect("pressed", self, "_on_player_btn_pressed", [btn])
		btn.connect("focus_entered", self, "_on_focus_entered", [btn])
		btn.connect("focus_exited", self, "_on_focus_exited", [btn])

		_set_btn_display(btn)



func _on_name_input_finished(new_name_text: String, player_activated: bool):

	if player_activated:
		editing_player_btn.text = new_name_text.to_upper()
		if not editing_player_btn in selected_player_names:
			selected_player_names[editing_player_btn] = new_name_text
		_set_btn_display(editing_player_btn, true)
	else:
		selected_player_names.erase(editing_player_btn)
		_set_btn_display(editing_player_btn, false)

	# set_activated_players
	for btn_index in get_child_count():
		var btn: Button = get_children()[btn_index]
		if btn in selected_player_names:
			if not btn_index in Sts.players_on_game_start:
				Sts.players_on_game_start.append(btn_index)
		else:
			Sts.players_on_game_start.erase(btn_index)

		Pfs.driver_profiles[btn_index]["driver_name"] = btn.text


func _set_btn_display(btn: Button, turned_on = null):

	var btn_index: int = get_children().find(btn)

	if turned_on == null:
		if btn_index in Sts.players_on_game_start:
			if not btn in selected_player_names:
				selected_player_names[btn] = btn.text
			btn.modulate = on_btn_color
			btn.icon = Pfs.driver_profiles[btn_index]["driver_avatar"]
		else:
			btn.icon = Pfs.ai_profile["ai_avatar"]
			btn.modulate = off_btn_color
	else:
		if turned_on == true:
			btn.modulate = on_btn_color
			btn.icon = Pfs.driver_profiles[btn_index]["driver_avatar"]
		else:
			btn.icon = Pfs.ai_profile["ai_avatar"]
			btn.modulate = off_btn_color


func _on_player_btn_pressed(btn: Button):
	print("PRESS")

	var btn_index: int = get_children().find(btn)

	if Sts.players_on_game_start.has(btn_index):
		player_popup.is_activated = true
	else:
		player_popup.is_activated = false

	player_popup.player_id = btn_index
	player_popup.driver_name = btn.text
	player_popup.driver_avatar_texture = Pfs.driver_profiles[btn_index]["driver_avatar"]
	player_popup.driver_color = Pfs.driver_profiles[btn_index]["driver_color"]
	player_popup.driver_controller_type = Pfs.driver_profiles[btn_index]["controller_type"]

	player_popup.popup_centered()
	editing_player_btn = btn


func _on_focus_entered(btn: Button):

	print("FOC")
	btn.modulate = Color.white


func _on_focus_exited(btn: Button):

	_set_btn_display(btn)


