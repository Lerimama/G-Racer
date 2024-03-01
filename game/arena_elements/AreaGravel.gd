extends Area2D


var ingoing_engine_power: float

func _on_AreaGravel_body_entered(body: Node) -> void:
	
	if body is Bolt:
		body.modulate = Color.yellow
		if body.fwd_engine_power > 0:
			body.engine_power = body.fwd_engine_power /3
#			body.fwd_engine_power = 100
		elif body.rev_engine_power > 0:
			body.engine_power = body.rev_engine_power /5
		printt("SPID", body.engine_power)


func _on_AreaGravel_body_exited(body: Node) -> void:
	
	if body is Bolt:
		
		if body.fwd_engine_power > 0:
#			body.engine_power = body.fwd_engine_power
			pass
		elif body.rev_engine_power > 0:
#			body.engine_power = body.rev_engine_power
			pass
			
#		printt("FIN", body.engine_power)
		body.modulate = Color.white
#		body.engine_power = ingoing_engine_power
#		body.side_traction = Pro.bolt_profiles[body.bolt_type]["side_traction"]
