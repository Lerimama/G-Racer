extends StaticBody2D


var bolts_in_goal_area: Array = []
var goal_points = 100

onready var light_2d: Light2D = $Light2D
onready var light_poly: Polygon2D = $LightPoly


func _ready() -> void:
	
	light_2d.color = Set.color_red
	light_poly.color = Set.color_red


func goal_reached():
	
	light_2d.color = Set.color_green
	light_poly.color = Set.color_green
	

func _on_DetectArea_body_entered(body: Node) -> void:
	
	if body is Bolt:
		bolts_in_goal_area.append(body)

func _on_DetectArea_body_exited(body: Node) -> void:

	if bolts_in_goal_area.has(body):
		bolts_in_goal_area.erase(body)
		goal_reached()
