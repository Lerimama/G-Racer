extends Area2D
class_name Pickable #, "res://assets/class_icons/pickable_icon.png"

export var height: float = 0 # PRO
export var elevation: float = 10 # PRO fili

export var pickable_key: int = 0 # OPT... določen za primer, če ga dam manualno v level ... zaporedje iz profilov
#export (Pfs.PICKABLE) var new_pickable_key: int = 0 # ne dela

#var pickable_key: int = placed_pickable_key # če je spawnan v igro, ga poda spawner

onready var pickable_value: float = Pfs.pickable_profiles[pickable_key]["value"]
onready var pickable_color: Color = Pfs.pickable_profiles[pickable_key]["color"]
#onready var icon_texture: Texture = Pfs.pickable_profiles[pickable_key]["icon_scene"]

#onready var elevation: float = Pfs.pickable_profiles[pickable_key]["elevation"]

var ai_target_rank: int = 3
#onready var ai_target_rank: int = Pfs.pickable_profiles[pickable_key]["ai_target_rank"]
onready var icon: Sprite = $Icon
onready var detect_area: CollisionShape2D = $CollisionShape2D
#onready var pickable_shadow: Sprite = $PickableShadow
#onready var detect_area: CollisionPolygon2D = $CollisionPolygon2D
#onready var sounds: Node = $Sounds
#onready var sound_picked: AudioStreamPlayer = $Sounds/PickedDefault
onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:

	add_to_group(Rfs.group_pickables)

#	icon.texture = icon_texture
	modulate = pickable_color
#	pickable_shadow.shadow_distance = pickable_altitude
#	animation_player.play("edge_rotate") # _temp unanimated


func _on_Item_body_entered(body: Node) -> void:

	# če je med soundi kakšen poleg defaultnega, potem zaigraj zadnjega
	#	var all_sounds: Array = sounds.get_children()
	#	if all_sounds.size() > 1:
	#		sound_picked = all_sounds[all_sounds.size() - 1]

	if body.is_in_group(Rfs.group_bolts):
		if Pfs.pickable_profiles.keys().has("pickable_ammo"):
			Rfs.sound_manager.play_sfx("pickable_ammo")
		else:
			Rfs.sound_manager.play_sfx("pickable")
			if pickable_key == Pfs.PICKABLE.PICKABLE_RANDOM:
				var random_range: int = Pfs.pickable_profiles.keys().size() - 1 # izloči random
				var random_pickable_index = randi() % random_range
				pickable_key = Pfs.pickable_profiles.keys()[random_pickable_index]

		printt("pickable", Pfs.PICKABLE.keys()[pickable_key])
		body.on_item_picked(pickable_key)

#	if body.has_method("item_picked"):
#		if pickable_key == Pfs.PICKABLE.PICKABLE_BULLET or pickable_key == Pfs.PICKABLE.PICKABLE_MISILE \
#		or pickable_key == Pfs.PICKABLE.PICKABLE_MINA:
#			Rfs.sound_manager.play_sfx("pickable_ammo")
#		elif pickable_key == Pfs.PICKABLE.PICKABLE_NITRO:
#			Rfs.sound_manager.play_sfx("pickable_nitro")
#		else:
#			Rfs.sound_manager.play_sfx("pickable")
#			pass
#
#		body.item_picked(pickable_key)
#		printt("pickable", Pfs.PICKABLE.keys()[pickable_key])
#		#		body.call_deferred("item_picked", pickable_key)
##		sound_picked.play()
##		modulate.a = 0
##		monitorable = false
##		monitoring = false

	queue_free()


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	print("new_loop")
	pass # Replace with function body.
