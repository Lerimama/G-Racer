extends Node2D

onready var navigation_line: Line2D = $Line2D
onready var target = $Player2
onready var enemy = $enema



func _ready() -> void:
	
	print(set_deferred("enemy", false))
	pass
	
	
func _on_enema_path_changed(path) -> void:
	navigation_line.points = path

func _physics_process(delta: float) -> void:
#	if enemy.has_method("set_target_location"):
#		enemy.target = target
	pass
	
	


func _on_Edge_tilemap_completed(floor_tiles_positions: Array) -> void:
	
#	set_deferred(enemy, true)
	print($en)
	call_deferred("pass_on", floor_tiles_positions)
	
func pass_on(xxx):
	enemy.idle_area = xxx
