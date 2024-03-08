extends Area2D
class_name Pickable, "res://assets/class_icons/pickable_icon.png"


enum Pickables {BULLET, MISILE, SHOCKER, SHIELD, ENERGY, GAS, LIFE, NITRO, TRACKING, POINTS, RANDOM} # mešanje zaporedja meša izbrane tipe
export (Pickables) var pickable_type 

var pickable_value: float # = 0 pobere iz profilov
var pickable_type_key: String
var pickable_color: Color # = 0 pobere iz profilov

onready var sprite: Sprite = $Sprite
onready var detect_area: CollisionPolygon2D = $CollisionPolygon2D
onready var animated_sprite: AnimatedSprite = $AnimatedSprite

onready var sound_picked: AudioStreamPlayer = $Sounds/Picked

func _ready() -> void:
	
	add_to_group(Ref.group_pickables)
	pickable_type_key = Pickables.keys()[pickable_type]
	pickable_value = Pro.pickable_profiles[pickable_type_key]["pickable_value"]
	pickable_color = Pro.pickable_profiles[pickable_type_key]["pickable_color"]
	modulate = pickable_color
	
func _on_Item_body_entered(body: Node) -> void:
	
	if body.has_method("on_item_picked"):
		sound_picked.play()
		body.on_item_picked(pickable_type_key)
		queue_free()	
