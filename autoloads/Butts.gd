extends Node2D


# kadar je hover, je tudi fokus
# sounds + omejitve > focus, confirm, cancel, toggle
# colors > non-btn focus, confirm, cancel, toggle
## first screen focus sfx off:
# - ko klikne "kritični" gumb > se soundi ugasnejo
# - ko se fokusira kontrola, če so soundi ugasnjeni, se po fokusu spet prižgejo soundi
# - grab_focus_nofx() je za izredne primere
## direct-call play_gui_sfx("btn_confirm")
# - confirm popup selection
# - name_input key confirm / cancel
## direct-call grab_focus_nofx direct()
# - HOF on update or publish finished
# - name_input on open ... confirm
# - publish popup open ... publish
# - pauza ... play resume btn


var allow_ui_sfx: bool = false
var group_critical_btns = "Critical btns" # input off group
# select game main btns
# select level btns
# game over quit, replay
# pause quit, restart
var group_cancel_btns = "Cancel btns" # cancel sound group
var group_touch_sound_btns = "Touch sound btns" # cancel sound group
# home sceeens esc
# home exit game
# game-over exit, quit
# pause restart, quit
# publish popup cancel btn
# name_input cancel btn


func _ready():

	# na ready se povežem z vsemi interaktivnimmi kontorlami, ki že obstajajo
	for child in get_tree().root.get_children():
		if child is BaseButton or child is HSlider or child is TouchScreenButton:
			_connect_interactive_control(child)

	# signal iz drevesa na vsak node, ki pride v igro
	get_tree().connect("node_added", self, "_on_SceneTree_node_added")


func grab_focus_nofx(control_to_focus: Control):

	# reset na fokus
	allow_ui_sfx = false
	control_to_focus.grab_focus()
	set_deferred("allow_ui_sfx", true)


func _on_SceneTree_node_added(node: Node): # na ready

	if node is BaseButton or node is HSlider or node is TouchScreenButton:
		_connect_interactive_control(node)



func _connect_interactive_control(node: Node): # and apply start lnf

	if node is Button:
		# hover
		node.connect("mouse_entered", self, "_on_mouse_entered", [node])
		# (de)focus
		node.connect("focus_entered", self, "_on_focus_entered", [node])
		node.connect("focus_exited", self, "_on_focus_exited", [node])

		if node is CheckButton:
			# toggle
			node.connect("toggled", self, "_on_btn_toggled", [node])
		else:
			# press
			node.connect("pressed", self, "_on_btn_pressed", [node])
	elif node is HSlider:
		# hover
		node.connect("mouse_entered", self, "_on_mouse_entered", [node])
		# (de)focus
		node.connect("focus_entered", self, "_on_focus_entered", [node])
		node.connect("focus_exited", self, "_on_focus_exited", [node])
		# slide sfx
		node.connect("value_changed", self, "_on_Slider_value_changed", [node])
	elif node is TouchScreenButton:
		node.connect("pressed", self, "_on_TouchBtn_pressed", [node])

	# setam default stanje
	_set_unfocused_state(node)




# SIGNALS ---------------------------------------------------------------------------------------------------------


func _on_mouse_entered(control: Control):
#	printt("control hovered", control)

	if not control.has_focus() and not control.focus_mode == control.FOCUS_NONE:# and not control is ColorRect
		#		allow_ui_sfx = true # mouse focus je zmeraj s sonundom
		#	control.call_deferred("grab_focus")
		control.grab_focus()


func _on_focus_entered(control: Control):
#	printt("control focused", control)

	if allow_ui_sfx:
		Global.sound_manager.play_gui_sfx("btn_focus_change")
	else:
		set_deferred("allow_ui_sfx", true)

	# color fix - non-regular-btn
	if control is CheckButton or control is HSlider or control.name == "RandomizeBtn" or control.name == "SchemeResetBtn":
		control.modulate = Color.white


func _on_focus_exited(control: Control):
#	printt("control unfocused", control)

	_set_unfocused_state(control)


func _set_unfocused_state(node: Node):

	# settings start barvanje
	if node is CheckButton or node is HSlider or node.name == "RandomizeBtn" or node.name == "SchemeResetBtn":
		node.modulate = Global.color_gui_gray_trans



func _on_btn_pressed(button: BaseButton):
#	printt("btn pressed", button)

#	Analytics.save_ui_click(button)

	if button.is_in_group(group_cancel_btns):
		Global.sound_manager.play_gui_sfx("btn_cancel")
	else:
		Global.sound_manager.play_gui_sfx("btn_confirm")

	if button.is_in_group(group_critical_btns):
		set_deferred("allow_ui_sfx", false)
		get_viewport().set_disable_input(true)


func _on_btn_toggled(button_pressed: bool, button: Button) -> void:
#	printt("btn toggled",button_pressed, button)

	if not str(button) == "[Deleted Object]": # anti home_out nek toggle btn
		if button_pressed:
			Global.sound_manager.play_gui_sfx("btn_confirm")
		else:
			Global.sound_manager.play_gui_sfx("btn_cancel")

#		Analytics.save_ui_click([button, button_pressed])


func _on_Slider_value_changed(slider_value: float, slider_node: HSlider):
#	printt("slider value", slider_value, slider_node)

	# trenutno vrednost opredelim kot procent razpona
	var slider_range: float = slider_node.max_value - slider_node.min_value
	var slider_value_normalized: float = slider_value - slider_node.min_value # normalized ...kot da bi bila min value 0
	var slider_value_percent: float = slider_value_normalized / slider_range
	# ... in jo konvertam v željeni pitch
	var pitch_max_value: float = 1.2
	var pitch_min_value: float = 0.8
	var pitch_percent: float = slider_value_percent
	var pitch_normalized: float = pitch_percent * (pitch_max_value - pitch_min_value)
	var new_pitch: float = pitch_normalized + pitch_min_value

	Global.sound_manager.play_gui_sfx("btn_confirm", new_pitch)


func _on_TouchBtn_pressed(touch_btn: TouchScreenButton):

	if touch_btn.is_in_group(group_touch_sound_btns):
		Global.sound_manager.play_gui_sfx("btn_confirm")
