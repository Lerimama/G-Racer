extends StaticBody2D


signal reached_by

export var height: float = 100
export var elevation: float = 10

var turned_on: bool = false
var agents_in_goal_area: Array = []

var level_object_key: int # poda spawner, uravnava vse ostalo

onready var reward_points: float = Pfs.level_object_profiles[level_object_key]["value"]
onready var ai_target_rank: int = Pfs.level_object_profiles[level_object_key]["ai_target_rank"]
onready var light_poly: Polygon2D = $LightPoly


func _ready() -> void:

	light_poly.color = Rfs.color_red


func goal_reached(agent: Node):

	emit_signal("reached_by", self, agent)

	if not turned_on:
		turned_on = true
		light_poly.color = Rfs.color_green
		agent.update_stat(Pfs.STATS.POINTS, reward_points)
		$AnimationPlayer.play("edge_rotate")


func _on_DetectArea_body_entered(body: Node) -> void:

	if body.is_in_group(Rfs.group_agents):
		agents_in_goal_area.append(body)


func _on_DetectArea_body_exited(body: Node) -> void:

	if agents_in_goal_area.has(body):
		agents_in_goal_area.erase(body)
		goal_reached(body)
