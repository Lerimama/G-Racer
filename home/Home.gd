extends Node2D


enum HOME_SCREEN{MAIN, LEVELS, PREGAME}
var home_screen: int = HOME_SCREEN.MAIN

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var main_menu: VBoxContainer = $Gui/MainMenu
onready var drivers_setup: Control = $Gui/Drivers
onready var levels_setup: Control = $Gui/Levels
onready var play_btn: Button = $Gui/MainMenu/PlayBtn
onready var focus_btn: Button = play_btn

onready var home_sound: Node = $Sounds

func _input(event: InputEvent) -> void:


	if Input.is_action_just_pressed("no1"):
#		capture_rect_image(ccontrol)
		Mets.take_screenshot()


func _ready() -> void:

	focus_btn.grab_focus()
	home_sound.menu_music.play()


func play_game():

	# drivers
	Pros.start_driver_profiles = {}
	for driver_box in drivers_setup.activated_driver_boxes:
		var driver_id: String = driver_box.driver_profile["driver_name_id"]
		Pros.start_driver_profiles[driver_id] = driver_box.driver_profile # .duplicate()

	# levels
	for level_btn in levels_setup.level_cards.get_children():
		if level_btn in levels_setup.selected_level_cards:
			var all_levels_level_value: int = levels_setup.level_cards.get_children().find(level_btn)
			Sets.game_levels.append(all_levels_level_value)

	Refs.ultimate_popup.open_popup()

	home_sound.screen_transition.play()
	home_sound.fade_sounds(home_sound.menu_music, home_sound.screen_transition)
	yield(home_sound.screen_transition, "finished")
	home_sound.nitro_intro.play()
	yield(get_tree().create_timer(1), "timeout")
	home_sound.fade_sounds(home_sound.nitro_intro, 3)
	yield(home_sound.nitro_intro, "finished")

	Refs.main_node.call_deferred("to_game")


func to_main_menu():

	if not home_screen == HOME_SCREEN.MAIN:
		home_sound.menu_transition.play()
		match home_screen:
			HOME_SCREEN.LEVELS:
				main_menu.show()
			HOME_SCREEN.PREGAME:
				main_menu.show()
		home_screen = HOME_SCREEN.MAIN
		focus_btn.grab_focus()


func _on_PlayBtn_pressed() -> void:
	# oneshot

	play_game()


func _on_LevelsBtn_pressed() -> void:

	home_sound.menu_transition.play()
	home_screen = HOME_SCREEN.LEVELS
	levels_setup.open()
	main_menu.hide()


func _on_PlayersBtn_pressed() -> void:

	home_sound.menu_transition.play()
	home_screen = HOME_SCREEN.PREGAME
	drivers_setup.open()
	main_menu.hide()


func _on_QuitBtn_pressed() -> void:

	get_tree().quit()
