extends HBoxContainer


export var icon_texture: AtlasTexture  # ta se uporabi na vseh ikona

var stat_value: int setget _on_stat_change
var previous_stat_value: int # preverjam smer spremembe lajfa

var def_stat_color: Color = Ref.color_hud_base setget _on_bolt_color_set

onready var stat_icon: Control = $StatIcon
onready var stat_icons: Array = get_children()


func _ready() -> void:
	
	set_icons_state() # preveri lajf na začetku in seta pravilno stanje ikon 
	
	# setam ikono na vse ikone
	for icon in stat_icons:
		icon.get_node("OnIcon").texture = icon_texture
		icon.get_node("OffIcon").texture = icon_texture


func _on_stat_change(new_value: int): # ne rabim parametra

	# setam prev life ... pravi_life count se še ni spremenil
	previous_stat_value = stat_value
	
	# setam current life
	stat_value = new_value
	
	if previous_stat_value == stat_value:
		return
	elif stat_value < previous_stat_value:
		modulate = Ref.color_red
		yield(get_tree().create_timer(0.5), "timeout")
		modulate = def_stat_color
	elif stat_value > previous_stat_value:
		modulate = Ref.color_green
		yield(get_tree().create_timer(0.5), "timeout")
		modulate = def_stat_color
	
	set_icons_state()
	

func set_icons_state():
	
	var loop_index: int = 0	
	for icon in stat_icons:
		loop_index += 1
		if loop_index >= stat_value + 1: # če je ena preveč
			icon.get_node("OnIcon").hide()
			icon.get_node("OffIcon").show()
		else:
			icon.get_node("OnIcon").show()
			icon.get_node("OffIcon").hide()


func _on_bolt_color_set(bolt_color):
	
	def_stat_color = bolt_color
	modulate = def_stat_color
