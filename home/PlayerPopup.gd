extends PopupDialog


signal input_finished

var empty_input_text: String = "..."

# ob odprtju glede na kliknjen gumb
var player_id: int
var driver_name: String
var driver_color : Color
var driver_avatar_texture : Texture
var driver_controller_type: int

var bolt_on_open: String
var add_btn_text: String = "ADD PLAYER"
var add_btn_text_alt: String = "CONFIRM"
var off_btn_color: Color = Color("#f2e4c4")
var on_btn_color: Color = Color("#f92c00")

onready var add_btn: Button = $Menu/AddBtn
onready var remove_btn: Button = $Menu/RemoveBtn
onready var line_edit: LineEdit = $LineEdit
onready var color_rect: ColorRect = $ColorRect
onready var bolts: HBoxContainer = $Bolts
onready var controllers: HBoxContainer = $Controllers

var is_activated: bool = false


func _input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("ui_cancel") and visible: # more bit, ker je "exclusive"
		_cancel_input()


func _ready() -> void:

	line_edit.text = empty_input_text

	var ctrl_label_template: Label = controllers.get_child(0).duplicate()
	for child in controllers.get_children():
		child.queue_free()
	for ctrl_type in Pfs.CONTROLLER_TYPE:
		var new_ctrl_label: Label = ctrl_label_template.duplicate()
		new_ctrl_label.text = ctrl_type
		controllers.add_child(new_ctrl_label)
#		if Pfs.driver_profiles[player_id]["controller_type"] == Pfs.CONTROLLER_TYPE.keys().find(ctrl_type):
		if driver_controller_type == Pfs.CONTROLLER_TYPE.keys().find(ctrl_type):
			new_ctrl_label.modulate = on_btn_color
		else:
			for profile in Pfs.driver_profiles:
				if Pfs.driver_profiles[profile]["controller_type"] == Pfs.CONTROLLER_TYPE.keys().find(ctrl_type):
					new_ctrl_label.modulate.a = 0.3
				else:
					new_ctrl_label.modulate = off_btn_color
		if driver_controller_type == Pfs.CONTROLLER_TYPE.keys().find(ctrl_type):
			new_ctrl_label.modulate = on_btn_color
		else:
			# opredeliš zasedene kontrole
			for profile in Pfs.driver_profiles:
				if Pfs.driver_profiles[profile]["controller_type"] == Pfs.CONTROLLER_TYPE.keys().find(ctrl_type):
					new_ctrl_label.modulate.a = 0.3
				else:
					new_ctrl_label.modulate = off_btn_color

	var bolt_label_template: Label = bolts.get_child(0).duplicate()
	for child in bolts.get_children():
		child.queue_free()

	for bolt_type in Pfs.BOLTS:
		var new_bolt_label: Label = bolt_label_template.duplicate()
		new_bolt_label.text = bolt_type
		bolts.add_child(new_bolt_label)

		if Pfs.driver_profiles[player_id]["bolt_type"] == Pfs.BOLTS.keys().find(bolt_type):
			new_bolt_label.modulate = on_btn_color
		else:
			new_bolt_label.modulate = off_btn_color


func _on_PlayerPopup_about_to_show() -> void:

	# line edit text poda odpirač
	line_edit.text = driver_name
	$Avatar.texture = driver_avatar_texture
	color_rect.color = driver_color
	line_edit.select_all()
	add_btn.grab_focus()

	if is_activated:
		remove_btn.show()
		add_btn.text = add_btn_text_alt
	else:
		remove_btn.hide()
		add_btn.text = add_btn_text
		add_btn.show()




func _confirm_input():

	emit_signal("input_finished", line_edit.text, true)
	hide()


func _cancel_input():

	# če je neizpolnjeno, playerja ne doda ali ga remova
#	if line_edit.text == empty_input_text or line_edit.text == "":
#		emit_signal("input_finished", line_edit.text, false)
#	# če je izpolnjeno, ostane nespremenjeno ali doda
#	else:
	emit_signal("input_finished", driver_name, false)
	hide()


func _on_LineEdit_text_entered(new_text: String) -> void:

	add_btn.grab_focus()


func _on_RemoveBtn_pressed() -> void:

#	line_edit.text = ""
	_cancel_input()


func _on_AddBtn_pressed() -> void:

	_confirm_input()
