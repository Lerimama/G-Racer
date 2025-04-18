extends HBoxContainer


var is_open: bool = false
var closed_position_offset: float = 500

onready var open_position: Vector2 = rect_position
onready var closed_position: Vector2# = rect_position + Vector2(0, closed_position_offset)
onready var home: Node = $"../.."


func _input(event: InputEvent) -> void:

	if is_open and Input.is_action_just_pressed("ui_cancel"):
		close()


func _ready() -> void:

	#pozicija

	if get_node("../LevelsOpenPosition") and get_node("../LevelsClosedPosition"):
		open_position = get_node("../LevelsOpenPosition").position
		closed_position = get_node("../LevelsClosedPosition").position
		closed_position_offset = closed_position.y - open_position.y
		var center_position_adapt: float = rect_size.x / 2
		open_position.x -= center_position_adapt
		closed_position.x -= center_position_adapt
	else:
		closed_position = rect_position + Vector2(0, closed_position_offset)

	rect_position = closed_position

	for btn in get_children():
		btn.connect("pressed", self, "_on_level_btn_pressed", [btn])
		# pressed
		var btn_index: int = get_children().find(btn)
		if btn_index in Sets.game_levels:
			btn.is_enabled = true
		else:
			btn.is_enabled = false


func open() -> void:

	if not is_open:
		is_open = true

		var slide_tween = get_tree().create_tween()
		slide_tween.tween_property(self, "rect_position", open_position, 0.2). set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		yield(slide_tween, "finished")

		# preverjam , če se je odprlo zaradi direktnega fokusiranja
		var allready_focused: bool = false
		for btn in get_children():
			if btn.has_focus():
				allready_focused = true
				break
		if not allready_focused:
			get_children()[0].grab_focus()


func close() -> void:

	if is_open:

		var slide_tween = get_tree().create_tween()
		slide_tween.tween_property(self, "rect_position", closed_position, 0.2). set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		yield(slide_tween, "finished")
#		focused_on_close.grab_focus()
		is_open = false
		home.to_main_menu()


func _on_level_btn_pressed(btn: Button):

	if is_open:
		var btn_index: int = get_children().find(btn)

		# _temp select one level only
		Sets.game_levels = [btn_index]
		for other_btn in get_children():
			if other_btn == btn:
				other_btn.is_enabled = true
			else:
				other_btn.is_enabled = false

	# turnir mode
	#	other_btn.is_enabled = not other_btn.is_enabled

	#	if btn_index in Sets.game_levels:
	#		Sets.game_levels.erase(btn_index)
	#	else:
	#		Sets.game_levels.append(btn_index)
