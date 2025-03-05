extends CanvasLayer
class_name Gui


var is_set: bool = false
var game_manager: Game

#onready var hud: Hud = $Hud
onready var hud: Control = $Hud
onready var driver_huds_holder: Control = $DriverHuds
onready var pause_game: Control = $PauseGame
onready var game_over: Control = $GameOver
onready var level_over: Control = $LevelOver
onready var game_cover: ColorRect = $GameCover



func _input(event: InputEvent) -> void: # temp tukej, ker GM ne procesira

	if Input.is_action_just_pressed("ui_cancel"):
		if game_manager.game_stage == game_manager.GAME_STAGE.PAUSED:
			pause_game.play_on()
			game_manager.set_deferred("game_stage", game_manager.GAME_STAGE.PLAYING) # def ker se more prosesirat
#			game_manager.game_stage = game_manager.GAME_STAGE.PLAYING
		elif game_manager.game_stage == game_manager.GAME_STAGE.PLAYING:
			game_manager.game_stage = game_manager.GAME_STAGE.PAUSED


func _ready() -> void:

	pause_game.hide()
	level_over.hide()
	game_over.hide()
	game_cover.modulate.a = 1
	pass


func _on_game_stage_changed(current_game_manager: Game):

	game_manager = current_game_manager
	var finale_data = current_game_manager.finale_game_data

	match game_manager.game_stage:
		game_manager.GAME_STAGE.READY:
			is_set = false
			hud.set_hud(game_manager)
			if game_manager.level_profile["level_time_limit"] > 0:
				if not hud.game_timer.is_connected("time_is_up", game_manager.game_reactor, "_on_game_time_is_up"):
					hud.game_timer.connect("time_is_up", game_manager.game_reactor, "_on_game_time_is_up")
			driver_huds_holder.set_driver_huds(game_manager.game_views, Sts.one_screen_mode)


		game_manager.GAME_STAGE.INTRO:
			var fade_tween = get_tree().create_tween()
			fade_tween.tween_property(game_cover, "modulate:a", 0, 0.7)
			yield(fade_tween, "finished")

		game_manager.GAME_STAGE.PLAYING:
			if not is_set:
				is_set = true
				hud.on_game_start()
			#			else:
			#				if pause_game.visible:
			#					pause_game.play_on()

		game_manager.GAME_STAGE.PAUSED:
			pause_game.pause_game()

		game_manager.GAME_STAGE.END_SUCCESS:
			yield(get_tree().create_timer(Sts.get_it_time), "timeout")
			var fade_tween = get_tree().create_tween()
			fade_tween.tween_property(game_cover, "modulate:a", 0.8, 0.7)
			yield(fade_tween, "finished")
			if game_manager.level_index < Sts.game_levels.size() - 1:
				level_over.open(finale_data)
				hud.on_level_over()
			else:
				game_over.open(finale_data)
				hud.on_game_over()

		game_manager.GAME_STAGE.END_FAIL:
			yield(get_tree().create_timer(Sts.get_it_time), "timeout")
			var fade_tween = get_tree().create_tween()
			fade_tween.tween_property(game_cover, "modulate:a", 0.8, 0.7)
			yield(fade_tween, "finished")
			game_over.open(finale_data)
			hud.on_game_over()


func back_to_what(what_to_do_next: int = 1):

#	yield(get_tree().create_timer(1), "timeout")
	match what_to_do_next:
		-1: # quit
			Rfs.main_node.game_out()
		0: # restart
			Rfs.main_node.reload_game()
		1: # next level
			game_manager._set_game()

