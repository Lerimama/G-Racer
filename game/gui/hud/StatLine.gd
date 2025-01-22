extends HBoxContainer

enum STAT_TYPE {COUNT, TIME, ICONS}
export (STAT_TYPE) var stat_type: int = STAT_TYPE.COUNT

export var icon_texture: AtlasTexture = null
export var stat_name: String = ""
export var name_is_icon: bool = false

var stat_value = 0 setget _on_stat_change # : razno
var color_blink_time: float = 0.5
var def_stat_color: Color = Rfs.color_hud_base
var minus_color: Color = Rfs.color_red
var plus_color: Color = Rfs.color_green

onready var stat_icon: TextureRect = $Icon
onready var stat_name_label: Label = $Name
onready var stat_count_label: Label = $Label
onready var stat_time_label: HBoxContainer = $TimeLabel
onready var stat_icons: HBoxContainer = $StatIcons
onready var blink_timer: Timer = $BlinkTimer


# -------------------------------------------------------------------------------------------------------------------------------


func _ready() -> void:

#	stat_count_label.modulate = def_stat_color
#	stat_icon.modulate = def_stat_color

	get_node("Icon").texture = icon_texture
	stat_name_label.text = "%s " % stat_name

	# setup elementov glede na tip
	if name_is_icon:
		stat_icon.show()
		stat_name_label.hide()
	else:
		stat_icon.hide()
		stat_name_label.show()

	stat_name_label.hide()
	stat_time_label.hide()
	stat_count_label.hide()
	stat_icons.hide()
	match stat_type:
		STAT_TYPE.COUNT:
			stat_count_label.show()
		STAT_TYPE.TIME:
			stat_time_label.show()
		STAT_TYPE.ICONS:
			stat_icons.show()
			# setam ikono na vse ikone
			for icon in stat_icons.get_children():
				icon.get_node("OnIcon").texture = icon_texture
				icon.get_node("OffIcon").texture = icon_texture
			set_icons_state(stat_value) # preveri lajf na začetku in seta pravilno stanje ikon


func _on_stat_change(new_stat_value):

	# če je string je sporočilo ... skrijem vse razen sporočila
	if new_stat_value is String:
		stat_count_label.text = new_stat_value
		#			stat_name_label.hide()
#			stat_icon.hide()
		stat_time_label.hide()
		stat_icons.hide()

	# če je številka ga primerjam
	elif new_stat_value is float or new_stat_value is int :

		if not stat_value == new_stat_value:

			if new_stat_value > stat_value:
				modulate = plus_color
			elif new_stat_value < stat_value:
				modulate = minus_color
			stat_value = new_stat_value

			match stat_type:
				STAT_TYPE.COUNT:
					stat_count_label.text = "%02d" % new_stat_value
				STAT_TYPE.TIME:
					write_clock_time(stat_value, stat_time_label)
				STAT_TYPE.ICONS:
					stat_count_label.text = "%02d" % new_stat_value
					set_icons_state(stat_value) # preveri lajf na začetku in seta pravilno stanje ikon

			blink_timer.start(color_blink_time)


func set_icons_state(on_icons_count: int):

	var loop_index: int = 0
	for icon in stat_icons.get_children():
		loop_index += 1
		if loop_index >= on_icons_count + 1: # če je ena preveč in jo odvzame
			icon.get_node("OnIcon").hide()
			icon.get_node("OffIcon").show()
			modulate = minus_color
		else:
			icon.get_node("OnIcon").show()
			icon.get_node("OffIcon").hide()
			modulate = plus_color


func write_clock_time(hundreds: int, time_label: HBoxContainer): # cele stotinke ali ne cele sekunde

	var seconds: float = hundreds / 100.0
	var rounded_minutes: int = floor(seconds / 60) # vse cele sekunde delim s 60
	var rounded_seconds_leftover: int = floor(seconds) - rounded_minutes * 60 # vse sekunde minus sekunde v celih minutah
	var rounded_hundreds_leftover: int = round((seconds - floor(seconds)) * 100) # decimalke množim x 100 in zaokrožim na celo
	# če je točno 100 stotink doda 1 sekundo da stotinke na 0
	if rounded_hundreds_leftover == 100:
		rounded_seconds_leftover += 1
		rounded_hundreds_leftover = 0

	time_label.get_node("Mins").text = "%02d" % rounded_minutes
	time_label.get_node("Secs").text = "%02d" % rounded_seconds_leftover
	time_label.get_node("Hunds").text = "%02d" % rounded_hundreds_leftover


func _on_BlinkTimer_timeout() -> void:

	modulate = def_stat_color
