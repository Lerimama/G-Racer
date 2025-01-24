extends HBoxContainer


var variable_name: String = "NN"
var default_value: float = 50
var node_to_update: Node2D

onready var label: Label = $Label
onready var value_label: Label = $Value
onready var h_slider: HSlider = $HSlider
onready var reset_btn: Button = $ResetBtn


func _ready() -> void:

	reset_btn.hide()

#	new_line_node.call_deferred("setup_line", line_name , param_variable, influence_node)


func set_debug_line(line_name: String, param_variable: String, influence_node: Node2D):

	variable_name = param_variable
	node_to_update = influence_node
	default_value = influence_node.get(param_variable)

	label.text = line_name + ": "
	value_label.text = str(default_value)

	# adaptacija slider max limit
	if default_value > (h_slider.max_value - 10):
		h_slider.max_value = default_value * 3

	h_slider.value = default_value
	show()


func reset_line():

	node_to_update.set_deferred(variable_name, default_value)
	value_label.text = str(default_value)
	reset_btn.hide()


func _on_HSlider_value_changed(value: float) -> void:

#	node_to_update.set_deferred(variable_name, value)
	node_to_update.set(variable_name, value)
	value_label.text = str(value)

	if value == default_value:
		reset_btn.hide()
	else:
		reset_btn.show()
	get_viewport().set_input_as_handled()


func _on_ResetBtn_pressed() -> void:

	reset_line()
	get_viewport().set_input_as_handled()
