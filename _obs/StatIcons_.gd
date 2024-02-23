extends Node2D


export(int, 1, 5) var default_active_icons # def_stat_value

# colors
var def_stat_color: Color = Color.white setget _on_bolt_color_set
var minus_color: Color = Set.color_red
var plus_color: Color = Set.color_green
var off_color: Color = Set.color_gray0

# toggle time
var color_toggle_time: float = 0 # samo ob prvem prikazu se ikone skrijejo brez tajminga, potem se nastavi ingame time
var ingame_color_toggle_time: float = 1

# values
var current_stat_value: int setget _on_stat_change # ime more bit isto kot v stat.gd

var active_stat_icons: Array
var stat_icons_turned_on: Array

onready var stat_icon_1: Sprite = $StatIcon1
onready var stat_icon_2: Sprite = $StatIcon2
onready var stat_icon_3: Sprite = $StatIcon3
onready var stat_icon_4: Sprite = $StatIcon4
onready var stat_icon_5: Sprite = $StatIcon5


# -------------------------------------------------------------------------------------------------------------------------------


func _ready() -> void:
	
#	printt("name", name, color_toggle_time)

	# najprej vse skrijem
	for child in get_children():
		child.visible = false
	
	# potem določim aktivne
	match default_active_icons:
		1:
			active_stat_icons = [stat_icon_1]
		2:
			active_stat_icons = [stat_icon_1, stat_icon_2]
		3:
			active_stat_icons = [stat_icon_1, stat_icon_2, stat_icon_3]
		4:
			active_stat_icons = [stat_icon_1, stat_icon_2, stat_icon_3, stat_icon_4]
		5:
			active_stat_icons = [stat_icon_1, stat_icon_2, stat_icon_3, stat_icon_4, stat_icon_5]
	
	
	# prikažem vse aktivne
	for icon in active_stat_icons:
		icon.visible = true
	
	# vse aktivne so na začetku prižgane ... ugasnem jih ob signalu iz huda
	stat_icons_turned_on = active_stat_icons
	current_stat_value = stat_icons_turned_on.size()
	
		
		
func _on_stat_change(new_stat_value):
	
	# current_stat_value je število prižganih
	# število, ki jih moram toglat = število trenutno prižganih - število ikon, ki morajo biti prižgane (new_stat_value) = število, ki jih moram ugasnit
	var icons_toggle_count: int = current_stat_value - new_stat_value
	
	# za vsako ikono, ki jo moram toglat
	for icon in abs(icons_toggle_count): 
#		printt("stat_icons", active_stat_icons)
#		printt("turned on", stat_icons_turned_on)
#		printt("new_stat_value", new_stat_value, current_stat_value, icons_toggle_count)
		
		if not active_stat_icons.empty():
			
			
			var icon_to_toggle = stat_icons_turned_on[stat_icons_turned_on.size() - 1] # zadnja ikona od trenutno prižganih

			# če bo šlo navzgor
			if new_stat_value > current_stat_value:
				
				icon_to_toggle.modulate = plus_color
				yield(get_tree().create_timer(color_toggle_time), "timeout")
				icon_to_toggle.modulate = def_stat_color
				
				# dodam med trenutno prižgane
				stat_icons_turned_on.push_back(icon_to_toggle)	
				current_stat_value = stat_icons_turned_on.size()
				
#				color_toggle_time = ingame_color_toggle_time # ob spawnu je 0, da se zgodi na hitro
				
			# če bo šlo navzdol
			elif new_stat_value < current_stat_value:
				
				icon_to_toggle.modulate = minus_color
				yield(get_tree().create_timer(color_toggle_time), "timeout")
				icon_to_toggle.modulate = off_color
				
				# odstranim iz trenutno prižganih
				stat_icons_turned_on.pop_back()	
				current_stat_value = stat_icons_turned_on.size()
	# toggle time postane ingame_toggle_time
	color_toggle_time = ingame_color_toggle_time
				

func _on_bolt_color_set(bolt_color):
	def_stat_color = bolt_color
	
	for icon in active_stat_icons:
		icon.modulate = def_stat_color
