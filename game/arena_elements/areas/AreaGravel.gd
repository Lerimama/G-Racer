extends Area2D


func _on_AreaGravel_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		if body.bolt_active: # če ni aktiven se sam od sebe ustavi
			if body.bolt_on_gravel_count == 0: # vklopiš samo na prvi
#				body.modulate = Color.green
				body.drag_force_div = Ref.game_manager.game_settings["area_gravel_drag_force_div"]
			body.bolt_on_gravel_count += 1


func _on_AreaGravel_body_exited(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
#		yield(get_tree().create_timer(1), "timeout")
		body.bolt_on_gravel_count -= 1 
		if body.bolt_on_gravel_count == 0: # izklopiš, ko bolta ni v nobeni več
#			body.modulate = Color.white
			body.drag_force_div = Pro.bolt_profiles[body.bolt_type]["drag_force_div"]
