extends Area2D


var level_area_key: int = Pro.LevelAreas.AREA_GRAVEL

onready var gravel_drag_div = Pro.level_areas_profiles[level_area_key]["drag_div"]


func _on_AreaGravel_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		if body.bolt_active: # če ni aktiven se sam od sebe ustavi
			body.drag_div = gravel_drag_div


func _on_AreaGravel_body_exited(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		body.drag_div = Pro.bolt_profiles[body.bolt_type]["drag_div"]
