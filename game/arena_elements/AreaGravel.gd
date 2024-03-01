extends Area2D


func _on_AreaGravel_body_entered(body: Node) -> void:
	
	if body is Bolt:
		if body.bolt_active: # če ni aktiven se sam od sebe ustavi
			body.drag_force_quo = Pro.bolt_profiles[body.bolt_type]["drag_force_quo_gravel"]


func _on_AreaGravel_body_exited(body: Node) -> void:
	
	if body is Bolt:
		if body.bolt_active: # če ni aktiven se sam od sebe ustavi
			body.drag_force_quo = Pro.bolt_profiles[body.bolt_type]["drag_force_quo"]
