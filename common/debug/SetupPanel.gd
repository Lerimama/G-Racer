extends VBoxContainer


var setup_lines: Array
onready var setup_layer_line: HBoxContainer = $SetupLayerLine


func _ready() -> void:

	Rfs.setup_layer = self
	setup_layer_line.hide()

#
#func build_setup_layer_from_dict(all_lines: Dictionary, lines_owner: Node2D):
#
#	for line in all_lines.keys():
#		var new_line_node = setup_layer_line.duplicate()
#		add_child(new_line_node)
#		setup_lines.append(new_line_node)
#
#	for s_line in setup_lines:
#		var line_index: int =  setup_lines.find(s_line)
#		var line_dictionary_key: String =  all_lines.keys()[line_index]
#		var line_dictionary_value: float =  all_lines[line_dictionary_key]
#		var line_name: String = lines_owner.name + " " + line_dictionary_key
#		s_line.call_deferred("setup_line", line_name, line_dictionary_key, line_dictionary_value, lines_owner)
#		# print(line_dictionary_key, line_dictionary_value, lines_owner)


func add_new_line_to_debug(param_variable: String, influence_node: Node2D, param_desc: String):

	var new_line_node = setup_layer_line.duplicate()
	var line_name = influence_node.name + " > " + param_variable
	if not param_desc == "":
		line_name = param_variable + " | " + param_desc

	add_child(new_line_node)

	setup_lines.append(new_line_node)

	new_line_node.call_deferred("set_debug_line", line_name , param_variable, influence_node)


func _on_ResetBtn_pressed() -> void:

	for line in setup_lines:
		line.reset_line()


func _on_HSlider_drag_ended(value_changed: bool) -> void:

	get_focus_owner().release_focus()
	pass # Replace with function body.
