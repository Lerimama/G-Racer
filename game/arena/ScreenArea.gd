extends Area2D


func _process(delta: float) -> void:
	global_position = Ref.current_camera.get_camera_screen_center()
