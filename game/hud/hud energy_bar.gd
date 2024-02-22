extends HBoxContainer


var energy: int setget _on_amount_change # energija je konveratana v razmerju velikosti bara
var previous_energy: int # preverjam smer spremembe lajfa

onready var tired_energy: int = Global.game_manager.game_settings["player_tired_energy"]
onready var texture_progress: TextureProgress = $TextureProgress


func _ready() -> void:
	
	set_icons_state() # preveri energijo na začetku in seta pravilno stanje ikon 


func _process(delta: float) -> void:
	
	# self.energy = Global.game_manager.player_stats["player_energy"] ... premaknjeno v hud
	pass

	
func _on_amount_change(new_value: int):
	
	# setam prev energy ... prava energija se še ni spremenila
	previous_energy = energy 
	# setam current energy
	energy = new_value
	
	if energy <= tired_energy:
		modulate = Global.color_red
	else:
		if energy < previous_energy:
			var blink_tween = get_tree().create_tween()
			blink_tween.tween_property(self, "modulate", Global.color_red, 0.2)
			blink_tween.tween_property(self, "modulate", Global.hud_text_color, 0.2)
		elif energy > previous_energy:
			modulate = Global.color_green
			var blink_tween = get_tree().create_tween()
			blink_tween.tween_property(self, "modulate", Global.color_green, 0.2)
			blink_tween.tween_property(self, "modulate", Global.hud_text_color, 0.2)
	
	set_icons_state()


func set_icons_state():
	
	texture_progress.value = energy
