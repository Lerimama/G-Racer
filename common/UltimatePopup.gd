extends Popup


onready var undi: ColorRect = $Undi
onready var texture_rect: TextureRect = $TextureRect
onready var label: Label = $Label
onready var animation_player: AnimationPlayer = $AnimationPlayer

var confirm_to_close: bool = false


func _input(event: InputEvent) -> void:

	if visible and confirm_to_close:
#	if confirm_to_close:
		if Input.is_action_just_pressed("ui_cancel"):
			printt("hide", confirm_to_close)
#			hide()
		elif Input.is_action_just_pressed("ui_accept"):
			printt("hide", confirm_to_close)
#			hide()
			get_tree().set_input_as_handled()
		elif Input.is_action_just_pressed("left_click"): # follow leader
			get_tree().set_input_as_handled()


func _ready() -> void:

	Rfs.ultimate_popup = self


func open_popup(confirm_mode: bool = false):

	confirm_to_close = confirm_mode
	popup_centered()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
