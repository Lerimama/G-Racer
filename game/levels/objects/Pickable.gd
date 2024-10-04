extends Area2D
class_name Pickable #, "res://assets/class_icons/pickable_icon.png"

export var height: float = 0 # PRO
export var elevation: float = 10 # PRO fili

var pickable_key: int #= Pro.PICKABLE[pickable_key_as_name]# poda ga spawner

onready var pickable_value: float = Pro.pickable_profiles[pickable_key]["value"]
onready var pickable_color: Color = Pro.pickable_profiles[pickable_key]["color"]
onready var icon_texture: Texture = Pro.pickable_profiles[pickable_key]["icon_scene"]
onready var pickable_altitude: float = Pro.pickable_profiles[pickable_key]["altitude"]
onready var ai_target_rank: int = Pro.pickable_profiles[pickable_key]["ai_target_rank"]
onready var icon: Sprite = $Icon
onready var detect_area: CollisionShape2D = $CollisionShape2D
onready var pickable_shadow: Sprite = $PickableShadow
#onready var detect_area: CollisionPolygon2D = $CollisionPolygon2D
#onready var sounds: Node = $Sounds
#onready var sound_picked: AudioStreamPlayer = $Sounds/PickedDefault
onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	
	add_to_group(Ref.group_pickables)
	
#	icon.texture = icon_texture
	modulate = pickable_color
#	pickable_shadow.shadow_distance = pickable_altitude
	animation_player.play("edge_rotate")

	
func _on_Item_body_entered(body: Node) -> void:
	
	# če je med soundi kakšen poleg defaultnega, potem zaigraj zadnjega
	#	var all_sounds: Array = sounds.get_children()
	#	if all_sounds.size() > 1:
	#		sound_picked = all_sounds[all_sounds.size() - 1] 

	if body.has_method("item_picked"):
		if pickable_key == Pro.PICKABLE.PICKABLE_BULLET or pickable_key == Pro.PICKABLE.PICKABLE_MISILE \
		or pickable_key == Pro.PICKABLE.PICKABLE_MINA:
			Ref.sound_manager.play_sfx("pickable_ammo")
		elif pickable_key == Pro.PICKABLE.PICKABLE_NITRO:
			Ref.sound_manager.play_sfx("pickable_nitro")
		else:
			Ref.sound_manager.play_sfx("pickable")
			pass
			
		body.item_picked(pickable_key)
		#		body.call_deferred("item_picked", pickable_key)
#		sound_picked.play()
#		modulate.a = 0
#		monitorable = false
#		monitoring = false
		
		queue_free()
