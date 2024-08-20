extends StaticBody2D


var turned_on: bool = false
var bolts_in_goal_area: Array = []

var element_key: int # poda spawner, uravnava vse ostalo

onready var pillar_altitude: float = Pro.level_elements_profiles[element_key]["altitude"]
onready var reward_points: float = Pro.level_elements_profiles[element_key]["value"]

onready var light_2d: Light2D = $Light2D
onready var light_poly: Polygon2D = $LightPoly
onready var pillar_shadow: Sprite = $PillarShadow


func _ready() -> void:
	
	light_2d.color = Ref.color_red
	light_poly.color = Ref.color_red
	pillar_shadow.shadow_distance = pillar_altitude
	

func goal_reached(bolt: KinematicBody2D):
	
	if not turned_on:
		turned_on = true
		light_2d.color = Ref.color_green
		light_poly.color = Ref.color_green
		bolt.update_bolt_points(reward_points)
	

func _on_DetectArea_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		bolts_in_goal_area.append(body)


func _on_DetectArea_body_exited(body: Node) -> void:

	if bolts_in_goal_area.has(body):
		bolts_in_goal_area.erase(body)
		goal_reached(body)
