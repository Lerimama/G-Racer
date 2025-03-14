extends Control


var is_open: bool = false
onready var home: Node = $"../.."
onready var level_menu: HBoxContainer = $LevelMenu


func _input(event: InputEvent) -> void:

	if is_open and Input.is_action_just_pressed("ui_cancel"):
		close()


func _ready() -> void:

	hide()


func open():

	# preverjam , če se je odprlo zaradi direktnega fokusiranja
	var allready_focused: bool = false
	for btn in level_menu.get_children():
		if btn.has_focus():
			allready_focused = true
			break
	if not allready_focused:
		level_menu.get_children()[0].grab_focus()

#	focus_btn.grab_focus()
	is_open = true
	show()


func close():

	home.to_main_menu()
	is_open = false
	hide()




func _on_BackBtn_pressed() -> void:
	close()


func _on_PlayBtn_pressed() -> void:

	close()
	home._on_PlayBtn_pressed()
