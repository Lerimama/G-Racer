extends Button


var level_id: int
var focus_offset: float = 0
var start_position: Vector2 = Vector2.ZERO

onready var title: String
onready var description: String
onready var thumb_texture: Texture

onready var focused_display: Control = $Focused
onready var deactivated_display: Panel = $Deactivated
onready var activated_display: Panel = $Activated

var is_activated: bool = false setget _change_activation


func _ready() -> void:

	start_position = rect_position
	deactivated_display.show()
	focused_display.hide()
	activated_display.hide()

	if title:
		$Activated/Title.text = title
		$Activated/Title2.text = title
		$Deactivated/Title.text = title
		$Deactivated/Title2.text = title
	if description:
		$Activated/Desc.text = description
		$Activated/Desc2.text = description
		$Deactivated/Desc.text = description
		$Deactivated/Desc2.text = description

	if thumb_texture:
		$TextureRect.texture = thumb_texture


func _change_activation(new_is_activated: bool):

	if not new_is_activated == is_activated:

		is_activated = new_is_activated

		if is_activated:
			deactivated_display.hide()
			activated_display.show()

		else:
			deactivated_display.show()
			activated_display.hide()


func _on_LevelBtn_focus_entered() -> void:

	focused_display.show()


func _on_LevelBtn_focus_exited() -> void:
	focused_display.hide()
