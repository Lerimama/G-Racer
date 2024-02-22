extends Area2D


func _on_FloorGap_body_entered(body: Node) -> void:
	
	if body is Bolt:
		body.modulate = Color.blue
		body.engine_power = Set.default_game_settings["area_nitro_value"] # fwd_engine_power ostaja isto močen in ima spet efekt ko ni nitro zoni


func _on_FloorGap_body_exited(body: Node) -> void:
	if body is Bolt:
		body.modulate = Color.white
