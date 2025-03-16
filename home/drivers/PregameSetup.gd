extends Control

var is_open: bool = false
var drivers_limit: int = 4
var start_drivers_count: int = 2
var driver_box_template: Control
var activated_driver_boxes: Array = []

onready var box_container: HBoxContainer = $BoxContainer
onready var focus_btn: Button = $Menu/PlayBtn
onready var home: Node = $"../.."


func _input(event: InputEvent) -> void:

	if is_open and Input.is_action_just_pressed("ui_cancel"):
		close()


func _ready() -> void:

	hide()

	# reset in template
	driver_box_template = Mets.remove_chidren_and_get_template(box_container.get_children())

#	yield(get_tree(), "idle_frame")
	for driver_count in start_drivers_count:
		add_new_driver_box(driver_count)


func open():

	focus_btn.grab_focus()
	is_open = true
	show()


func close():

	home.to_main_menu()
	is_open = false
	hide()


func add_new_driver_box(driver_index):

	var new_driver_box: Control = driver_box_template.duplicate()
	new_driver_box.driver_index = driver_index
	if driver_index == 0:
		new_driver_box.is_ai = false
	box_container.add_child(new_driver_box)

	# prvi je human in ga ne moreš odstranit
	if driver_index == 0:
		new_driver_box.remove_btn.get_parent().hide()
	else:
		new_driver_box.remove_btn.connect("pressed", self, "_on_driver_remove_pressed", [new_driver_box])

	activated_driver_boxes.append(new_driver_box)


func _on_driver_remove_pressed(driver_box_to_remove: Control):

	activated_driver_boxes.erase(driver_box_to_remove)
	driver_box_to_remove.queue_free()


func _on_AddBtn_pressed() -> void:

	if activated_driver_boxes.size() < drivers_limit:
#		var added_driver_index: int = box_container.activated_driver_boxes.size()
		var added_driver_index = activated_driver_boxes.size()
		add_new_driver_box(added_driver_index)


func _on_PlayBtn_pressed() -> void:

	home.play_game()
#	home.home_sound.screen_transition.play()
#	home.home_sound.fade_sounds(home.home_sound.menu, home.home_sound.screen_transition)
#	yield(home.home_sound.screen_transition, "finished")
#	home.home_sound.nitro_intro.play()
#	yield(get_tree().create_timer(5), "timeout")
#	home.home_sound.fade_sounds(home.home_sound.nitro_intro, 5)
#	yield(home.home_sound.nitro_intro, "finished")
#
#	Pros.start_driver_profiles = {}
#
#	for driver_box in activated_driver_boxes:
#		var driver_id: String = driver_box.driver_profile["driver_name_id"]
#		Pros.start_driver_profiles[driver_id] = driver_box.driver_profile#.duplicate()
#
#	Refs.ultimate_popup.open_popup()
#	yield(get_tree().create_timer(0.1),"timeout")
#	Refs.main_node.call_deferred("home_out")


func _on_BackBtn_pressed() -> void:

	close()
