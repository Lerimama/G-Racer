extends Node


enum HOME_SCREEN{MAIN, LEVELS, PREGAME}
var home_screen: int = HOME_SCREEN.MAIN

onready var animation_player: AnimationPlayer = $AnimationPlayer
#onready var focus_btn: Button = $UI/PlayersMenu/PlayerBtn
#onready var focus_btn: Button = $UI/LevelMenu/LevelBtn
onready var focus_btn: Button = $UI/MainMenu/PlayBtn
onready var level_menu: HBoxContainer = $UI/LevelMenu
onready var main_menu: VBoxContainer = $UI/MainMenu
onready var pregame_setup: Control = $UI/PregameSetup

# positions
onready var levels_open_position: Position2D = $UI/LevelsOpenPosition
onready var levels_closed_position: Position2D = $UI/LevelsClosedPosition
onready var levels_open_main_menu_position: Position2D = $UI/LevelsOpenMainMenuPosition
onready var main_menu_start_position: Vector2 = main_menu.rect_position


func _input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("ui_cancel"):
		_to_main_menu()


func _ready() -> void:

	focus_btn.grab_focus()

	# hide positions
	levels_closed_position.hide()
	levels_open_position.hide()
	levels_open_main_menu_position.hide()


func _on_PlayBtn_pressed() -> void:

#	Rfs.ultimate_popup.open_popup(true)
#	Rfs.ultimate_popup.connect("closing_popup", self, "_on_pregame_closed")
#	yield(Rfs.ultimate_popup, "closing_popup")

#	yield(get_tree().create_timer(0.1),"timeout")
#	if
	home_screen = HOME_SCREEN.PREGAME
	pregame_setup.open()
	main_menu.hide()
	level_menu.hide()
#	Rfs.main_node.call_deferred("home_out")


func _to_main_menu():
	if not home_screen == HOME_SCREEN.MAIN:
		match home_screen:
			HOME_SCREEN.LEVELS:
				level_menu.close()
				main_menu.get_node("LevelsBtn").show()
				main_menu.get_node("QuitBtn").show()

				main_menu.rect_position.y = main_menu_start_position.y


			HOME_SCREEN.PREGAME:
				pregame_setup.close()
				main_menu.show()
				level_menu.show()

				pass
		home_screen = HOME_SCREEN.MAIN


func _on_QuitBtn_pressed() -> void:

	get_tree().quit()


func _process(delta: float) -> void:
	pass


func _on_AnimationPlayer_animation_finished(animation) -> void:
	pass



func _on_LevelsBtn_pressed() -> void:

	home_screen = HOME_SCREEN.LEVELS
	level_menu.open()
	main_menu.get_node("LevelsBtn").hide()
	main_menu.get_node("QuitBtn").hide()
#	var position_delta_to_level_menu: float = level_menu.rect_position.y - main_menu.rect_position.y
	main_menu.rect_position.y = levels_open_main_menu_position.position.y



func _on_LevelsBtn_focus_entered() -> void:
	pass # Replace with function body.


func _on_LevelsBtn_focus_exited() -> void:
	pass # Replace with function body.


func _on_PlayBtn_focus_entered() -> void:
	_to_main_menu()
	pass # Replace with function body.
