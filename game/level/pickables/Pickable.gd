extends Area2D
class_name Pickable


signal reached_by

export var height: float = 0
export var elevation: float = 10
export var pickable_key: int = 0 # OPT... določen za primer, če ga dam manualno v level ... zaporedje iz profilov
#export (Pfs.PICKABLE) var new_pickable_key: int = 0 # ne dela
#var pickable_key: int = placed_pickable_key # če je spawnan v igro, ga poda spawner
export (AudioStream) var picked_sound_stream: AudioStream

var target_rank: int = 3
var pickable_value: float = 0
var pickable_color: Color = Color.white

onready var icon: Sprite = $Icon
onready var detect_area: CollisionShape2D = $CollisionShape2D
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var picked_sound: AudioStreamPlayer = $Sounds/Picked
onready var collision_shape: CollisionShape2D = $CollisionShape2D



func _ready() -> void:

	add_to_group(Rfs.group_pickables)

	target_rank = Pfs.pickable_profiles[pickable_key]["target_rank"]
	pickable_color = Pfs.pickable_profiles[pickable_key]["color"]
	pickable_value = Pfs.pickable_profiles[pickable_key]["value"]
	modulate = pickable_color

	if picked_sound_stream:
		picked_sound.stream = picked_sound_stream
	#	icon.texture = icon_texture
	#	animation_player.play("edge_rotate")


func _on_Item_body_entered(body: Node) -> void:
#		printt("pickable", Pfs.PICKABLE.keys()[pickable_key])

	if body.is_in_group(Rfs.group_drivers):
		emit_signal("reached_by", self, body)
		picked_sound.play()
		if pickable_key == Pfs.PICKABLE.PICKABLE_RANDOM:
			var random_range: int = Pfs.pickable_profiles.keys().size() - 1 # izloči random
			var random_pickable_index = randi() % random_range
			pickable_key = Pfs.pickable_profiles.keys()[random_pickable_index]

		body.on_item_picked(pickable_key)
		collision_shape.set_deferred("disabled", true)
		hide()



func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	pass # Replace with function body.


func _on_Picked_finished() -> void:

	queue_free()
