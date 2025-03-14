extends StaticBody2D


export var height: float = 5
export var elevation: float = 0

export var off_color: Color = Color.yellow
export var on_color: Color = Color.green

var turned_on: bool = false
var drivers_in_light_area: Array = []
var level_object_key: int # poda spawner, uravnava vse ostalo

onready var reward_points: float = Pros.level_object_profiles[level_object_key]["value"]
onready var target_rank: int = Pros.level_object_profiles[level_object_key]["target_rank"]
onready var light_2d: Light2D = $Light2D
onready var sprite: Sprite = $Sprite


func _ready() -> void:

	light_2d.color = off_color
	sprite.modulate = off_color


func light_reached(vehicle: Vehicle):

	if not turned_on:
		turned_on = true
		light_2d.color = on_color
		sprite.modulate = Color.white
		vehicle.update_stat(Pros.STATS.POINTS, reward_points)


func _on_DetectArea_body_entered(body: Node) -> void:

	if body.is_in_group(Refs.group_drivers):
		light_reached(body)


func _on_DetectArea_body_exited(body: Node) -> void:

	pass
