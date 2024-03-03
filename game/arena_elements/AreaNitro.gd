extends Area2D


func _on_AreaNitro_body_entered(body: Node) -> void:

	if body is Bolt:
		if body.bolt_active: # če ni aktiven se sam od sebe ustavi
			body.modulate = Color.green
			body.drag_force_quo = Pro.bolt_profiles[body.bolt_type]["drag_force_quo_nitro"]


func _on_AreaNitro_body_exited(body: Node) -> void:
	
	if body is Bolt:
#		if body.bolt_active: # če ni aktiven se sam od sebe ustavi
		body.modulate = Color.white
#		body.drag = Pro.bolt_profiles[body.bolt_type]["drag"]
		body.drag_force_quo = Pro.bolt_profiles[body.bolt_type]["drag_force_quo"]
