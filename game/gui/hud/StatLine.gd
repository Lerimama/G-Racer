tool
extends HBoxContainer

enum STAT_TYPE {COUNT, TIME, ICONS}
export (STAT_TYPE) var stat_type: int = STAT_TYPE.COUNT

export var icon_texture: Texture = null
export var stat_name: String = ""
export var name_is_icon: bool = false

var stat_value = 0 setget _on_stat_change # : razno
var color_blink_time: float = 0.5

var icon_off_color: Color = Color(Color.white, 0.3)
var icon_on_color: Color = Color(Color.white, 1)

onready var def_stat_color: Color = Rfs.color_hud_base
onready var minus_color: Color = Rfs.color_red
onready var plus_color: Color = Rfs.color_green

onready var stat_icon: TextureRect = $Icon
onready var stat_name_label: Label = $Name
onready var stat_count_label: Label = $Label
onready var stat_time_label: HBoxContainer = $TimeLabel
onready var count_icons_holder: HBoxContainer = $CountIcons
onready var blink_timer: Timer = $BlinkTimer


func _ready() -> void:

	# stat icon
	get_node("Icon").texture = icon_texture
	# stat name
	stat_name_label.text = "%s " % stat_name

	# debug reset count icon
	for child in count_icons_holder.get_children():
		child.queue_free()

	# name or icon
	if name_is_icon and icon_texture:
		stat_icon.show()
		stat_name_label.hide()
	elif not stat_name.empty():
		stat_icon.hide()
		stat_name_label.show()

	match stat_type:
		STAT_TYPE.COUNT:
			stat_count_label.show()
			stat_time_label.hide()
			count_icons_holder.hide()
		STAT_TYPE.TIME:
			stat_count_label.hide()
			stat_time_label.show()
			count_icons_holder.hide()
		STAT_TYPE.ICONS:
			stat_count_label.hide()
			stat_time_label.hide()
			count_icons_holder.show()
			# name lebel, icon
			stat_icon.hide()
			stat_name_label.hide()


func _on_stat_change(new_stat_value):

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
			STAT_TYPE.TIME:
				pass
			STAT_TYPE.ICONS:
				_set_icons_state(stat_value) # preveri lajf na začetku in seta pravilno stanje ikon

	# če je številka ga primerjam
	elif new_stat_value is float or new_stat_value is int :
		match stat_type:
			STAT_TYPE.COUNT:
				stat_count_label.text = "%02d" % new_stat_value
			STAT_TYPE.TIME:
				write_clock_time(stat_value, stat_time_label)
			STAT_TYPE.ICONS:
				_set_icons_state(stat_value) # preveri lajf na začetku in seta pravilno stanje ikon

	stat_value = new_stat_value


func _set_icons_state(count_value):

	# count_value + max_count_value?
	var max_count_value: int = 0
	if count_value is Array:
		max_count_value = count_value[1]
		var current_count_value: int = count_value[0]
		count_value = current_count_value
#	max_count_value = 5
#	count_value = 2

	# stat value icons
	if max_count_value == 0:
		var count_difference: int = count_value - count_icons_holder.get_child_count()
		# ker je ena že notri, jo samo skrivam ... je templejt
		if count_difference > 0:
			for count in count_difference:
				var new_icon: TextureRect = TextureRect.new()
				new_icon.texture = icon_texture
				count_icons_holder.add_child(new_icon)
		elif count_difference < 0:
			for count in abs(count_difference):
				#				count_icons_holder.get_child(count).queue_free()
				count_icons_holder.get_children().back().queue_free() # testni način
	# stat value / max value icons
	else:
		# če je max manjši od count_value
		if max_count_value < count_value:
			max_count_value = count_value

		# če ni pravilno število ikon
		var max_count_difference: int = max_count_value - count_icons_holder.get_child_count()
		if max_count_difference > 0:
			for count in max_count_difference: # templejt je že notri
				var new_icon: TextureRect = TextureRect.new()
				new_icon.texture = icon_texture
				count_icons_holder.add_child(new_icon)
		elif max_count_difference < 0:
			for count in abs(max_count_difference):
				count_icons_holder.get_child(count).queue_free()

		# lnf
		for icon_index in count_icons_holder.get_child_count():
			if icon_index < count_value:
				count_icons_holder.get_child(icon_index).modulate = icon_on_color
			else:
				count_icons_holder.get_child(icon_index).modulate = icon_off_color


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
