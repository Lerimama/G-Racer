extends Control


onready var play_btn: Button = $Menu/PlayBtn


func _input(event: InputEvent) -> void: # temp tukej, ker GM ne procesira

	if Input.is_action_just_pressed("ui_cancel"):

		var game: Game = get_parent().game
		if game:
			if game.game_stage == game.GAME_STAGE.PLAYING or game.game_stage == game.GAME_STAGE.READY:
				get_parent().game.game_sound.screen_slide.play()
				if visible:
					play_btn.emit_signal("pressed")
				else:
					pause_game()


func _ready() -> void:

	hide()


func pause_game():

	get_parent().game.game_sound.game_music.stream_paused = true
	get_parent().game.game_sound.menu_music.play()

	get_tree().set_pause(true)

	play_btn.grab_focus()

	show()
	var pause_in_time: float = 0.32
	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(self, "modulate:a", 1, pause_in_time).from(0.0).set_ease(Tween.EASE_IN)
	yield(fade_tween, "finished")

	if not play_btn.is_connected("pressed", self, "_on_play_btn_pressed"):
		play_btn.connect("pressed", self, "_on_play_btn_pressed", [], CONNECT_ONESHOT)



func play_on():

	var pause_out_time: float = 0.5
	var fade_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_tween.tween_property(self, "modulate:a", 0, pause_out_time).set_ease(Tween.EASE_IN)
	yield(fade_tween, "finished")
	hide()

	get_tree().set_pause(false)

	get_parent().game.game_sound.menu_music.stop()
	get_parent().game.game_sound.game_music.stream_paused = false



# MENU ---------------------------------------------------------------------------------------------


func _on_play_btn_pressed() -> void:

	play_on()


func _on_RestartBtn_pressed() -> void:

	Refs.main_node.reload_game()


func _on_QuitBtn_pressed() -> void:

	Refs.main_node.to_home()
