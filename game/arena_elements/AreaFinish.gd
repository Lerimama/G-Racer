extends Area2D


func _on_FloorGap_body_entered(body: Node) -> void:
	
	if body is Bolt:
		body.modulate = Color.red
#		body.engine_power = Set.default_game_settings["area_nitro_value"] # fwd_engine_power ostaja isto močen in ima spet efekt ko ni nitro zoni
	

func _on_FloorGap_body_exited(body: Node) -> void:
#	print("finish line")
	
	if body is Bolt:
		body.modulate = Color.green
		yield(get_tree().create_timer(0.5), "timeout")
		Ref.game_manager.game_over(0)
