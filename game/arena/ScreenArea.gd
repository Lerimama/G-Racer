extends Node2D


signal body_exited_playing_field(body)

onready var screen_area: Area2D = $ScreenArea
onready var screen_edge: StaticBody2D = $ScreenEdge
onready var screen_edge_collision: CollisionPolygon2D = $ScreenEdge/CollisionPolygon2D


func _process(delta: float) -> void:
	global_position = Refs.current_camera.get_camera_screen_center()


func _on_ScreenArea_body_exited(body: Node) -> void:
	
	emit_signal("body_exited_playing_field", body)
