extends Button


var level_id: int
var focus_offset: float = 0
var start_position: Vector2 = Vector2.ZERO

var level_profile: Dictionary = {}
var title: String
var description: String
var thumb_texture: Texture

onready var focused_display: Control = $Focused
onready var unselected_display: Panel = $Deactivated
onready var selected_display: Panel = $Activated

var is_selected: bool = false setget _change_selected


func _ready() -> void:

	start_position = rect_position
	unselected_display.show()
	focused_display.hide()
	selected_display.hide()

	if not level_profile.empty():
		title = level_profile["level_name"]
		thumb_texture = level_profile["level_thumb"]
		description = level_profile["level_desc"]

	if title:
		$Activated/Title.text = title
		$Deactivated/Title.text = title
	if description:
		$Activated/Desc.text = description
		$Deactivated/Desc.text = description

	if thumb_texture:
		$TextureRect.texture = thumb_texture


func _change_selected(new_is_selected: bool):

	if not new_is_selected == is_selected:

		is_selected = new_is_selected

		if is_selected:
			unselected_display.hide()
			selected_display.show()

		else:
			unselected_display.show()
			selected_display.hide()


func _on_LevelBtn_focus_entered() -> void:
#	focused_display.show()
	pass


func _on_LevelBtn_focus_exited() -> void:

	focused_display.hide()
