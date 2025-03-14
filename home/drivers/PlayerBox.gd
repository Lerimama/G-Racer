extends Control


var is_ai: bool = true # spawner prvega spremeni v human
var driver_index: int = 0
#var driver_index
var driver_profile: Dictionary = {}

var transform_btn_text: String = "MAKE HUMAN"
var transform_btn_text_alt: String = "MAKE AI"

onready var controllers_node: VBoxContainer = $Content/Properties/Controllers/Types
onready var line_edit: LineEdit = $Content/LineEdit
onready var transform_btn: Button = $Content/Menu/TransformBtn
onready var remove_btn: Button = $Content/Menu/RemoveBtn
onready var drivers_node: VBoxContainer = $Content/Properties/Drivers/Types
onready var color_rect: ColorRect = $Content/ColorRect
onready var avatar_btn: TextureButton = $Content/AvatarBtn


func _ready() -> void:

	driver_profile = Pros.default_driver_profile.duplicate()
	if driver_profile: # debug za tiste, ki so ne spawnani in se na redi spucajo
		if is_ai:
			driver_profile["driver_type"] = Pros.DRIVER_TYPE.AI
			driver_profile["driver_avatar"] = Pros.ai_profile["ai_avatar"]
			driver_profile["driver_name_obs"] = Pros.ai_profile["ai_name"]
			driver_profile["driver_color"] = Pros.colors[driver_index]
		else:
			driver_profile["driver_type"] = Pros.DRIVER_TYPE.PLAYER
			driver_profile["driver_name_obs"] = Pros.names[driver_index]
			driver_profile["driver_avatar"] = Pros.avatars[driver_index]
			driver_profile["driver_color"] = Pros.colors[driver_index]

		_set_driver_box()


func _set_driver_box():

	color_rect.color = driver_profile["driver_color"]
	avatar_btn.texture_normal = driver_profile["driver_avatar"]
	line_edit.text = driver_profile["driver_name_obs"]

	if is_ai:
		avatar_btn.modulate = Color.red
		avatar_btn.disabled = true
		avatar_btn.focus_mode = Control.FOCUS_NONE
		line_edit.editable = false
		line_edit.focus_mode = Control.FOCUS_NONE
		$Undi.modulate.a = 0.5
		transform_btn.text = transform_btn_text
		transform_btn.show()
	else:
		avatar_btn.modulate = Color.white
		avatar_btn.disabled = false
		avatar_btn.focus_mode = Control.FOCUS_ALL
		line_edit.editable = true
		line_edit.focus_mode = Control.FOCUS_ALL
		$Undi.modulate.a = 1
		transform_btn.text = transform_btn_text_alt
		remove_btn.show()

	_set_driver_controller()
	_set_driver_vehicle()


func _set_driver_controller():

	var btn_template: Button = Mets.remove_chidren_and_get_template(controllers_node.get_children())
	var ai_controller_index: int = Pros.CONTROLLER_TYPE.values().back()

	if is_ai:
		var new_btn = btn_template
		new_btn.text = "AI" #Pros.CONTROLLER_TYPE.keys().back()
		controllers_node.add_child(new_btn)
		new_btn.disabled = true
		new_btn.focus_mode = Control.FOCUS_NONE
	else:
		for ctrl_type in Pros.CONTROLLER_TYPE.values():
			var new_btn: Button = btn_template.duplicate()
			new_btn.text = Pros.CONTROLLER_TYPE.keys()[ctrl_type]
			controllers_node.add_child(new_btn)
			new_btn.disabled = false
			new_btn.focus_mode = Control.FOCUS_ALL
			new_btn.modulate = Color.white
			new_btn.connect("pressed", self, "_on_controller_btn_pressed", [new_btn])

			if not driver_profile["controller_type"] == ctrl_type:
				new_btn.hide()


func _set_driver_vehicle():

	var btn_template: Button = Mets.remove_chidren_and_get_template(drivers_node.get_children())

	for vehicle_type in Pros.VEHICLE.values():
		var new_btn: Button = btn_template.duplicate()
		new_btn.text = Pros.VEHICLE.keys()[vehicle_type]
		drivers_node.add_child(new_btn)
		new_btn.connect("pressed", self, "_on_driver_btn_pressed", [new_btn])

		if not driver_profile["vehicle_type"] == vehicle_type:
			new_btn.hide()

		if is_ai:
			new_btn.disabled = true
			new_btn.focus_mode = Control.FOCUS_NONE
		else:
			new_btn.disabled = false
			new_btn.focus_mode = Control.FOCUS_ALL


func _on_controller_btn_pressed(btn: Button):

	var next_btn_index: int = controllers_node.get_children().find(btn) + 1
	if next_btn_index > controllers_node.get_child_count() - 1:
		next_btn_index = 0

	driver_profile["controller_type"] = next_btn_index
	controllers_node.get_child(next_btn_index).show()
	controllers_node.get_child(next_btn_index).grab_focus()
	btn.hide()



func _on_driver_btn_pressed(btn: Button):

	var next_btn_index: int = drivers_node.get_children().find(btn) + 1
	if next_btn_index > drivers_node.get_child_count() - 1:
		next_btn_index = 0

	drivers_node.get_child(next_btn_index).show()
	driver_profile["vehicle_type"] = next_btn_index
	drivers_node.get_child(next_btn_index).grab_focus()
	btn.hide()



func _on_TransformBtn_pressed() -> void:

	is_ai = not is_ai

	if is_ai:
		driver_profile["driver_type"] = Pros.DRIVER_TYPE.AI
		driver_profile["driver_avatar"] = Pros.ai_profile["ai_avatar"]
		driver_profile["driver_name_obs"] = Pros.ai_profile["ai_name"]
	else:
		driver_profile["driver_type"] = Pros.DRIVER_TYPE.PLAYER
		driver_profile["driver_name_obs"] = Pros.names[driver_index]
		driver_profile["driver_avatar"] = Pros.avatars[driver_index]
		driver_profile["driver_color"] = Pros.colors[driver_index]
	_set_driver_box()


func _on_LineEdit_text_changed(new_text: String) -> void:

	driver_profile["driver_name_obs"] = new_text


func _on_AvatarBtn_pressed() -> void:

	var next_avatar_index: int = Pros.avatars.find(driver_profile["driver_avatar"]) + 1
	if next_avatar_index > Pros.avatars.size() - 1:
		next_avatar_index = 0

	driver_profile["driver_avatar"] = Pros.avatars[next_avatar_index]
	avatar_btn.texture_normal = driver_profile["driver_avatar"]


func _on_AvatarBtn_focus_exited() -> void:

#	avatar_btn.get_node("Edge").hide()
	pass

func _on_AvatarBtn_focus_entered() -> void:

#	avatar_btn.get_node("Edge").show()
	pass
