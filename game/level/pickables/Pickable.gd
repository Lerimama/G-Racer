extends Area2D
class_name Pickable

export var height: float = 0
export var elevation: float = 10

export var pickable_key: int = 0 # OPT... določen za primer, če ga dam manualno v level ... zaporedje iz profilov
#export (Pfs.PICKABLE) var new_pickable_key: int = 0 # ne dela
#var pickable_key: int = placed_pickable_key # če je spawnan v igro, ga poda spawner

var ai_target_rank: int = 3
var pickable_value: float = 0
var pickable_color: Color = Color.white

onready var icon: Sprite = $Icon
onready var detect_area: CollisionShape2D = $CollisionShape2D
onready var animation_player: AnimationPlayer = $AnimationPlayer
#onready var icon_texture: Texture = Pfs.pickable_profiles[pickable_key]["icon_scene"]
#onready var sounds: Node = $Sounds
#onready var sound_picked: AudioStreamPlayer = $Sounds/PickedDefault


func _ready() -> void:

	add_to_group(Rfs.group_pickables)

	ai_target_rank = Pfs.pickable_profiles[pickable_key]["ai_target_rank"]
	pickable_color = Pfs.pickable_profiles[pickable_key]["color"]
	pickable_value = Pfs.pickable_profiles[pickable_key]["value"]
	modulate = pickable_color
	#	icon.texture = icon_texture
	#	animation_player.play("edge_rotate") # _temp un-animated


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

#		printt("pickable", Pfs.PICKABLE.keys()[pickable_key])
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
#	print("new_loop")
	pass # Replace with function body.
