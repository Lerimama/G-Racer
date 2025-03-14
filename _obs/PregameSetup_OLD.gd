extends Control

onready var menu: VBoxContainer = $Menu
onready var focus_btn: Button = $Menu/ConfirmBtn

func _ready() -> void:
	hide()


func open():

	show()
	focus_btn.grab_focus()


func close():

	hide()


func _on_ConfirmBtn_pressed() -> void:

	Rfs.ultimate_popup.open_popup()
	menu.hide()
	yield(get_tree().create_timer(0.1),"timeout")
	Rfs.main_node.call_deferred("home_out")


func _on_CancelBtn_pressed() -> void:
	hide()
