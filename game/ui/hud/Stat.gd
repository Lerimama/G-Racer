extends HBoxContainer

export var icon_texture: AtlasTexture  # ta se uporabi

var def_stat_value: int = 0
var current_stat_value: int = 0 setget _on_stat_change

# colors
var def_stat_color: Color = Color.white setget _on_bolt_color_set
var minus_color: Color = Set.color_red
var plus_color: Color = Set.color_green
var color_blink_time: float = 0.5

onready var stat_icon: TextureRect = $Icon
onready var stat_label: Label = $Label


# -------------------------------------------------------------------------------------------------------------------------------


func _ready() -> void:
	
#	def_stat_color = get_parent().stat_line_color
	stat_label.modulate = def_stat_color
	stat_icon.modulate = def_stat_color
	
	get_node("Icon").texture = icon_texture
	
func _on_stat_change(new_stat_value):
	
	# če je string ga ne primerjam s trnutnim
	if new_stat_value is String:
		stat_label.text = str(new_stat_value)
#		stat_label.modulate = plus_color
#		yield(get_tree().create_timer(color_blink_time), "timeout")
#		stat_label.modulate = def_stat_color
	else:
		# če bo šlo navzgor
		if new_stat_value > current_stat_value:
			current_stat_value = new_stat_value
			stat_label.modulate = plus_color
			stat_label.text = "%02d" % new_stat_value
			yield(get_tree().create_timer(color_blink_time), "timeout")
			stat_label.modulate = def_stat_color
		# če bo šlo navzdol
		elif new_stat_value < current_stat_value:
			current_stat_value = new_stat_value
			stat_label.modulate = minus_color
			stat_label.text = "%02d" % new_stat_value
			yield(get_tree().create_timer(color_blink_time), "timeout")
			stat_label.modulate = def_stat_color


func _on_bolt_color_set(bolt_color):
	
	def_stat_color = bolt_color
	stat_label.modulate = def_stat_color
	stat_icon.modulate = def_stat_color
