extends StaticBody2D


export var height: float = 0 # PRO
export var elevation: float = 10 # PRO

var level_object_key: int # poda spawner, uravnava vse ostalo

onready var brick_color: Color = Pro.level_object_profiles[level_object_key]["color"]
#onready var elevation: float = Pro.level_object_profiles[level_object_key]["altitude"] # PRO elevation profiles
onready var reward_points: float = Pro.level_object_profiles[level_object_key]["value"]
onready var ai_target_rank: int = Pro.level_object_profiles[level_object_key]["ai_target_rank"]
onready var bounce_strength: float = Pro.level_object_profiles[level_object_key]["bounce_strength"]
onready var sprite: Sprite = $Sprite
onready var brick_shadow: Sprite = $BrickShadow


func _ready() -> void:

	sprite.modulate = brick_color
	

func _on_DetectArea_body_entered(body: Node) -> void:

	if body.is_in_group(Ref.group_bolts):
		body.modulate = Color.yellow
		
		
func _on_DetectArea_body_exited(body: Node) -> void:

	if body.is_in_group(Ref.group_bolts): 
		body.modulate = Color.white
