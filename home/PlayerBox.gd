extends Control


var is_ai: bool = true # spawner prvega spremeni v human
var driver_index: int = 0
var driver_profile: Dictionary = {}

var transform_btn_text: String = "MAKE HUMAN"
var transform_btn_text_alt: String = "MAKE AI"

#onready var transform_btn: Button = $Menu/TransformBtn
#onready var remove_btn: Button = $Menu/RemoveBtn
#onready var line_edit: LineEdit = $LineEdit
#onready var color_rect: ColorRect = $ColorRect
#onready var bolts_node: HBoxContainer = $Bolts
#onready var controllers_node: HBoxContainer = $Controllers
onready var bolts_node: HBoxContainer = $Content/Properties/Bolts/Types

onready var controllers_node: HBoxContainer = $Content/Properties/Controllers/Types


onready var line_edit: LineEdit = $Content/Properties/LineEdit
onready var color_rect: ColorRect = $Content/Properties/ColorRect
onready var avatar: TextureRect = $Content/Properties/Avatar

onready var transform_btn: Button = $Content/Menu/TransformBtn
onready var remove_btn: Button = $Content/Menu/RemoveBtn




func _ready() -> void:

	driver_profile = Pfs.default_driver_profile.duplicate()
	if driver_profile: # debug za tiste, ki so ne spawnani in se na redi spucajo
		if is_ai:
			driver_profile["driver_type"] = Pfs.DRIVER_TYPE.AI
		else:
			driver_profile["driver_type"] = Pfs.DRIVER_TYPE.PLAYER
			driver_profile["driver_name"] = Pfs.names[driver_index]
			driver_profile["driver_avatar"] = Pfs.avatars[driver_index]
		driver_profile["driver_color"] = Pfs.colors[driver_index]

		_set_driver_box()



func _set_driver_box():

	if is_ai:
		avatar.texture = Pfs.ai_profile["ai_avatar"]
		avatar.modulate = Color.red
		line_edit.text = "AI"
		line_edit.editable = false
		$Undi.color = Color.red
		transform_btn.text = transform_btn_text
		transform_btn.show()
	else:
		line_edit.text = driver_profile["driver_name"]
		avatar.texture = driver_profile["driver_avatar"]
		avatar.modulate = Color.white
		line_edit.editable = true
		$Undi.color = Color.black
		transform_btn.text = transform_btn_text_alt
		remove_btn.show()

	color_rect.color = driver_profile["driver_color"]
	_set_driver_controller()
	_set_driver_bolt()


func _set_driver_controller():

	var btn_template: Button = Mts.remove_chidren_and_get_template(controllers_node.get_children())
	var ai_controller_index: int = Pfs.CONTROLLER_TYPE.values().back()

	if is_ai:
		var new_btn = btn_template
		new_btn.text = "AI" #Pfs.CONTROLLER_TYPE.keys().back()
		controllers_node.add_child(new_btn)
		new_btn.disabled = true
	else:
		for ctrl_index in Pfs.CONTROLLER_TYPE.size():
			var new_btn: Button = btn_template.duplicate()
			new_btn.text = Pfs.CONTROLLER_TYPE.keys()[ctrl_index]
			controllers_node.add_child(new_btn)
			new_btn.modulate = Color.white
			new_btn.connect("toggled", self, "_on_controller_btn_toggled", [new_btn])

		yield(get_tree(), "idle_frame")
		controllers_node.get_children()[driver_profile["controller_type"]].set_deferred("pressed", true)


func _set_driver_bolt():

	var btn_template: Button = Mts.remove_chidren_and_get_template(bolts_node.get_children())

	for bolt_type in Pfs.BOLTS:
		var new_btn: Button = btn_template.duplicate()
		new_btn.text = bolt_type
		bolts_node.add_child(new_btn)
		new_btn.connect("toggled", self, "_on_bolt_btn_toggled", [new_btn])

	yield(get_tree(), "idle_frame")
	bolts_node.get_children()[driver_profile["bolt_type"]].set_deferred("pressed", true)


func _on_controller_btn_toggled(is_pressed: bool, btn: Button):

	if is_pressed:
		for controller_btn in controllers_node.get_children():
			if not controller_btn == btn:
				controller_btn.disabled = false
				controller_btn.pressed = false
		btn.disabled = true

		driver_profile["controller_type"] = controllers_node.get_children().find(btn)



func _on_bolt_btn_toggled(is_pressed: bool, btn: Button):

	if is_pressed:
		for bolt_btn in bolts_node.get_children():
			if not bolt_btn == btn:
				bolt_btn.disabled = false
				bolt_btn.pressed = false
		btn.disabled = true

		driver_profile["bolt_type"] = bolts_node.get_children().find(btn)


func _on_TransformBtn_pressed() -> void:

	is_ai = not is_ai

	if is_ai:
		driver_profile["driver_type"] = Pfs.DRIVER_TYPE.AI
	else:
		driver_profile["driver_type"] = Pfs.DRIVER_TYPE.PLAYER
		driver_profile["driver_avatar"] = Pfs.avatars[driver_index]

	_set_driver_box()


func _on_LineEdit_text_changed(new_text: String) -> void:

	driver_profile["driver_name"] = new_text
