extends StaticBody2D

var turned_on: bool = false

var bolts_in_light_area: Array = []
var light_on_color: Color = Ref.color_brick_light_on

var level_object_key: int # poda spawner, uravnava vse ostalo

onready var light_off_color: Color = Pro.level_object_profiles[level_object_key]["color"]
onready var brick_altitude: float = Pro.level_object_profiles[level_object_key]["altitude"]
onready var reward_points: float = Pro.level_object_profiles[level_object_key]["value"]

onready var ai_target_rank: int = Pro.level_object_profiles[level_object_key]["ai_target_rank"]

onready var brick_shadow: Sprite = $BrickShadow
onready var light_poly: Polygon2D = $LightPoly
onready var light_2d: Light2D = $Light2D


func _ready() -> void:
	
	#	light_2d.color = light_off_color
	#	light_poly.color = light_off_color
	modulate = light_off_color
	brick_shadow.shadow_distance = brick_altitude


func light_reached(bolt: Node2D):
	
	if not turned_on:
		turned_on = true
		#		light_2d.color = light_on_color
		#		light_poly.color = light_on_color
		modulate = light_on_color
		bolt.update_bolt_points(reward_points)

func _on_DetectArea_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		bolts_in_light_area.append(body) # OPT zakaj to rabm?
	elif body.is_in_group(Ref.group_thebolts):
		bolts_in_light_area.append(body)
		body.modulate = Color.yellow	


func _on_DetectArea_body_exited(body: Node) -> void:

	if bolts_in_light_area.has(body):
		bolts_in_light_area.erase(body)
		light_reached(body)
	elif body.is_in_group(Ref.group_thebolts):
		body.modulate = Color.white	
		bolts_in_light_area.erase(body)
		light_reached(body)
