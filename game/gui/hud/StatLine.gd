tool
extends HBoxContainer

enum STAT_TYPE {COUNT, TIME_HUND, TIME_SEC, ICONS}
export (STAT_TYPE) var stat_type: int = STAT_TYPE.COUNT

export var icon_texture: Texture = null
export var stat_name: String = ""
export var name_as_icon: bool = true
export (int, 0, 10) var count_digits_size: int = 0 # če je 1 vpliva na timer > kaže eno hunds decimalko

var stat_value = 0 setget _on_stat_change # : razno
var color_blink_time: float = 0.5

var icon_off_color: Color = Color(Color.white, 0.3)
var icon_on_color: Color = Color(Color.white, 1)
var digits_size_string: String = "%" + "d"

onready var def_stat_color: Color = Refs.color_hud_base
onready var minus_color: Color = Refs.color_red
onready var plus_color: Color = Refs.color_green

onready var mid_separator: VSeparator = $VSeparator
onready var stat_icon: TextureRect = $Icon
onready var stat_name_label: Label = $Name
onready var stat_count_label: Label = $Label
onready var stat_time_label: HBoxContainer = $TimeLabel
onready var blink_timer: Timer = $BlinkTimer
onready var count_icons_holder: HBoxContainer = $CountIcons


func _ready() -> void:

	# debug reset count icon
	for child in count_icons_holder.get_children():
		child.queue_free()
	#	yield(get_tree(), "idle_frame") ... zankrat ne rabim

	# stat icon
	stat_icon.texture = icon_texture
	stat_name_label.text = "%s " % stat_name

	# digit count
	if count_digits_size > 0:
		digits_size_string = "%0" + str(count_digits_size) + "d"

	# name or icon
	if name_as_icon and icon_texture:
		stat_icon.show()
		stat_name_label.hide()
		mid_separator.show()
	else:
		if stat_name.empty():
			stat_name_label.hide()
			stat_icon.hide()
			mid_separator.hide()
		else:
			stat_icon.hide()
			stat_name_label.show()
			mid_separator.show()


	match stat_type:
		STAT_TYPE.COUNT:
			stat_count_label.show()
			stat_time_label.hide()
			count_icons_holder.hide()
		STAT_TYPE.TIME_HUND:
			stat_time_label.show()
			for label in stat_time_label.get_children():
				label.show()
			stat_count_label.hide()
			count_icons_holder.hide()
		STAT_TYPE.TIME_SEC:
			stat_time_label.show()
			# krijem stotinke
			stat_time_label.get_children().back().hide()
			stat_count_label.hide()
			count_icons_holder.hide()
		STAT_TYPE.ICONS:
			stat_time_label.hide()
			stat_count_label.hide()
			stat_icon.hide()
			if name_as_icon:
				stat_name_label.hide()
				mid_separator.hide()
			_update_count_icons()


func _on_stat_change(new_stat_value):
#	if name == "StatWins":
#		print("new_stat_value ", name, new_stat_value)

	# če je string je sporočilo ... skrijem vse razen sporočila
	if new_stat_value is String:
		stat_count_label.text = new_stat_value
		stat_time_label.hide()
		count_icons_holder.hide()

	# če je array je ponavadi količina in max količina
	elif new_stat_value is Array:
		match stat_type:
			STAT_TYPE.COUNT:
				stat_count_label.text = str(new_stat_value[0]) + "/" + str(new_stat_value[1]) # +1 ker kaže trnenutnega, ne končanega
			STAT_TYPE.TIME_HUND, STAT_TYPE.TIME_SEC:
				_write_clock_time(new_stat_value[0], stat_time_label)
			STAT_TYPE.ICONS:
				_update_count_icons(new_stat_value[0], new_stat_value[1]) # preveri lajf na začetku in seta pravilno stanje ikon

	# če je številka ga primerjam
	elif new_stat_value is float or new_stat_value is int:

		match stat_type:
			STAT_TYPE.COUNT:
				stat_count_label.text = digits_size_string % new_stat_value
			STAT_TYPE.TIME_HUND, STAT_TYPE.TIME_SEC:
				_write_clock_time(new_stat_value, stat_time_label)
			STAT_TYPE.ICONS: # recimo healthbar
				if new_stat_value is float: # ponavadi procent
					var stat_value_percent: int = round(new_stat_value * 10)
					var max_percent_value: int = 10
					new_stat_value = [stat_value_percent, max_percent_value]
				_update_count_icons(new_stat_value) # preveri lajf na začetku in seta pravilno stanje ikon

	# aplciram novi value
	stat_value = new_stat_value


func _update_count_icons(count_value = 0, max_count_value: int = 0):
#	count_value = randi() % 5
#	max_count_value =  randi() % 5 + 2
#	max_count_value =  0
#	count_value = 1
#	if name == "StatWins":
#		printt ("max_count_difference", self, self.get_parent().get_parent().get_parent(), count_value, max_count_value)


	var count_icon_texture: Texture = stat_icon.texture

	# curr only
	if max_count_value == 0:
		var count_difference: int = count_value - count_icons_holder.get_child_count()
		# premalo ikon
		if count_difference > 0:
			for count in count_difference:
				var new_icon: TextureRect = TextureRect.new()
				new_icon.texture = count_icon_texture
				count_icons_holder.add_child(new_icon)
				new_icon.modulate = icon_on_color
		# preveč ikon
		elif count_difference < 0:
			for count in abs(count_difference):
				count_icons_holder.get_child(count).queue_free()

	# curr / max
	else:
		# če je max manjši od count_value
		if max_count_value < count_value:
			max_count_value = count_value
		# premalo ikon
		var max_count_difference: int = max_count_value - count_icons_holder.get_child_count()
		if max_count_difference > 0:
			for count in max_count_difference: # templejt je že notri
				var new_icon: TextureRect = TextureRect.new()
				new_icon.texture = count_icon_texture
				count_icons_holder.add_child(new_icon)
		# preveč ikon
		elif max_count_difference < 0:
			for count in abs(max_count_difference):
				count_icons_holder.get_child(count).queue_free()

		# lnf
		for icon_index in count_icons_holder.get_child_count():
			if icon_index < count_value:
				count_icons_holder.get_child(icon_index).modulate = icon_on_color
			else:
				count_icons_holder.get_child(icon_index).modulate = icon_off_color


func _write_clock_time(hundreds: int, time_label: HBoxContainer): # cele stotinke ali ne cele sekunde

	var seconds: float = hundreds / 100.0
	var rounded_minutes: int = floor(seconds / 60) # vse cele sekunde delim s 60
	var rounded_seconds_leftover: int = floor(seconds) - rounded_minutes * 60 # vse sekunde minus sekunde v celih minutah
	var rounded_hundreds_leftover: int = round((seconds - floor(seconds)) * 100) # decimalke množim x 100 in zaokrožim na celo

	# če je točno 100 stotink doda 1 sekundo da stotinke na 0
	if rounded_hundreds_leftover == 100:
		rounded_seconds_leftover += 1
		rounded_hundreds_leftover = 0

	time_label.get_node("MinSec/Mins").text = "%02d" % rounded_minutes
	time_label.get_node("MinSec/Secs").text = "%02d" % rounded_seconds_leftover
	time_label.get_node("Hunds/Hunds").text = "%02d" % rounded_hundreds_leftover

	# hunds display settings
	if count_digits_size == 1:
		time_label.get_node("Hunds").rect_min_size.x = 44
		time_label.get_node("Hunds/Hunds").visible_characters = 1
	else:
		time_label.get_node("Hunds").rect_min_size.x = 68
		time_label.get_node("Hunds/Hunds").visible_characters = -1


func _on_BlinkTimer_timeout() -> void:

	modulate = def_stat_color
