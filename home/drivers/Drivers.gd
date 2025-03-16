extends Control

var is_open: bool = false
var drivers_count: int = 2
var drivers_count_limit: int = 4
var activated_driver_boxes: Array = [] # referenca za start_driver_profiles on play()

onready var driver_boxes: HBoxContainer = $DriverBoxes
onready var home: Node = $"../.."
onready var DriverBox: PackedScene = preload("res://home/drivers/DriverBox.tscn")
onready var play_btn: Button = $Menu/PlayBtn
onready var add_btn: Button = $AddBtn
onready var drivers_count_btn: Button = $DriversCountBtn


func _input(event: InputEvent) -> void:

	if is_open and Input.is_action_just_pressed("ui_cancel"):
		close()


func _ready() -> void:

	hide()

	# debug reset
	for box in driver_boxes.get_children():
		box.queue_free()

	for driver_count in drivers_count:
		_add_new_driver_box(driver_count)


func open():

	play_btn.grab_focus()
	is_open = true
	show()


func _check_for_duplicate_ids():

	# če vsa imena niso uniqe
	var activated_players_ids: Array = []
	for driver_box in activated_driver_boxes:
		activated_players_ids.append(driver_box.driver_profile["driver_name_id"])
	var duplicated_players_ids: Array = []
	for driver_id in activated_players_ids:
		if activated_players_ids.count(driver_id) > 1:
			printerr("Duplicate driver names found: ", driver_id)
			if not driver_id in duplicated_players_ids:
				duplicated_players_ids.append(driver_id)
	# vsakemu duplikatu dodam index med vsemi driverji
#	for driver_id in duplicated_players_ids:
#		# ta prvi ne dodam nič
#		var first_id_index: int = duplicated_players_ids.find(driver_id)
#		var first_id: String = duplicated_players_ids[first_id_index]
#		if not driver_id == first_id
#		driver_id +=
#		if activated_players_ids.count(driver_id) > 1:
#			printerr("Duplicate driver names found: ", driver_id)
#			if not driver_id in duplicated_players_ids:
#				duplicated_players_ids.append(driver_id)



func close():


	_check_for_duplicate_ids()

	home.to_main_menu()
	is_open = false
	hide()


func _add_new_driver_box(driver_index):

	var new_driver_box: Control = DriverBox.instance()
	new_driver_box.driver_index = driver_index
	if driver_index == 0:
		new_driver_box.is_ai = false
	driver_boxes.add_child(new_driver_box)

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

	_on_DriversCountBtn_pressed()
#	if activated_driver_boxes.size() < drivers_limit:
#		var added_driver_index = activated_driver_boxes.size()
#		_add_new_driver_box(added_driver_index)


func _on_PlayBtn_pressed() -> void:

	home.play_game()


func _on_BackBtn_pressed() -> void:

	close()


func _on_LevelsBtn_pressed() -> void:

	close()
	home._on_LevelsBtn_pressed()


func _on_DriversCountBtn_pressed() -> void:

	# ... generiraj ai ime
	drivers_count += 1
	if drivers_count <= drivers_count_limit:
		var added_driver_index = activated_driver_boxes.size()
		_add_new_driver_box(added_driver_index)
	else:
		# zbrišem vse razen prve
		for box in driver_boxes.get_children():
			if not driver_boxes.get_children().find(box) == 0:
				activated_driver_boxes.erase(box)
				box.queue_free()
		drivers_count = 1
	drivers_count_btn.text = "DRIVERS COUNT: %d" % drivers_count
