extends Node


enum HOME_SCREEN{MAIN, LEVELS, PREGAME}
var home_screen: int = HOME_SCREEN.MAIN

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var main_menu: VBoxContainer = $Gui/MainMenu
onready var pregame_setup: Control = $Gui/PregameSetup
onready var select_games: Control = $Gui/SelectGames
onready var play_btn: Button = $Gui/MainMenu/PlayBtn
onready var focus_btn: Button = play_btn


func _ready() -> void:

	focus_btn.grab_focus()


func to_main_menu():

	if not home_screen == HOME_SCREEN.MAIN:
		match home_screen:
			HOME_SCREEN.LEVELS:
				main_menu.show()
			HOME_SCREEN.PREGAME:
				main_menu.show()
		home_screen = HOME_SCREEN.MAIN
		focus_btn.grab_focus()


func _on_PlayBtn_pressed() -> void:


	home_screen = HOME_SCREEN.PREGAME
	pregame_setup.open()
	main_menu.hide()


func _on_LevelsBtn_pressed() -> void:

	home_screen = HOME_SCREEN.LEVELS
	select_games.open()
	main_menu.hide()


func _on_QuitBtn_pressed() -> void:

	get_tree().quit()
