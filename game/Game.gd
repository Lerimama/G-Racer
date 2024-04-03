extends Node2D


#var active_players_count: int = 4
onready var game_view_grid: GridContainer = $GameViewGrid

func _ready() -> void:
#	print("GAME")
#	modulate.a = 0
#	Ref.game_manager.get_game_settings(0)
#	Ref.game_manager.set_game()
	
#	yield(get_tree().create_timer(1), "timeout") # da se kamera centrira (na restart)
	
#	fade_in.tween_callback(Ref.game_manager, "set_game")
	pass

#func show_game():
#	var fade_time: float =  1
#	var fade_in_tween = get_tree().create_tween()
#	fade_in_tween.tween_property(self, "modulate", Color.white, fade_time).from(Color.black)
#
#
#func reload_scene(vp_count):
#	get_tree().reload_current_scene()
