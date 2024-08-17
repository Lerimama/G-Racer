extends StaticBody2D

var turned_on: bool = false
var bolts_in_goal_area: Array = []

var light_off_color: Color = Set.color_brick_light_off
var light_on_color: Color = Set.color_brick_light_on

onready var light_poly: Polygon2D = $LightPoly
onready var light_2d: Light2D = $Light2D


func _ready() -> void:
	
	#	light_2d.color = light_off_color
	#	light_poly.color = light_off_color
	modulate = light_off_color


func light_reached(bolt: KinematicBody2D):
	
	if not turned_on:
		turned_on = true
		#		light_2d.color = light_on_color
		#		light_poly.color = light_on_color
		modulate = light_on_color
		var points_reward: float = Ref.game_manager.game_settings["light_points"]
		bolt.update_bolt_points(points_reward)

func _on_DetectArea_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		bolts_in_goal_area.append(body)


func _on_DetectArea_body_exited(body: Node) -> void:

	if bolts_in_goal_area.has(body):
		bolts_in_goal_area.erase(body)
		light_reached(body)
