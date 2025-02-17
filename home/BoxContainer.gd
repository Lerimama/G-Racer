extends HBoxContainer


var driver_box_template: Control
var start_drivers_count: int = 2

onready var activated_driver_boxes: Array


func _ready() -> void:

	# reset in template
	driver_box_template = Mts.remove_chidren_and_get_template(get_children())


#func add_new_driver_box(driver_index: int):
func add_new_driver_box(driver_index):

	var new_driver_box: Control = driver_box_template.duplicate()
	new_driver_box.driver_index = driver_index
	if driver_index == 0:
		new_driver_box.is_ai = false
	add_child(new_driver_box)

	# prvi je human in ga ne moreš odstranit
	if driver_index == 0:
		new_driver_box.remove_btn.get_parent().hide()
	else:
		new_driver_box.remove_btn.connect("pressed", self, "_on_driver_remove_pressed", [new_driver_box])

	activated_driver_boxes.append(new_driver_box)


func _on_driver_remove_pressed(driver_box_to_remove: Control):

	activated_driver_boxes.erase(driver_box_to_remove)
	driver_box_to_remove.queue_free()


