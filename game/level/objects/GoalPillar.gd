extends StaticBody2D


export var height: float = 100 # PRO
export var elevation: float = 10 # PRO
export var transparency: float = 10 # PRO

var turned_on: bool = false
var bolts_in_goal_area: Array = []

var level_object_key: int # poda spawner, uravnava vse ostalo

onready var reward_points: float = Pros.level_object_profiles[level_object_key]["value"]
onready var ai_target_rank: int = Pros.level_object_profiles[level_object_key]["ai_target_rank"]
onready var light_poly: Polygon2D = $LightPoly


func _ready() -> void:

	light_poly.color = Refs.color_red


func goal_reached(bolt: Node):

	if not turned_on:
		turned_on = true
		light_poly.color = Refs.color_green
		bolt.update_bolt_points(reward_points)
		$AnimationPlayer.play("edge_rotate")


func _on_DetectArea_body_entered(body: Node) -> void:

	if body.is_in_group(Refs.group_bolts):
		bolts_in_goal_area.append(body)


func _on_DetectArea_body_exited(body: Node) -> void:

	if bolts_in_goal_area.has(body):
		bolts_in_goal_area.erase(body)
		goal_reached(body)
