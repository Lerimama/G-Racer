extends Node


#var active_players_count: int = 4
onready var game_view_grid: GridContainer = $GameViewGrid

func _ready() -> void:
	print("GAME")
	pass
	
func reload_scene(vp_count):
	get_tree().reload_current_scene()

#
#func _on_Button_pressed() -> void:
#	game_view_grid.active_players_count = 1
##	reload_scene(1)
#
#
#func _on_Button2_pressed() -> void:
#	game_view_grid.active_players_count = 2
##	reload_scene(2)
#
#
#func _on_Button3_pressed() -> void:
#	game_view_grid.active_players_count = 3
##	reload_scene(3)
#
#
#func _on_Button4_pressed() -> void:
#	game_view_grid.active_players_count = 4
##	reload_scene(4)
