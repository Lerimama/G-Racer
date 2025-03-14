extends StaticBody2D


signal reached_by

export var height: float = 100
export var elevation: float = 10

var turned_on: bool = false
var drivers_in_goal_area: Array = []

var level_object_key: int # poda spawner, uravnava vse ostalo

onready var reward_points: float = Pros.level_object_profiles[level_object_key]["value"]
onready var target_rank: int = Pros.level_object_profiles[level_object_key]["target_rank"]
onready var light_poly: Polygon2D = $LightPoly


func _ready() -> void:

	light_poly.color = Refs.color_red


func _goal_reached(vehicle: Vehicle):

	emit_signal("reached_by", self, vehicle)

	if not turned_on:
		turned_on = true
		light_poly.color = Refs.color_green
		vehicle.update_stat(Pros.STATS.POINTS, reward_points)
		$AnimationPlayer.play("edge_rotate")


func _on_DetectArea_body_entered(body: Node) -> void:

	if body.is_in_group(Refs.group_drivers):
		drivers_in_goal_area.append(body)


func _on_DetectArea_body_exited(body: Node) -> void:

	if body in drivers_in_goal_area:
		drivers_in_goal_area.erase(body)
		_goal_reached(body)
