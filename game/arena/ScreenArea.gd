extends Area2D


func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	global_position = Ref.current_camera.get_camera_screen_center()



func _on_ScreenArea_body_entered(body: Node) -> void:
	pass # Replace with function body.
	if body is Player:
		body.modulate = Color.white # ne spremeni barve bolta


func _on_ScreenArea_body_exited(body: Node) -> void:
	
	if body is Player:
		body.modulate = Color.red
	pass # Replace with function body.
