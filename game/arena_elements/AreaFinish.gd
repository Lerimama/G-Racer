extends Area2D


func _on_AreaFinish_body_entered(body: Node) -> void:
	
	if body is Bolt:
		body.modulate = Color.red
	

func _on_AreaFinish_body_exited(body: Node) -> void:
	
	if body is Bolt:
		body.modulate = Color.green
		yield(get_tree().create_timer(0.5), "timeout")
		Ref.game_manager.game_over(0)
