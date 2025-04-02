extends Control


func _input(event: InputEvent) -> void: # temp tukej, ker GM ne procesira

	if Input.is_action_just_pressed("ui_cancel"):

		var game: Game = get_parent().game
		if game:
			if game.game_stage == game.GAME_STAGE.PLAYING or game.game_stage == game.GAME_STAGE.READY:
				get_parent().game.game_sound.screen_slide.play()
				if visible:
					_on_PlayBtn_pressed()
				else:
					pause_game()


func _ready() -> void:

	hide()


func pause_game():

	get_parent().game.game_sound.game_music.stream_paused = true
	get_parent().game.game_sound.menu_music.play()

	show()
	get_tree().set_pause(true)
	$Menu/PlayBtn.grab_focus()

	get_viewport().set_disable_input(true) # anti dablklik
	var pause_in_time: float = 0.32
	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(self, "modulate:a", 1, pause_in_time).from(0.0).set_ease(Tween.EASE_IN)
	yield(fade_tween, "finished")
	get_viewport().set_disable_input(false)


func play_on():

	get_viewport().set_disable_input(true) # anti dablklik
	var pause_out_time: float = 0.5
	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(self, "modulate:a", 0, pause_out_time).set_ease(Tween.EASE_IN)
	yield(fade_tween, "finished")
	get_viewport().set_disable_input(false)

	get_parent().game.game_sound.menu_music.stop()
	get_parent().game.game_sound.game_music.stream_paused = false

	get_tree().set_pause(false)
	hide()


# MENU ---------------------------------------------------------------------------------------------


func _on_PlayBtn_pressed() -> void:

	play_on()


func _on_RestartBtn_pressed() -> void:

	Refs.main_node.reload_game()


func _on_QuitBtn_pressed() -> void:

	Refs.main_node.to_home()
