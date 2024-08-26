extends Area2D


var level_area_key: int # poda spawner, uravnava vse ostalo

onready var nitro_drag_div = Pro.level_areas_profiles[level_area_key]["drag_div"]


func _on_AreaNitro_body_entered(body: Node) -> void:

	if body.is_in_group(Ref.group_bolts):
		if body.bolt_active: # če ni aktiven se sam od sebe ustavi
			if body.bolt_on_nitro_count == 0: # vklopiš samo na prvi
				#				body.modulate = Color.green
				body.drag_div = nitro_drag_div
				#				body.current_drag = Ref.game_manager.game_settings["area_nitro_drag"]
			body.bolt_on_nitro_count += 1 
			#	printt("in", body.bolt_in_nitro_count)
			
			
func _on_AreaNitro_body_exited(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		# yield(get_tree().create_timer(1), "timeout")
		body.bolt_on_nitro_count -= 1 
		if body.bolt_on_nitro_count == 0: # izklopiš, ko bolta ni v nobeni več
		#			body.modulate = Color.white 
			body.drag_div = Pro.bolt_profiles[body.bolt_type]["drag_div"]
		#			body.current_drag = Pro.bolt_profiles[body.bolt_type]["drag"]
