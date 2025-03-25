extends Control

var is_open: bool = false
var drivers_count: int = 2
var drivers_count_limit: int = 4
var activated_driver_boxes: Array = [] # referenca za start_driver_profiles on play()

onready var driver_boxes: HBoxContainer = $DriverBoxes
onready var home: Node = $"../.."
onready var DriverBox: PackedScene = preload("res://home/drivers/DriverBox.tscn")
onready var play_btn: Button = $Menu/PlayBtn
onready var drivers_count_btn: Button = $SubMenu/DriversCountBtn
onready var view_mode_btn: Button = $SubMenu/ViewModeBtn
onready var add_btn: Button = $SubMenu/AddBtn


func _input(event: InputEvent) -> void:

	if is_open and Input.is_action_just_pressed("ui_cancel"):
		close()


func _ready() -> void:

	# debug reset
	for box in driver_boxes.get_children():
		box.queue_free()

	for driver_count in drivers_count:
		_add_new_driver_box(driver_count)

	hide()

	# btn states
	drivers_count_btn.text = "DRIVERS COUNT: %d" % drivers_count
	if Sets.mono_view_mode:
		view_mode_btn.text = "VIEW MODE: SPLIT"
	else:
		view_mode_btn.text = "VIEW MODE: MONO"


func open():

	play_btn.grab_focus()
	is_open = true
	show()


func close():

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
	# ostale povežeš z remove gumbom
	else:
		new_driver_box.remove_btn.connect("pressed", self, "_on_driver_remove_pressed", [new_driver_box])

	activated_driver_boxes.append(new_driver_box)


func _on_driver_remove_pressed(driver_box_to_remove: Control):

	activated_driver_boxes.erase(driver_box_to_remove)
	driver_box_to_remove.queue_free()


func _check_for_duplicate_ids(): # ne rabim zaenkrat
	# ne dela, ker pravi da A in A nista enaka
	# izgleda, da ndeluje super tudi z duplikati

	var activated_players_ids: Array = []
	for driver_box in activated_driver_boxes:
		var curr_name_id: String = driver_box.driver_profile["driver_name_id"]
		# če je enak name_id že notri, mu dodam zaporedno številko enakega idja
		# spremembo apliciram v driver profil in driver box
		if curr_name_id in activated_players_ids:
			var same_name_ids_count: int = activated_players_ids.count(curr_name_id)
			curr_name_id += "_%d" % same_name_ids_count
			driver_box.driver_profile["driver_name_id"] = curr_name_id
			printerr("Duplicate driver_id turned to uniq: ", curr_name_id, " ", driver_box.driver_profile["driver_name_id"])
		activated_players_ids.append(curr_name_id)


func _on_AddBtn_pressed() -> void:

	_on_DriversCountBtn_pressed()


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
	# reset na 1, če je več kot limit
	else:
		# zbrišem vse razen prve
		for box in driver_boxes.get_children():
			if not driver_boxes.get_children().find(box) == 0:
				activated_driver_boxes.erase(box)
				box.queue_free()
		drivers_count = 1
	drivers_count_btn.text = "DRIVERS COUNT: %d" % drivers_count


func _on_ViewModeBtn_pressed() -> void:

	Sets.mono_view_mode = not Sets.mono_view_mode

	if Sets.mono_view_mode:
		view_mode_btn.text = "VIEW MODE: SPLIT"
	else:
		view_mode_btn.text = "VIEW MODE: MONO"
