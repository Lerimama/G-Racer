extends Area2D


func _on_AreaHole_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		if body.bolt_active: # če ni aktiven se sam od sebe ustavi
			if body.bolt_on_hole_count == 0: # vklopiš samo na prvi
#				body.modulate = Color.green			
				body.drag_force_div = Ref.game_manager.game_settings["area_hole_drag_force_div"]
			body.bolt_on_hole_count += 1 


func _on_AreaHole_body_exited(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		body.bolt_on_hole_count -= 1 
		if body.bolt_on_hole_count == 0: # izklopiš, ko bolta ni v nobeni več
#			body.modulate = Color.white 			
			body.drag_force_div = Pro.bolt_profiles[body.bolt_type]["drag_force_div"]
		
