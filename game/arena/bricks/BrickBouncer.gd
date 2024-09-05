extends StaticBody2D


var level_object_key: int # poda spawner, uravnava vse ostalo

onready var brick_color: Color = Pro.level_object_profiles[level_object_key]["color"]
onready var brick_altitude: float = Pro.level_object_profiles[level_object_key]["altitude"]
onready var reward_points: float = Pro.level_object_profiles[level_object_key]["value"]
onready var ai_target_rank: int = Pro.level_object_profiles[level_object_key]["ai_target_rank"]
onready var bounce_strength: float = Pro.level_object_profiles[level_object_key]["bounce_strength"]

onready var sprite: Sprite = $Sprite
onready var brick_shadow: Sprite = $BrickShadow


func _ready() -> void:

	sprite.modulate = brick_color
	brick_shadow.shadow_distance = brick_altitude
	

func _on_DetectArea_body_entered(body: Node) -> void:

	if body.is_in_group(Ref.group_bolts):
		body.modulate = Color.yellow
		
		
func _on_DetectArea_body_exited(body: Node) -> void:

	if body.is_in_group(Ref.group_bolts): 
		body.modulate = Color.white
