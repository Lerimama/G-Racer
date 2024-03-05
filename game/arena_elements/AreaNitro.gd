extends Area2D


func _on_AreaNitro_body_entered(body: Node) -> void:

	if body is Bolt:
		if body.bolt_active: # če ni aktiven se sam od sebe ustavi
			if body.bolt_on_nitro_count == 0: # vklopiš samo na prvi
#				body.modulate = Color.green
				body.drag_force_div = Ref.game_manager.game_settings["area_nitro_drag_force_div"]
			body.bolt_on_nitro_count += 1 
#	printt("in", body.bolt_in_nitro_count)
			
			
func _on_AreaNitro_body_exited(body: Node) -> void:
	
	if body is Bolt:
		# yield(get_tree().create_timer(1), "timeout")
		body.bolt_on_nitro_count -= 1 
		if body.bolt_on_nitro_count == 0: # izklopiš, ko bolta ni v nobeni več
#			body.modulate = Color.white 
			body.drag_force_div = Pro.bolt_profiles[body.bolt_type]["drag_force_div"]
#	printt("out", body.bolt_in_nitro_count)
