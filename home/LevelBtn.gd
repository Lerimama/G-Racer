extends Button


var level_id: int
var focus_offset: float = 0
var start_position: Vector2 = Vector2.ZERO
var on_btn_color: Color = Color("#f2e4c4")
var off_btn_color: Color = Color("#f92c00")

onready var title: Label = $Title
onready var focused_display: Control = $Focused
onready var deactivated_display: Panel = $Deactivated
onready var activated_display: Panel = $Activated
onready var texture_rect: TextureRect = $TextureRect

var is_activated: bool = false setget _change_activation


func _ready() -> void:

	start_position = rect_position
	#	yield(get_tree(),"idle_frame")
	#	rect_position.y = start_position.y + focus_offset
	deactivated_display.show()
	focused_display.hide()
	activated_display.hide()


func _change_activation(new_is_activated: bool):

	if not new_is_activated == is_activated:

		is_activated = new_is_activated

		if is_activated:
			deactivated_display.hide()
#			focused_display.hide()
			activated_display.show()
#			focused_display.modulate.a = 0
#			focused_display.show()
#
#			var slide_tween = get_tree().create_tween()
#			slide_tween.tween_property(self, "rect_position:y", rect_position.y - focus_offset, 0.1). set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
#			slide_tween.parallel().tween_property(unfocused_display, "modulate:a", 0, 0.1)
#			slide_tween.parallel().tween_property(focused_display, "modulate:a", 1, 0.1).set_delay(0.1)

		else:
			deactivated_display.show()
#			focused_display.show()
			activated_display.hide()

#			var slide_tween = get_tree().create_tween()
#			slide_tween.tween_property(self, "rect_position:y", start_position.y, 0.1). set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
#			slide_tween.parallel().tween_property(focused_display, "modulate:a", 0, 0.1)
#			slide_tween.parallel().tween_property(unfocused_display, "modulate:a", 1, 0.1).set_delay(0.1)
#			slide_tween.tween_callback(focused_display, "hide")


func _on_LevelBtn_focus_entered() -> void:
	var home_node: Node = get_parent().get_parent().get_parent()

	if not home_node.home_screen == home_node.HOME_SCREEN.LEVELS:
		home_node._on_LevelsBtn_pressed()
		grab_focus()

	focused_display.show()
	pass


func _on_LevelBtn_focus_exited() -> void:
	focused_display.hide()
	pass


func _on_LevelBtn_pressed() -> void:
	pass
#	self.is_activated = not is_activated
