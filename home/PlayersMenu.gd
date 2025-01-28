extends HBoxContainer


func _ready() -> void:

	for child in get_children():
		if not child is Label:
			var btn: Button = child
			btn.connect("toggled", self, "_on_player_btn_toggled", [btn])
			# pressed
			var btn_index: int = get_children().find(btn)
			var driver_index_among_drivers: int = btn_index
			if driver_index_among_drivers in Sts.players_on_game_start:
				btn.pressed = true
			else:
				btn.pressed = false


func _on_player_btn_toggled(is_pressed: bool, pressed_btn: Button):

	var btn_index: int = get_children().find(pressed_btn)
	var player_key_from_index: int = btn_index # zaporedje v profilih je pomembno

	if is_pressed:
		if not player_key_from_index in Sts.players_on_game_start:
			Sts.players_on_game_start.append(player_key_from_index)
	else:
		Sts.players_on_game_start.erase(player_key_from_index)

	print(Sts.players_on_game_start)
