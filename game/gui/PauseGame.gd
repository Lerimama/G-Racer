extends Control


func _input(event: InputEvent) -> void: # temp tukej, ker GM ne procesira

	if Input.is_action_just_pressed("ui_cancel"):

		var game_manager: Game = get_parent().game_manager
		if game_manager:
			if game_manager.game_stage == game_manager.GAME_STAGE.PLAYING or game_manager.game_stage == game_manager.GAME_STAGE.READY:
				if visible:
					play_on()
				else:
					pause_game()


func _ready() -> void:

	hide()


func pause_game():

	get_parent().game_manager.game_sound.game_music.stream_paused = true
	get_parent().game_manager.game_sound.menu_music.play()
#	var mn_music = get_parent().game_manager.game_sound.menu_music
#	var gm_music = get_parent().game_manager.game_sound.game_music
#	get_parent().game_manager.game_sound.fade_sounds(gm_music, mn_music, true)

	show()
	get_viewport().set_disable_input(true) # anti dablklik
	get_tree().set_pause(true)

#	Global.game_sound.play_gui_sfx("screen_slide")
	$Menu/PlayBtn.grab_focus()
	var pause_in_time: float = 0.32
	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(self, "modulate:a", 1, pause_in_time).from(0.0).set_ease(Tween.EASE_IN)

	yield(fade_tween, "finished")

	get_viewport().set_disable_input(false)


func play_on():

	get_viewport().set_disable_input(true) # anti dablklik

#	Global.game_sound.play_gui_sfx("screen_slide")
	var pause_out_time: float = 0.5
	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(self, "modulate:a", 0, pause_out_time).set_ease(Tween.EASE_IN)

	yield(fade_tween, "finished")

#	var gm_music = get_parent().game_manager.game_sound.game_music
#	get_parent().game_manager.game_sound.fade_sounds(mn_music, gm_music)
	get_parent().game_manager.game_sound.menu_music.stop()
	get_parent().game_manager.game_sound.game_music.stream_paused = false

	hide()
	get_tree().set_pause(false)
	get_viewport().set_disable_input(false)


# MENU ---------------------------------------------------------------------------------------------


func _on_PlayBtn_pressed() -> void:
	print ("gumb ni povezan")
	play_on()


func _on_RestartBtn_pressed() -> void:

	get_parent().close_game(0, 0)


func _on_QuitBtn_pressed() -> void:

	get_parent().close_game(-1, 0)


