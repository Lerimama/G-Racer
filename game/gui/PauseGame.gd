extends Control



func _ready() -> void:

	hide()


func pause_game():

	show()
	get_viewport().set_disable_input(true) # anti dablklik
	get_tree().set_pause(true)

#	Global.sound_manager.play_gui_sfx("screen_slide")
	$Menu/PlayBtn.grab_focus()
	var pause_in_time: float = 0.32
	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(self, "modulate:a", 1, pause_in_time).from(0.0).set_ease(Tween.EASE_IN)

	yield(fade_tween, "finished")

	get_viewport().set_disable_input(false)



func play_on():

	get_viewport().set_disable_input(true) # anti dablklik

#	Global.sound_manager.play_gui_sfx("screen_slide")
	var pause_out_time: float = 0.5
	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(self, "modulate:a", 0, pause_out_time).set_ease(Tween.EASE_IN)

	yield(fade_tween, "finished")

	hide()
	get_tree().set_pause(false)
	get_viewport().set_disable_input(false)


# MENU ---------------------------------------------------------------------------------------------


func _on_PlayBtn_pressed() -> void:
	print ("gumb ni povezan")
	play_on()


func _on_RestartBtn_pressed() -> void:

#	Global.sound_manager.play_gui_sfx("btn_confirm")
	Rfs.sound_manager.stop_music()
	get_tree().paused = false #... tween za izhod pavzo drevesa ignorira
	Rfs.main_node.reload_game()


func _on_QuitBtn_pressed() -> void:

#	Global.game_manager.stop_game_elements()
	Rfs.sound_manager.stop_music()
	# get_tree().paused = false ... tween za izhod pavzo drevesa ignorira
	Rfs.main_node.game_out()
