extends Area2D


func _on_FloorGap_body_entered(body: Node) -> void:
	
	if body is Bolt:
		body.modulate.a = 0.8
		body.engine_power = 0 # fwd_engine_power ostaja isto močen in ima spet efekt ko ni nitro zoni


func _on_FloorGap_body_exited(body: Node) -> void:
	
	if body is Bolt:
		body.modulate = Color.white
		
