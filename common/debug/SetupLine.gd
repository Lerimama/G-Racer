extends HBoxContainer


var variable_name: String = "NN"
var reset_value: float = 50
var node_to_update: Node2D
var variable_on_node

onready var label: Label = $Label
onready var value_label: Label = $Value
onready var h_slider: HSlider = $HSlider
onready var reset_btn: Button = $ResetBtn


func _ready() -> void:
	
	reset_btn.hide()
	
	
func setup_line(line_name: String, var_name: String, line_value: float, line_node: Node2D ):
	
	variable_name = var_name
	node_to_update = line_node
	reset_value = line_value
	
	label.text = line_name
	value_label.text = str(reset_value)
	if reset_value > (h_slider.max_value - 10):
		h_slider.max_value = reset_value * 3
	h_slider.value = reset_value
			
	show()


func reset_line():
	
	node_to_update.set_deferred(variable_name, reset_value)
	value_label.text = str(reset_value)	
	reset_btn.hide()
	

func _on_HSlider_value_changed(value: float) -> void:
	
	node_to_update.set_deferred(variable_name, value)
	value_label.text = str(value)
	
	if value == reset_value:
		reset_btn.hide()
	else:
		reset_btn.show()


func _on_ResetBtn_pressed() -> void:
	
	reset_line()
