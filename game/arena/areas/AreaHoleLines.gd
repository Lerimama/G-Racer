extends Area2D


var level_area_key: int = Pro.LevelAreas.AREA_HOLE

onready var hole_drag_div = Pro.level_areas_profiles[level_area_key]["drag_div"]


func _on_AreaHole_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		if body.bolt_active: # če ni aktiven se sam od sebe ustavi
			body.modulate = Color.green			
			body.drag_div = hole_drag_div


func _on_AreaHole_body_exited(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		body.modulate = Color.white 			
		body.drag_div = Pro.bolt_profiles[body.bolt_type]["drag_div"]
