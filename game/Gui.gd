extends CanvasLayer
class_name Gui


onready var hud: Hud = $Hud
onready var agent_huds: Control = $AgentHuds
onready var pause_game: Control = $PauseGame
onready var game_over: Control = $GameOver
onready var level_over: Control = $LevelOver

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
	var finale_data = current_game_manager.finale_game_data#.duplicate()
#func set_hud(level_type: int, level_time_limit: float, level_lap_count: int, game_views: Dictionary):
	match game_manager.game_stage:

		game_manager.GAME_STAGE.READY:
			hud.set_hud(game_manager.game_tracker.agents_in_game, game_manager.game_level.level_type, game_manager.level_profile, game_manager.game_views)
			if game_manager.level_profile["level_time_limit"] > 0:
				if not hud.game_timer.is_connected("time_is_up", game_manager.game_reactor, "_on_game_time_is_up"):
					hud.game_timer.connect("time_is_up", game_manager.game_reactor, "_on_game_time_is_up")
			agent_huds.set_agent_huds(game_manager.game_views, Sts.one_screen_mode)

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
#			print ("GO sus")
#			print (finale_data)
			# je level zadnji?
			yield(get_tree().create_timer(Sts.get_it_time), "timeout")
			if game_manager.level_index < (Sts.current_game_levels.size() - 1):
				level_over.open(finale_data)
				hud.on_level_over()
			else:
				game_over.open(finale_data)
				hud.on_game_over()

		game_manager.GAME_STAGE.END_FAIL:
#			print ("GO fail")
#			print (finale_data)
			yield(get_tree().create_timer(Sts.get_it_time), "timeout")
			game_over.open(finale_data)
			hud.on_game_over()

#	print(game_manager.finale_game_data)
