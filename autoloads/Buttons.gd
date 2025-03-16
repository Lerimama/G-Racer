extends Node


# KAJ DODAM?
# vsak hover, postane focus
# dodam sounde na focus
# dodam sounde na confirm, cancel, quit
# dodam modulate na Checkbutton focus

# KAJ POČNEM?
# kadar je hover, je tudi fokus
# focus, confirm, cancel, toggle, slide, ...
# btn SFX + omejitve na fokus
# btn VFX


var allow_focus_sfx: bool = false # focus sounds

onready var btn_cancel_sound_stream: AudioStream = preload("res://assets/sounds/_zaloga/_pa/gui/btn_cancel_NFF-home-switch-off.wav")
onready var btn_accept_sound_stream: AudioStream = preload("res://assets/sounds/_zaloga/_pa/gui/btn_confirm_NFF-home-switch-on.wav")
onready var btn_focus_sound_stream: AudioStream = preload("res://assets/sounds/_zaloga/_pa/gui/btn_focus_change.wav")

var btn_accept_sound: AudioStreamPlayer = AudioStreamPlayer.new()
var btn_cancel_sound: AudioStreamPlayer = AudioStreamPlayer.new()
var btn_focus_sound: AudioStreamPlayer = AudioStreamPlayer.new()
var btn_toggle_on_sound: AudioStreamPlayer = AudioStreamPlayer.new()
var btn_toggle_off_sound: AudioStreamPlayer = AudioStreamPlayer.new()


# povežem "vse node added" signal iz že obstojećih interaktivih kontrol
func _ready():

	# _temp zaenkrat seta home sounds
	#	btn_accept_sound.stream = btn_accept_sound_stream
	#	btn_cancel_sound.stream = btn_cancel_sound_stream
	#	btn_toggle_on_sound.stream = btn_accept_sound_stream
	#	btn_toggle_off_sound.stream = btn_cancel_sound_stream
	#	btn_focus_sound.stream = btn_focus_sound_stream

	for child in get_tree().root.get_children():
		if child is BaseButton\
		or child is HSlider\
		or child is TouchScreenButton\
		or child is LineEdit:
			_connect_interactive_control(child)

	# signal iz drevesa na vsak node, ki pride v igro
	get_tree().connect("node_added", self, "_node_added_to_scene_tree")


# vsak dodan node povežem s potrebnimi signali
# dodanim nodetom opredelim kurzor ikono
func _node_added_to_scene_tree(added_node: Node):
#	prints("added_node", added_node.name)

	if added_node is BaseButton\
	or added_node is HSlider\
	or added_node is TouchScreenButton\
	or added_node is LineEdit:
		_connect_interactive_control(added_node)

	if added_node is Button\
	or added_node is HSlider:
		added_node.set_default_cursor_shape(2) # CURSOR_POINTING_HAND


func _connect_interactive_control(node: Node): # and apply start lnf
#	prints("connected_node", node.name, node.get_class())

	if node is BaseButton:
#	if node is Button:
		# focus
		node.connect("focus_entered", self, "_on_focus_entered", [node])
		node.connect("focus_exited", self, "_on_focus_exited", [node])
		node.connect("mouse_entered", self, "_on_mouse_entered", [node])
		node.connect("mouse_exited", self, "_on_mouse_exited", [node])
		# toggle
		node.connect("toggled", self, "_on_btn_toggled", [node])
		# press
		node.connect("pressed", self, "_on_btn_pressed", [node])
	elif node is LineEdit:
		# focus
		node.connect("mouse_entered", self, "_on_mouse_entered", [node])
		node.connect("focus_entered", self, "_on_focus_entered", [node])
		node.connect("focus_exited", self, "_on_focus_exited", [node])
	elif node is HSlider:
		# focus
		node.connect("mouse_entered", self, "_on_mouse_entered", [node])
		node.connect("focus_entered", self, "_on_focus_entered", [node])
		node.connect("focus_exited", self, "_on_focus_exited", [node])
		# slide
		node.connect("value_changed", self, "_on_Slider_value_changed", [node])
	elif node is TouchScreenButton:
		node.connect("pressed", self, "_on_TouchBtn_pressed", [node])

	# setam default stanje
	#	_set_unfocused_state(node)


# grab_focus_nofx outside call
func grab_focus_nofx(control: Control):

	# reset na fokus
	allow_focus_sfx = false
	control.grab_focus()
	set_deferred("allow_focus_sfx", true)


# SIGNALI INTERAKTIVNIH KONTROL ----------------------------------------------------------------


func _on_mouse_entered(control: Control):
#	printt("control hovered", control)

	# imitira fokus
#	control.emit_signal("focus_entered")
	if not control.has_focus() and not control.focus_mode == control.FOCUS_NONE: # and not control is ColorRect
		allow_focus_sfx = true # mouse focus je zmeraj s sonundom
		control.grab_focus()


func _on_mouse_exited(control: Control):
#	printt("control un-hoverd", control)
	# imitira fokus
#	control.emit_signal("focus_exited")
	pass


func _on_focus_entered(control: Control):
#	printt("control focused", control, btn_focus_sound.is_playing(), btn_focus_sound.volume_db)

	if allow_focus_sfx:
		btn_focus_sound.play()
	else: # ob tranziciji disejblam fokus sound, enejblam, ga ob naslednjem fokusu
		allow_focus_sfx = true


func _on_focus_exited(control: Control): # a rabm?

	control.release_focus()


func _on_btn_pressed(button: BaseButton):
#	printt("btn pressed", button)

	if button.is_in_group(Refs.group_accept_btns):
		btn_accept_sound.play()
	else:
		btn_cancel_sound.play()

	# ob tranziciji disejblam fokus sound, enejblam, ga ob naslednjem fokusu
	if button.is_in_group(Refs.group_transition_btns):
		set_deferred("allow_focus_sfx", false)
		#		get_viewport().set_disable_input(true)


func _on_btn_toggled(button_pressed: bool, button: Button) -> void:
#	printt("btn toggled",button_pressed, button)

	if button_pressed:
		btn_toggle_on_sound.play()
	else:
		btn_toggle_off_sound.play()


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

	btn_toggle_on_sound.play()
	# ... dodaj vairable pitch for sliding ... ex.sound_manager.play_gui_sfx("btn_confirm", new_pitch)


func _on_TouchBtn_pressed(touch_btn: TouchScreenButton):

#	if touch_btn.is_in_group(group_touch_sound_btns):
#		Refs.sound_manager.play_gui_sfx("btn_confirm")
		pass
