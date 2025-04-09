extends Control


var is_open: bool = false
var focused_level_card_index: int = 0 # da vem levo/desno
var selected_level_cards: Array = [] # referenca za game_levels on play()
var level_keys_with_cards: Dictionary = {}
var visible_level_cards: Array = [] # za filter in adaptacijo skrolanja

onready var home: Node = $"../.."
onready var level_cards: HBoxContainer = $LevelCards
onready var def_level_menu_position: Vector2 = level_cards.rect_position
onready var selected_levels_label: Label = $SelectedLevels
onready var LevelCard: PackedScene = preload("res://home/levels/LevelCard.tscn")

# neu
onready var easy_mode_btn: Button = $EasyModeBtn
onready var play_btn: Button = $Menu/PlayBtn
var easy_mode: bool = false
onready var level_filter: HBoxContainer = $LevelFilter


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


func open():

	# empty data prevent ... lahko bi tudi auto prvi level select
	level_cards.get_child(0).grab_focus()
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
	var all_levels: Array = []
	all_levels.append(Levs.LEVEL.TESTER)
	all_levels.append_array(Levs.training_levels)
	all_levels.append_array(Levs.racing_levels)
	all_levels.append_array(Levs.battle_levels)
	all_levels.append_array(Levs.goal_levels)
	all_levels.append_array(Levs.mission_levels)

	for level in Levs.level_profiles: # po vrsti v LEVELS enum

		var new_level_card: Button = LevelCard.instance()
		new_level_card.level_profile = Levs.level_profiles[level]
		level_cards.add_child(new_level_card)

		level_keys_with_cards[level] = new_level_card
		visible_level_cards.append(level_cards)

		new_level_card.connect("pressed", self, "_on_level_btn_pressed", [new_level_card])
		new_level_card.connect("focus_entered", self, "_on_level_btn_focused", [new_level_card])

		var level_value_index: int = all_levels.find(level)
		if level_value_index in Sets.game_levels:
			new_level_card.is_selected = true
			selected_level_cards.append(new_level_card)
			# lista
			selected_levels_label.text += new_level_card.level_profile["level_name"]
			if level_value_index < selected_level_cards.size() - 1:
				selected_levels_label.text += " . "

		if "done" in Levs.level_profiles[level]:
			new_level_card._enabled_panel.show()
		else:
			new_level_card._enabled_panel.hide()


	for filter_btn in level_filter.get_children():
		if not filter_btn.is_connected("toggled", self, "_on_filter_btn_toggled"):
			filter_btn.connect("toggled", self, "_on_filter_btn_toggled", [filter_btn])

	level_filter.get_child(0).text += " (%d)" % all_levels.size()
	level_filter.get_child(1).text += " (%d)" % Levs.training_levels.size()
	level_filter.get_child(2).text += " (%d)" % (Levs.racing_levels.size() + Levs.goal_levels.size())
	level_filter.get_child(3).text += " (%d)" % Levs.battle_levels.size()
	level_filter.get_child(4).text += " (%d)" % Levs.mission_levels.size()
#	_on_filter_btn_toggled(true, level_filter.get_child(0))


# SIGNALI ------------------------------------------------------------------------------


func _on_filter_btn_toggled(pressed: bool, pressed_filter_btn: Button):

	visible_level_cards.clear()

	# odtoglam ostale
	for btn in  level_filter.get_children():
		if not btn == pressed_filter_btn:
			btn.set_pressed_no_signal(false)

	var pressed_btn_index: int = level_filter.get_children().find(pressed_filter_btn)
	for level_card in level_keys_with_cards.values():
		match pressed_btn_index:
			0: # all
				level_card.show()
			1: # training
				var level_key: int = level_keys_with_cards.find_key(level_card)
				if level_key in Levs.training_levels:
					level_card.show()
				else:
					level_card.hide()
			2: # racing + goals
				var level_key: int = level_keys_with_cards.find_key(level_card)
				if level_key in Levs.racing_levels or level_key in Levs.goal_levels:
					level_card.show()
				else:
					level_card.hide()
			3: # battle
				var level_key: int = level_keys_with_cards.find_key(level_card)
				if level_key in Levs.battle_levels:
					level_card.show()
				else:
					level_card.hide()
			4: # missions
				var level_key: int = level_keys_with_cards.find_key(level_card)
				if level_key in Levs.mission_levels:
					level_card.show()
				else:
					level_card.hide()

	for card in level_cards.get_children():
		if card.visible:
			visible_level_cards.append(card)


func _on_level_btn_pressed(pressed_card: Button):

	# toggle pressed
	if pressed_card in selected_level_cards:
		selected_level_cards.erase(pressed_card)
		pressed_card.is_selected = false
	else:
		if not pressed_card in selected_level_cards:
			selected_level_cards.append(pressed_card)
		pressed_card.is_selected = true

	# lista levelov
	selected_levels_label.text = "SELECTED LEVELS > "
	for selected_btn in selected_level_cards:
		selected_levels_label.text += selected_btn.level_profile["level_name"]
		if selected_level_cards.find(selected_btn) < selected_level_cards.size() - 1:
			selected_levels_label.text += " . "

	# izberi prvega, če ni izbran noben
	if selected_level_cards.empty():
		_on_level_btn_pressed(level_cards.get_child(0))
		var slide_to_start_tween = get_tree().create_tween()
		slide_to_start_tween.tween_property(level_cards, "rect_position:x", def_level_menu_position.x, 0.32).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		if not pressed_card in selected_level_cards:
			selected_level_cards.append(pressed_card)
	# ime play gumba
	if selected_level_cards.size() == 1:
		play_btn.text = "PLAY"
	else:
		play_btn.text = "PLAY TOURNAMENT"


func _on_level_btn_focused(btn: Button):

	btn.focused_display.show()
	btn.level_preview.show()

	# slide
	var sliding_on_card_index: int = 3
	var next_focused_card_index: int = visible_level_cards.find(btn)
	var right_edge_margin: int = 136
	var scroll_time: float = 0.32
	# slajdam, če je next_card večji od limite in ni zadnji
	if next_focused_card_index >= sliding_on_card_index and next_focused_card_index < visible_level_cards.size() - 1:
		# edge margin glede na ali je zadnji ali ne
		if next_focused_card_index == sliding_on_card_index:
			right_edge_margin = 0
		# slide
		var slide_distance: float = (next_focused_card_index - sliding_on_card_index) * (btn.rect_size.x + level_cards.get_constant("hseparation"))
		var slide_tween = get_tree().create_tween()
		slide_tween.tween_property(level_cards, "rect_position:x", def_level_menu_position.x - slide_distance - right_edge_margin,scroll_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)


#func _on_level_btn_focused_old(btn: Button):
#
#	btn.focused_display.show()
#	btn.level_preview.show()
#
#	# slide
#	var sliding_on_card_index: int = 3
#	var next_focused_card_index: int = level_cards.get_children().find(btn)
#	var right_edge_margin: int = 136
#	var scroll_time: float = 0.32
#	# slajdam, če je next_card večji od limite in ni zadnji
#	if next_focused_card_index >= sliding_on_card_index and next_focused_card_index < level_cards.get_child_count() - 1:
#		# edge margin glede na ali je zadnji ali ne
#		if next_focused_card_index == sliding_on_card_index:
#			right_edge_margin = 0
#		# slide
#		var slide_distance: float = (next_focused_card_index - sliding_on_card_index) * (btn.rect_size.x + level_cards.get_constant("hseparation"))
#		var slide_tween = get_tree().create_tween()
#		slide_tween.tween_property(level_cards, "rect_position:x", def_level_menu_position.x - slide_distance - right_edge_margin,scroll_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)


func _on_BackBtn_pressed() -> void:

	close()


func _on_PlayBtn_pressed() -> void:
	# oneshot

	home.play_game()


func _on_DriversBtn_pressed() -> void:
	# _temp ... cross home screens btns

	close() # zaenkrat more bit tukej
	home._on_PlayersBtn_pressed()


func _on_EasyModeBtn_pressed() -> void:

	Sets.easy_mode = not Sets.easy_mode

	if Sets.easy_mode:
		easy_mode_btn.text = "EASY MODE ON    ... all players advance"
	else:
		easy_mode_btn.text = "EASY MODE OFF ... only qualified advance"
