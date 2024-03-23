extends StaticBody2D

var turned_on: bool = false
var bolts_in_goal_area: Array = []

onready var light_poly: Polygon2D = $LightPoly
onready var light_2d: Light2D = $Light2D
onready var light_points: int = Set.default_game_settings["light_points"]


func _ready() -> void:
	
	light_2d.color = Set.color_red
	light_poly.color = Set.color_red


func light_reached(bolt: KinematicBody2D):
	
	if not turned_on:
		turned_on = true
		light_2d.color = Set.color_green
		light_poly.color = Set.color_green
		bolt.get_points(light_points)
	

func _on_DetectArea_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		bolts_in_goal_area.append(body)


func _on_DetectArea_body_exited(body: Node) -> void:

	if bolts_in_goal_area.has(body):
		bolts_in_goal_area.erase(body)
		light_reached(body)
