tool
extends EditorPlugin

var dock

var output_panel
var output_original_parent
var output_label
var output_button
var root

func _enter_tree():
	# Initialization of the plugin goes here
	dock = preload('res://addons/dockable_output/DockableOutput.tscn').instance()
	add_control_to_dock(DOCK_SLOT_RIGHT_UR, dock)
	root = get_tree().get_root()
	while output_panel == null:
		_search_children_for_output(root)
	output_original_parent = output_panel.get_parent()
	output_original_parent.remove_child(output_panel)
	output_panel.show()
	dock.add_child(output_panel)
	output_panel.update()
func _process(delta):
	if output_panel:
		output_panel.show()
	if output_button == null:
		_search_children_for_button(root)
func _search_children_for_button(node):
	if node is ToolButton:
		if node.get('text').find('Output') > -1:
			output_button = node
			output_button.hide()
	else:
		if output_button == null:
			for child in node.get_children():
				_search_children_for_button(child)
func _search_children_for_output(node):
	if node is Label:
		if node.get('text').find('Output:') > -1:
			output_label = node
			output_panel = node.get_parent().get_parent()
			output_label.text = ''
	if output_panel == null:
		for child in node.get_children():
			_search_children_for_output(child)
func _exit_tree():
	# Clean-up of the plugin goes here
	remove_control_from_docks(dock)
	dock.remove_child(output_panel)
	output_label.text = 'Output:'
	output_original_parent.add_child(output_panel)
	dock.free()
	output_button.show()
