extends PopupDialog


signal input_finished

var empty_input_text: String = "..."
var text_on_open: String
var color_on_open : Color

onready var color_rect: ColorRect = $ColorRect
onready var line_edit: LineEdit = $LineEdit


func _input(event: InputEvent) -> void:

	if visible:
		if Input.is_action_just_pressed("ui_cancel"):
			_cancel_input()

		elif Input.is_action_just_pressed("ui_confirm"):
			_confirm_input()
#
func _ready() -> void:

	line_edit.text = empty_input_text


func _cancel_input():

	# če je neizpolnjeno, playerja ne doda ali ga remova
	if line_edit.text == empty_input_text or line_edit.text == "":
		emit_signal("input_finished", "")
	# če je izpolnjeno ostane nespremenjeno ali doda
	else:
		emit_signal("input_finished", text_on_open)
	hide()


func _on_PlayerPopup_about_to_show() -> void:

	# line edit text poda odpirač
	line_edit.text = text_on_open
	color_rect.color = color_on_open
	line_edit.select_all()
	line_edit.grab_focus()


func _confirm_input():

	emit_signal("input_finished", line_edit.text)
	hide()


func _on_LineEdit_text_entered(new_text: String) -> void:
	_confirm_input()


func _on_RemoveBtn_pressed() -> void:

	line_edit.text = ""
	_cancel_input()
