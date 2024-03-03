extends Area2D
class_name Pickable, "res://assets/class_icons/pickable_icon.png"


enum Pickables {BULLET, MISILE, SHOCKER, SHIELD, ENERGY, GAS, LIFE, NITRO, TRACKING, RANDOM} # mešanje zaporedja meša izbrane tipe
export (Pickables) var pickable_type 

var pickable_value: float # = 0 pobere iz profilov
var pickable_type_key: String

onready var sprite: Sprite = $Sprite
onready var detect_area: CollisionPolygon2D = $CollisionPolygon2D
onready var animated_sprite: AnimatedSprite = $AnimatedSprite


func _ready() -> void:
	
	add_to_group(Ref.group_pickups)
	pickable_type_key = Pickables.keys()[pickable_type]
	pickable_value = Pro.pickable_profiles[pickable_type_key]["pickable_value"]
	
	
func _on_Item_body_entered(body: Node) -> void:
	
	if body.has_method("on_item_picked"):
		body.on_item_picked(pickable_type_key)
		queue_free()	
