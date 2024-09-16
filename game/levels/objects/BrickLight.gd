extends StaticBody2D


export var height: float = 0 # PRO
export var elevation: float = 0 # PRO

var turned_on: bool = false
var bolts_in_light_area: Array = []
var level_object_key: int # poda spawner, uravnava vse ostalo

#onready var elevation: float = Pro.level_object_profiles[level_object_key]["altitude"]
onready var reward_points: float = Pro.level_object_profiles[level_object_key]["value"]
onready var ai_target_rank: int = Pro.level_object_profiles[level_object_key]["ai_target_rank"]
onready var brick_shadow: Sprite = $BrickShadow
onready var light_2d: Light2D = $Light2D
onready var sprite: Sprite = $Sprite

# neu
#onready var light_on_color: Color = Ref.color_brick_light_on
#onready var light_off_color: Color = Pro.level_object_profiles[level_object_key]["color"]
export var off_color: Color = Color.yellow
export var on_color: Color = Color.green


func _ready() -> void:
	
	light_2d.color = off_color
	sprite.modulate = off_color


func light_reached(bolt: Node2D):
	
	if not turned_on:
		turned_on = true
		light_2d.color = on_color
		sprite.modulate = Color.white
		bolt.update_bolt_points(reward_points)


func _on_DetectArea_body_entered(body: Node) -> void:
	
	if body.is_in_group(Ref.group_bolts):
		light_reached(body)
	

func _on_DetectArea_body_exited(body: Node) -> void:

	pass
