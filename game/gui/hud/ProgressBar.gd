extends Panel


var stage_count: int = 1 setget _change_stage_count # checkpoints, laps or goals
var progress_unit: float = 0 setget _change_total_progress

var ticks_x_positions: Array = [] # x

onready var ticks_holder: Control = $Ticks
onready var bar: Panel = $Bar
var bar_color: Color = Color.white

# lahko kažeš barvo ali teksturo
onready var bar_text_background: TextureRect = $Bar/TextureRect
onready var bar_color_background: ColorRect = $Bar/ColorRect

onready var progress_bar_width: float = rect_size.x



func _ready() -> void:

	# debug reset count icon
	for child in ticks_holder.get_children():
		if not child == ticks_holder.get_child(0):
			child.queue_free()

#	bar.rect_size.x = 0


func _change_total_progress(new_progress_unit: float):

	# debug
	if not bar:
		return

	progress_unit = new_progress_unit

	var curr_bar_scale_unit: float = bar.rect_size.x / progress_bar_width
	var new_bar_scale_unit: float = progress_unit * progress_bar_width

	bar.rect_size.x = new_bar_scale_unit
	bar_text_background.rect_size.x = progress_bar_width
	bar_color_background.rect_size.x = progress_bar_width
	bar_color_background.color = bar_color


func _change_stage_count(new_stage_count: int):


	# debug
	if get_parent():#is MarginContainer:
		if get_parent().get_parent():#is MarginContainer:
			get_parent().get_parent().show()
	if not ticks_holder: # debug export
		return

	progress_bar_width = rect_size.x
	stage_count = new_stage_count

	# reset
	var current_ticks: Array = ticks_holder.get_children()
	# template (ga nikoli ne pokažem)
	var template_tick: Control = current_ticks.pop_front()
	template_tick.hide()
	# ticks
	for tick in current_ticks:
		tick.queue_free()
	current_ticks.clear()

	if stage_count > 1: # vsaj 1 tick

		for count in stage_count - 1:
			var new_tick: Control = template_tick.duplicate()
			var separation_width: float = progress_bar_width/stage_count
			new_tick.rect_position.x = separation_width * (count + 1)
			ticks_holder.add_child(new_tick)
			current_ticks.append(new_tick)

		for tick in current_ticks:
			tick.show()

	# ticks on units na novo
	ticks_x_positions.clear()
	for tick in current_ticks:
		ticks_x_positions.append(tick.rect_position.x)
	# dodam še full width pozicijo, čeprav tam ni tika ... za zadnjo fazo
	ticks_x_positions.append(progress_bar_width)


func _on_ProgressBar_resized() -> void:
	# vsakič kose resiza, se ticksi preuredijo

	self.stage_count = stage_count
