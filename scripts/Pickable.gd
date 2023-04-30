extends Area2D

class_name Pickable, "res://assets/icons/pickable_icon.png"


enum Pickables {BULLET, MISILE, SHOCKER, SHIELD, ENERGY, LIFE, NITRO, TRACKING, RANDOM} # zaporedje kot na tilesetu (le-d, g-d) ... enako je v slovarju
export (Pickables) var type # = Pickables.SHIELD

var amount: float = 0
var type_name: String
onready var pickable_names = Profiles.Pickables_names # "ključi" so imena
onready var pickable_profil = Profiles.pickable_profiles # ključi so cifre v istem zaporedju
#onready var pickable_profil = Profiles.pickable_profiles # ključi so cifre v istem zaporedju

onready var sprite: Sprite = $Sprite
onready var detect_area: CollisionPolygon2D = $CollisionPolygon2D
onready var animated_sprite: AnimatedSprite = $AnimatedSprite


func _ready() -> void:
	
	amount = pickable_profil[type]["amount"]
	type_name = pickable_names[type] # type je zaporedna številka s katero se izberea v arrayu imen
	
	add_to_group(Config.group_pickups)
#	print (type)
#	print (type_name)
#	print (amount)
	
	
func _process(delta: float) -> void:
	
	pass


func _on_Item_body_entered(body: Node) -> void:
	
	if body.has_method("item_picked"):
		body.item_picked(type_name, amount)
	queue_free()	
