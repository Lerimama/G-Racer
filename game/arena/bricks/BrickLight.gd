extends StaticBody2D

var turned_on: bool = false

var bolts_in_light_area: Array = []
var light_off_color: Color = Set.color_brick_light_off
var light_on_color: Color = Set.color_brick_light_on

var key_as_name: String # poda spawner, uravnava vse ostalo

onready var brick_color: Color = Pro.arena_element_profiles[key_as_name]["color"]
onready var brick_altitude: float = Pro.arena_element_profiles[key_as_name]["altitude"]
onready var reward_points: float = Pro.arena_element_profiles[key_as_name]["value"]

onready var brick_shadow: Sprite = $BrickShadow
onready var light_poly: Polygon2D = $LightPoly
onready var light_2d: Light2D = $Light2D


func _ready() -> void:
	
	#	light_2d.color = light_off_color
	#	light_poly.color = light_off_color
	modulate = light_off_color
	brick_shadow.shadow_distance = brick_altitude


func light_reached(bolt: KinematicBody2D):
	
	if not turned_on:
		turned_on = true
		#		light_2d.color = light_on_color
		#		light_poly.color = light_on_color
		modulate = light_on_color
		bolt.update_bolt_points(reward_points)

func _on_DetectArea_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		bolts_in_light_area.append(body)


func _on_DetectArea_body_exited(body: Node) -> void:

	if bolts_in_light_area.has(body):
		bolts_in_light_area.erase(body)
		light_reached(body)
