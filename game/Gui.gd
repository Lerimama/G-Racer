extends CanvasLayer
class_name Gui


#var is_set: bool = false
var game_manager: Game

#onready var hud: Hud = $Hud
onready var hud: Control = $Hud
onready var driver_huds_holder: Control = $DriverHuds
onready var pause_game: Control = $PauseGame
onready var game_over: Control = $GameOver
onready var game_cover: ColorRect = $GameCover



func _input(event: InputEvent) -> void: # temp tukej, ker GM ne procesira

	if Input.is_action_just_pressed("ui_cancel") and game_manager.game_stage == game_manager.GAME_STAGE.PLAYING:
		if pause_game.visible:
			pause_game.play_on()
		else:
			pause_game.pause_game()


func _ready() -> void:

	pause_game.hide()
	game_over.hide()
	game_cover.modulate.a = 1


func _on_game_stage_changed(curr_game_manager: Game):

	game_manager = curr_game_manager

	var finale_data = game_manager.finale_game_data

	match game_manager.game_stage:

		game_manager.GAME_STAGE.READY:

			hud.set_hud(game_manager)
			if game_manager.level_profile["level_time_limit"] > 0:
				if not hud.game_timer.is_connected("time_is_up", game_manager.game_reactor, "_on_game_time_is_up"):
					hud.game_timer.connect("time_is_up", game_manager.game_reactor, "_on_game_time_is_up")
			driver_huds_holder.set_driver_huds(game_manager, Sts.one_screen_mode)

		game_manager.GAME_STAGE.INTRO:

			var fade_tween = get_tree().create_tween()
			fade_tween.tween_property(game_cover, "modulate:a", 0, 0.7)
			yield(fade_tween, "finished")

		game_manager.GAME_STAGE.PLAYING:

			hud.on_game_start()

		game_manager.GAME_STAGE.END_SUCCESS, game_manager.GAME_STAGE.END_FAIL:

			var is_success: bool = true
			if game_manager.game_stage == game_manager.GAME_STAGE.END_FAIL:
				is_success = false

			yield(get_tree().create_timer(Sts.get_it_time), "timeout")
			var fade_tween = get_tree().create_tween()
			fade_tween.tween_property(game_cover, "modulate:a", 0.8, 0.7)
			yield(fade_tween, "finished")

			game_over.open(finale_data, game_manager.level_index, Sts.game_levels.size(), is_success)
			hud.on_game_over()
