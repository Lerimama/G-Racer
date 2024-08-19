extends Area2D
class_name Pickable #, "res://assets/class_icons/pickable_icon.png"




#onready var pickable_value: float = Pro.pickable_profiles[pickable_type_key]["pickable_value"]
#onready var pickable_color: Color = Pro.pickable_profiles[pickable_type_key]["pickable_color"]
#var pickable_type_key: String # seta spawner

#var pickable_value: float
#var pickable_color: Color
#var pickable_altitude: float
var pickable_key_as_name: String # poda ga spawner
onready var pickable_value: float = Pro.pickable_profiles[pickable_key_as_name]["pickable_value"]
onready var pickable_color: Color = Pro.pickable_profiles[pickable_key_as_name]["pickable_color"]
onready var icon_texture: Texture = Pro.pickable_profiles[pickable_key_as_name]["icon_scene"]

onready var pickable_altitude: float = 5 

onready var icon: Sprite = $Icon
onready var sprite: Sprite = $Sprite
onready var detect_area: CollisionPolygon2D = $CollisionPolygon2D
onready var animated_sprite: AnimatedSprite = $AnimatedSprite
onready var pickable_shadow: Sprite = $PickableShadow

#onready var sounds: Node = $Sounds
#onready var sound_picked: AudioStreamPlayer = $Sounds/PickedDefault

func _ready() -> void:
	
	add_to_group(Ref.group_pickables)
	
	icon.texture = icon_texture
	modulate = pickable_color
	pickable_shadow.shadow_distance = pickable_altitude

	
func _on_Item_body_entered(body: Node) -> void:
	
	# če je med soundi kakšen poleg defaultnega, potem zaigraj zadnjega
#	var all_sounds: Array = sounds.get_children()
#	if all_sounds.size() > 1:
#		sound_picked = all_sounds[all_sounds.size() - 1] 
	
	if body.has_method("on_item_picked"):
		if pickable_key_as_name == "BULLET" or pickable_key_as_name == "MISILE" \
		or pickable_key_as_name == "MINA" or pickable_key_as_name == "SHOCKER":
			Ref.sound_manager.play_sfx("pickable_weapon")
		elif pickable_key_as_name == "NITRO":
			Ref.sound_manager.play_sfx("pickable_nitro")
		else:
			Ref.sound_manager.play_sfx("pickable")
			pass
#		sound_picked.play()
		body.on_item_picked(pickable_key_as_name)
#		modulate.a = 0
#		monitorable = false
#		monitoring = false

		queue_free()

#func _on_Picked_finished() -> void:
#	queue_free()	
