extends StaticBody2D


var turned_on: bool = false
var bolts_in_goal_area: Array = []

var key_as_name: String # poda spawner, uravnava vse ostalo

onready var pillar_color: Color = Pro.arena_element_profiles[key_as_name]["color"] # trenutno ne uporabljam
onready var pillar_altitude: float = Pro.arena_element_profiles[key_as_name]["altitude"]
onready var reward_points: float = Pro.arena_element_profiles[key_as_name]["value"]

onready var light_2d: Light2D = $Light2D
onready var light_poly: Polygon2D = $LightPoly
onready var pillar_shadow: Sprite = $PillarShadow


func _ready() -> void:
	
	light_2d.color = Set.color_red
	light_poly.color = Set.color_red
	pillar_shadow.shadow_distance = pillar_altitude
	

func goal_reached(bolt: KinematicBody2D):
	
	if not turned_on:
		turned_on = true
		light_2d.color = Set.color_green
		light_poly.color = Set.color_green
		bolt.update_bolt_points(reward_points)
	

func _on_DetectArea_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		bolts_in_goal_area.append(body)


func _on_DetectArea_body_exited(body: Node) -> void:

	if bolts_in_goal_area.has(body):
		bolts_in_goal_area.erase(body)
		goal_reached(body)
