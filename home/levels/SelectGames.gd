extends Control


var wins_limit: int = 3
var is_open: bool = false
var focused_level_btn_index: int = 0 # da vem levo/desno
var selected_level_btns: Array = []


onready var home: Node = $"../.."
onready var level_menu: HBoxContainer = $LevelMenu
onready var default_level_menu_position: Vector2 = level_menu.rect_position
onready var selected_levels_label: Label = $SelectedLevels
onready var wins_limit_label: Label = $WinsLimit
onready var LevelBtn: PackedScene = preload("res://home/levels/LevelBtn.tscn")


func _input(event: InputEvent) -> void:

	if is_open and Input.is_action_just_pressed("ui_cancel"):
		close()


func _ready() -> void:

	_set_levels_menu()
	print("game_levels", Sets.game_levels)
	hide()


func open(focus_btn_index: int = focused_level_btn_index):
	level_menu.get_child(focus_btn_index).grab_focus()
	is_open = true
	show()


func close():

	home.to_main_menu()
	is_open = false
	hide()


func _set_levels_menu() -> void: # tole gre na starša

	# debug reset
	for child in level_menu.get_children():
		child.queue_free()

	# spawn btns
	for level_value in Pros.LEVELS.values(): # po vrsti v LEVELS enum

		var new_level_btn: Button = LevelBtn.instance()
		new_level_btn.level_profile = Pros.level_profiles[level_value]
		level_menu.add_child(new_level_btn)

		new_level_btn.connect("pressed", self, "_on_level_btn_pressed", [new_level_btn])
		new_level_btn.connect("focus_entered", self, "_on_level_btn_focused", [new_level_btn])

		if Pros.LEVELS.values().find(level_value) in Sets.game_levels:
			new_level_btn.is_selected = true
			prints("SEL", Pros.level_profiles[level_value]["level_name"])

#	for selected_level_value in Sets.game_levels:
#		var selected_level_btn: Button = level_menu.get_child(selected_level_value)
#		prints("SEL", selected_level_btn.level_profile)

#		# temp, bolje je da iima btns svoje?
#	Buts.btn_accept_sound = btn_accept
#	Buts.btn_cancel_sound = btn_cancel
#	Buts.btn_toggle_on_sound = btn_accept
#	Buts.btn_toggle_off_sound = btn_cancel
#	Buts.btn_focus_sound = btn_focus


func _on_level_btn_pressed(btn: Button):

	if btn in selected_level_btns:
		selected_level_btns.erase(btn)
		btn.is_selected = false
	else:
		selected_level_btns.append(btn)
		btn.is_selected = true

	selected_levels_label.text = ""
	for selected_btn in selected_level_btns:
		selected_levels_label.text += selected_btn.level_profile["level_name"] + " "


func _on_level_btn_focused(btn: Button):

	btn.focused_display.show()

	# levo/desno
	var new_focused_btn_index: int = level_menu.get_children().find(btn)
	var slide_distance: float = new_focused_btn_index * (btn.rect_size.x + level_menu.get_constant("hseparation"))
	var slide_tween = get_tree().create_tween()
	slide_tween.tween_property(level_menu, "rect_position:x", default_level_menu_position.x - slide_distance, 0.32).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)


func _on_BackBtn_pressed() -> void:

#	Sets.game_levels = []
#	for level_btn in level_menu.get_children():
#		if level_btn in selected_level_btns:
#			var all_levels_level_value: int = level_menu.get_children().find(level_btn)
#			Sets.game_levels.append(all_levels_level_value)

	close()


func _on_PlayBtn_pressed() -> void:

#	Sets.game_levels = []
#	for level_btn in level_menu.get_children():
#		if level_btn in selected_level_btns:
#			var all_levels_level_value: int = level_menu.get_children().find(level_btn)
#			Sets.game_levels.append(all_levels_level_value)

	#	close()
	home.play_game()
