extends Control

var is_open: bool = false
var drivers_limit: int = 4
var start_drivers_count: int = 2

onready var box_container: VFlowContainer = $BoxContainer
onready var focus_btn: Button = $MenuBox/Menu/PlayBtn
onready var home: Node = $"../.."

func _input(event: InputEvent) -> void:

	if is_open and Input.is_action_just_pressed("ui_cancel"):
		close()


func _ready() -> void:

	hide()
	for driver_count in start_drivers_count:
		var box_driver_id = Pfs.DRIVER_ID.values()[driver_count]
		box_container.add_new_driver_box(box_driver_id)

func open():

	focus_btn.grab_focus()
	is_open = true
	show()


func close():

	home.to_main_menu()
	is_open = false
	hide()




func _on_AddBtn_pressed() -> void:

	if box_container.activated_driver_boxes.size() < drivers_limit:
		var added_driver_id: int = box_container.activated_driver_boxes.size()
		box_container.add_new_driver_box(added_driver_id)


func _on_PlayBtn_pressed() -> void:

	Sts.players_on_game_start = []
	Pfs.driver_profiles = {}

	for driver_box in box_container.activated_driver_boxes:
		var driver_id = Pfs.DRIVER_ID.values()[driver_box.driver_index]
		Pfs.driver_profiles[driver_id] = driver_box.driver_profile#.duplicate()
		Sts.players_on_game_start.append(driver_id)
		#		printt("profile", Pfs.driver_profiles[driver_id])
		#	print("drivers ", Sts.players_on_game_start)

	Rfs.ultimate_popup.open_popup()
	yield(get_tree().create_timer(0.1),"timeout")
	Rfs.main_node.call_deferred("home_out")


func _on_CancelBtn_pressed() -> void:

	close()
