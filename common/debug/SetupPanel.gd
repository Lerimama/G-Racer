extends VBoxContainer


var setup_lines: Array
onready var setup_layer_line: HBoxContainer = $SetupLayerLine


func _ready() -> void:

	#	Refs.debug_setup_layer = self
	setup_layer_line.hide()


func add_new_line_to_debug(param_variable: String, influence_node: Node2D, param_desc: String):

	var new_line_node = setup_layer_line.duplicate()
	var line_name = influence_node.name + " > " + param_variable
	if not param_desc == "":
		line_name = param_variable + " | " + param_desc

	add_child(new_line_node)

	setup_lines.append(new_line_node)

	new_line_node.call_deferred("set_debug_line", line_name , param_variable, influence_node)

#
func _on_ResetBtn_pressed() -> void:

	for line in setup_lines:
		line.reset_line()

	$ResetBtn.hide()



