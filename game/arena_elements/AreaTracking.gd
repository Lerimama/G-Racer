extends Area2D


func _on_FloorGap_body_entered(body: Node) -> void:
	
	if body is Bolt:
		body.modulate = Color.yellow
		body.side_traction = Set.default_game_settings["area_tracking_value"]


func _on_FloorGap_body_exited(body: Node) -> void:
	if body is Bolt:
		body.modulate = Color.white
		body.side_traction = Pro.bolt_profiles[body.bolt_type]["side_traction"]
