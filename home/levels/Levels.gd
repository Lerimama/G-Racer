extends Control


var is_open: bool = false
var focused_level_btn_index: int = 0 # da vem levo/desno
var selected_level_btns: Array = [] # referenca za game_levels on play()


onready var home: Node = $"../.."
onready var level_cards: HBoxContainer = $LevelCards
onready var default_level_menu_position: Vector2 = level_cards.rect_position
onready var selected_levels_label: Label = $SelectedLevels
onready var wins_limit_label: Label = $WinsLimit
onready var LevelCard: PackedScene = preload("res://home/levels/LevelCard.tscn")

# neu
onready var wins_limit_btn: Button = $WinsLimitBtn
var wins_needed_limit: int = 5
onready var easy_mode_btn: Button = $EasyModeBtn
onready var play_btn: Button = $Menu/PlayBtn
var easy_mode: bool = false


func _input(event: InputEvent) -> void:

	if is_open and Input.is_action_just_pressed("ui_cancel"):
		close()


func _ready() -> void:

	hide()

	_set_levels_menu()

	# btn states
	if Sets.easy_mode:
		easy_mode_btn.text = "EASY MODE ON    ... all players advance"
	else:
		easy_mode_btn.text = "EASY MODE OFF ... only qualified advance"
	if selected_level_btns.size() == 1:
		wins_limit_btn.text = "WINS NEEDED: %d    ... Single level tournament wins needed" % Sets.wins_needed
		wins_limit_btn.disabled = false
	else:
		wins_limit_btn.text = "WINS NEEDED only in single level mode"
		wins_limit_btn.disabled = true


func open(focus_btn_index: int = focused_level_btn_index):

	# empty data prevent ... lahko bi tudi auto prvi level select
	play_btn.grab_focus()

	is_open = true
	show()


func close():

	home.to_main_menu()
	is_open = false
	hide()


func _set_levels_menu() -> void: # tole gre na starša

	# debug reset
	for child in level_cards.get_children():
		child.queue_free()

	selected_levels_label.text = "SELECTED LEVELS: > "

	# spawn btns
	for level_value in Pros.LEVELS.values(): # po vrsti v LEVELS enum

		var new_level_btn: Button = LevelCard.instance()
		new_level_btn.level_profile = Pros.level_profiles[level_value]
		level_cards.add_child(new_level_btn)

		new_level_btn.connect("pressed", self, "_on_level_btn_pressed", [new_level_btn])
		new_level_btn.connect("focus_entered", self, "_on_level_btn_focused", [new_level_btn])

		var level_value_index: int = Pros.LEVELS.values().find(level_value)
		if level_value_index in Sets.game_levels:
			new_level_btn.is_selected = true
			selected_level_btns.append(new_level_btn)
			# lista
			selected_levels_label.text += new_level_btn.level_profile["level_name"]
			if level_value_index < selected_level_btns.size() - 1:
				selected_levels_label.text += " . "


func _on_level_btn_pressed(btn: Button):

	if btn in selected_level_btns:
		selected_level_btns.erase(btn)
		btn.is_selected = false
	else:
		selected_level_btns.append(btn)
		btn.is_selected = true

	# lista
	selected_levels_label.text = "SELECTED LEVELS > "
	for selected_btn in selected_level_btns:
		selected_levels_label.text += selected_btn.level_profile["level_name"]
		if selected_level_btns.find(selected_btn) < selected_level_btns.size() - 1:
			selected_levels_label.text += " . "

	# izberi prvega, če ni izbran noben
	if selected_level_btns.empty():
		_on_level_btn_pressed(level_cards.get_child(0))
		_on_level_btn_focused(level_cards.get_child(0))
		var slide_to_start_tween = get_tree().create_tween()
		slide_to_start_tween.tween_property(level_cards, "rect_position:x", default_level_menu_position.x, 0.32).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)


func _on_level_btn_focused(btn: Button):

	btn.focused_display.show()
	btn.level_preview.show()

	# levo/desno premikam, če je index večji od limite in ni zadnji
	var slide_on_index: int = 3
	var new_focused_btn_index: int = level_cards.get_children().find(btn)
	var right_edge_margin_adapt: int = 136

	if new_focused_btn_index >= slide_on_index and new_focused_btn_index < level_cards.get_child_count() - 1:
		if new_focused_btn_index == slide_on_index:
			right_edge_margin_adapt = 0
		var slide_distance: float = (new_focused_btn_index - slide_on_index) * (btn.rect_size.x + level_cards.get_constant("hseparation"))
		var slide_tween = get_tree().create_tween()
		slide_tween.tween_property(level_cards, "rect_position:x", default_level_menu_position.x - slide_distance - right_edge_margin_adapt, 0.32).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)


func _on_BackBtn_pressed() -> void:

	close()


func _on_PlayBtn_pressed() -> void:

	home.play_game()


func _on_DriversBtn_pressed() -> void:
	# _temp ... cross home screens btns

	close() # zaenkrat more bit tukej
	home._on_PlayersBtn_pressed()


func _on_WinsLimit_pressed() -> void:

	Sets.wins_needed += 1

	if Sets.wins_needed > wins_needed_limit:
		Sets.wins_needed = 0

	wins_limit_btn.text = "WINS NEEDED: %d    ... Single level tournament wins needed" % Sets.wins_needed


func _on_EasyModeBtn_pressed() -> void:

	Sets.easy_mode = not Sets.easy_mode

	if Sets.easy_mode:
		easy_mode_btn.text = "EASY MODE ON    ... all players advance"
	else:
		easy_mode_btn.text = "EASY MODE OFF ... only qualified advance"
