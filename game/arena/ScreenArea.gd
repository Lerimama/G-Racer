extends Node2D


signal body_exited_playing_field (body)

func _process(delta: float) -> void:
	global_position = Ref.current_camera.get_camera_screen_center()


func _on_ScreenArea_body_exited(body: Node) -> void:
	emit_signal("body_exited_playing_field", body)
