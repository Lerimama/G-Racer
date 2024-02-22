extends Control



func _ready() -> void:
	pass # Replace with function body.


func _on_BackBtn_pressed() -> void:
	
	Global.sound_manager.play_gui_sfx("screen_slide")
	$"%AnimationPlayer".play_backwards("select_game")
	get_viewport().set_disable_input(true)
	

func play_selected_game(selected_game_enum: int):
	Profiles.set_game_data(selected_game_enum)
	Global.sound_manager.play_gui_sfx("menu_fade")
	$"%AnimationPlayer".play("play")
	get_viewport().set_disable_input(true)
	
		
# at the cleaners -----------------------------------------------------------------------------------------


func _on_CleanerBtn_pressed() -> void:
	play_selected_game(Profiles.Games.CLEANER)
func _on_TutorialBtn_pressed() -> void:
	play_selected_game(Profiles.Games.TUTORIAL)
func _on_CleanerDuelBtn_pressed() -> void:
	play_selected_game(Profiles.Games.CLEANER_DUEL)


func _on_EraserSBtn_pressed() -> void:
	play_selected_game(Profiles.Games.ERASER_S)
func _on_EraserMBtn_pressed() -> void:
	play_selected_game(Profiles.Games.ERASER_M)
func _on_EraserLBtn_pressed() -> void:
	play_selected_game(Profiles.Games.ERASER_L)


func _on_ScrollerBtn_pressed() -> void:
	play_selected_game(Profiles.Games.SCROLLER)
func _on_SliderBtn_pressed() -> void:
	play_selected_game(Profiles.Games.SLIDER)


func _on_RiddlerBtn_pressed() -> void:
	play_selected_game(Profiles.Games.RIDDLER_S)
func _on_RiddlerBtn2_pressed() -> void:
	play_selected_game(Profiles.Games.RIDDLER_M)
func _on_RiddlerBtn3_pressed() -> void:
	play_selected_game(Profiles.Games.RIDDLER_L)


func _on_RunnerBtn_pressed() -> void:
	play_selected_game(Profiles.Games.RUNNER)

