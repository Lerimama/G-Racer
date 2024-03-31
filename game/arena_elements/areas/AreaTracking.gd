extends Area2D


func _on_AreaTracking_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		if body.bolt_active:
			if body.bolt_on_tracking_count == 0: # vklopiš samo na prvi
#				body.modulate = Color.green			
				body.side_traction = Set.default_game_settings["area_tracking_value"]
			body.bolt_on_tracking_count += 1 


func _on_AreaTracking_body_exited(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		body.bolt_on_tracking_count -= 1 
		if body.bolt_on_tracking_count == 0: # izklopiš, ko bolta ni v nobeni več
#			body.modulate = Color.white
			body.side_traction = Pro.bolt_profiles[body.bolt_type]["side_traction"]