extends StaticBody2D


export var height: float = 40 # PRO
export var elevation: float = 20 # PRO
export var transparency: float = 1 # PRO

var level_object_key: int # poda spawner, uravnava vse ostalo

onready var brick_color: Color = Pros.level_object_profiles[level_object_key]["color"]
#onready var elevation: float = Pros.level_object_profiles[level_object_key]["elevation"] # PRO elevation profiles
onready var reward_points: float = Pros.level_object_profiles[level_object_key]["value"]
onready var ai_target_rank: int = Pros.level_object_profiles[level_object_key]["ai_target_rank"]
onready var bounce_strength: float = Pros.level_object_profiles[level_object_key]["bounce_strength"]
onready var sprite: Sprite = $Sprite
onready var brick_shadow: Sprite = $BrickShadow


func _ready() -> void:

	sprite.modulate = brick_color


func _on_DetectArea_body_entered(body: Node) -> void:

	if body.is_in_group(Refs.group_bolts):
		body.modulate = Color.yellow


func _on_DetectArea_body_exited(body: Node) -> void:

	if body.is_in_group(Refs.group_bolts):
		body.modulate = Color.white
