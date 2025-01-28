tool
extends HBoxContainer

export var krneki : String = ""



func _ready() -> void:

	for btn in get_children():
		btn.connect("toggled", self, "_on_level_btn_toggled", [btn])
		# pressed
		var btn_index: int = get_children().find(btn)
		var level_index_among_levels: int = btn_index
		if level_index_among_levels in Sts.current_game_levels:
			btn.pressed = true
		else:
			btn.pressed = false


func _process(delta: float) -> void:

	$LevelBtn/Label.text = krneki


func _on_level_btn_toggled(is_pressed: bool, pressed_btn: Button):

	var btn_index: int = get_children().find(pressed_btn)
	var level_key_index: int = btn_index # zaporedje v profilih je pomembno

	if is_pressed:
		if not level_key_index in Sts.current_game_levels:
			Sts.current_game_levels.append(level_key_index)
	else:
		Sts.current_game_levels.erase(level_key_index)
	print(Sts.current_game_levels)

