extends Panel


export (int, 1, 100) var stage_count: int = 1 setget _change_stage_count # checkpoints, laps or goals
export (float, 0, 1, 0.01) var total_progress_unit: float = 0 setget _change_total_progress

var ticks_on_units: Array = []

onready var ticks_holder: HBoxContainer = $Ticks
onready var bar: Panel = $Bar
onready var bar_background: TextureRect = $Bar/TextureRect
onready var bar_separators: Array = [$Ticks/VSeparator, $Ticks/VSeparator_2]


func _ready() -> void:

	# debug reset count icon
	for child in ticks_holder.get_children():
		if not child in bar_separators and not child == ticks_holder.get_child(1):
			child.queue_free()


func _change_total_progress(new_total_progress: float):

	# debug
	if not bar:
		return

	var curr_bar_scale_unit: float = bar.rect_size.x / rect_size.x
	total_progress_unit = new_total_progress
	var new_bar_scale_unit: float = total_progress_unit * rect_size.x
	bar.rect_size.x = new_bar_scale_unit

	bar_background.rect_size.x = rect_size.x


func _change_stage_count(new_stage_count: int):

	# debug
	if get_parent():#is MarginContainer:
		if get_parent().get_parent():#is MarginContainer:
			get_parent().get_parent().show()
	if not ticks_holder: # debug export
		return

	stage_count = new_stage_count

	# reset
	var current_ticks: Array = ticks_holder.get_children()
	# separatorji
	current_ticks.pop_front().hide()
	current_ticks.pop_back().hide()
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
			ticks_holder.add_child(new_tick)
			ticks_holder.move_child(new_tick, ticks_holder.get_child_count() - 2)
			current_ticks.append(new_tick)

		# separators
		#		yield(get_tree(),"idle_frame")
		#		var sepa_separation: float = (rect_size.x / current_ticks.size()) / 2
		#		if stage_count > 2:
		#			for sepa in bar_separators:
		#				var ticks_position_separation: int = abs(current_ticks[0].rect_position.x - current_ticks[1].rect_position.x)
		#				sepa.rect_min_size.x = sepa_separation
		#				sepa.rect_size.x = sepa_separation
		#				sepa.show()

		for tick in current_ticks:
			tick.show()

		# ticks on units na novo
		#	ticks_on_units.clear()
		#	for tick in current_ticks:
		#		ticks_on_units.append(tick.rect_position.x)

