extends CanvasLayer
class_name Gui


onready var hud: Hud = $Hud
onready var agent_huds: Control = $AgentHuds
onready var pause_game: Control = $PauseGame
onready var level_finished: Control = $LevelFinished
onready var game_over: Control = $GameOver

var is_set: bool = false
var game_manager: Game


func _input(event: InputEvent) -> void: # temp tukej, ker GM ne procesira

	if Input.is_action_just_pressed("ui_cancel"):
		if game_manager.game_stage == game_manager.GAME_STAGE.PAUSED:
			pause_game.play_on()
			game_manager.set_deferred("game_stage", game_manager.GAME_STAGE.PLAYING) # def ker se more prosesirat
#			game_manager.game_stage = game_manager.GAME_STAGE.PLAYING
		elif game_manager.game_stage == game_manager.GAME_STAGE.PLAYING:
			game_manager.game_stage = game_manager.GAME_STAGE.PAUSED


func _ready() -> void:

	pass


func _on_game_stage_changed(current_game_manager: Game):

	game_manager = current_game_manager

	match game_manager.game_stage:
		game_manager.GAME_STAGE.READY:
			_set_layer_hud()
			hud.set_hud(game_manager.level_profile, game_manager.game_views)
			for agent in game_manager.agents_in_game:
				hud.set_agent_statbox(agent, game_manager.level_stats[game_manager.agents_in_game.find(agent)])

		game_manager.GAME_STAGE.PLAYING:
			print("play")
			if not is_set:
				is_set = true
				hud.on_game_start()
#			else:
#				if pause_game.visible:
#					pause_game.play_on()
		game_manager.GAME_STAGE.PAUSED:
			print("pause")
			pause_game.pause_game()
		game_manager.GAME_STAGE.END_SUCCESS:
			# je level zadnji?
			if game_manager.current_level_index < (Sts.current_game_levels.size() - 1):
				level_finished.open_level_finished(game_manager.agents_finished, game_manager.agents_in_game)
				hud.on_level_finished()
			else:
				game_over.open_gameover(game_manager.agents_finished, game_manager.agents_in_game)
				hud.on_game_over()
				#				print("agents_finished", agents_finished)
		game_manager.GAME_STAGE.END_FAIL:
			game_over.open_gameover(game_manager.agents_finished, game_manager.agents_in_game)
			hud.on_game_over()


func _set_layer_hud():

	pass
