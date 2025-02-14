extends Control


#func _input(event: InputEvent) -> void:
#
#	#	if Rfs.game_manager.game_on:
#	if Input.is_action_just_pressed("ui_cancel"):
#		if not visible:
#			pause_game()
#		else:
#			_on_PlayBtn_pressed()


func _ready() -> void:

	visible = false
	modulate.a = 0


func pause_game():

	get_viewport().set_disable_input(true) # anti dablklik

	visible = true
#	Global.sound_manager.play_gui_sfx("screen_slide")
	$Menu/PlayBtn.grab_focus()

	var pause_in_time: float = 0.5
	var fade_in_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_in_tween.tween_callback(get_tree(), "set_pause", [true])
	fade_in_tween.tween_property(self, "modulate:a", 1, pause_in_time)
	fade_in_tween.tween_callback(get_viewport(), "set_disable_input", [false]) # anti dablklik


func play_on():

	get_viewport().set_disable_input(true) # anti dablklik
#	Global.sound_manager.play_gui_sfx("screen_slide")

	var pause_out_time: float = 0.5
	var fade_out_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out_tween.tween_property(self, "modulate:a", 0, pause_out_time)
	fade_out_tween.tween_callback(self, "hide")
	fade_out_tween.tween_callback(get_tree(), "set_pause", [false])
	fade_out_tween.tween_callback(get_viewport(), "set_disable_input", [false]) # anti dablklik
	yield(fade_out_tween, "finished")


# MENU ---------------------------------------------------------------------------------------------


func _on_PlayBtn_pressed() -> void:
	print ("gumb ni povezan")
	play_on()


func _on_RestartBtn_pressed() -> void:

#	Global.sound_manager.play_gui_sfx("btn_confirm")
	Rfs.sound_manager.stop_music()

#	Rfs.game_manager.stop_game_elements()
	get_tree().paused = false #... tween za izhod pavzo drevesa ignorira
	Rfs.main_node.reload_game()
#	Rfs.main_node.reload_game()


func _on_QuitBtn_pressed() -> void:

#	Global.game_manager.stop_game_elements()
	Rfs.sound_manager.stop_music()
	# get_tree().paused = false ... tween za izhod pavzo drevesa ignorira
	Rfs.main_node.game_out()
