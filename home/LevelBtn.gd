extends Button


var level_id: int
var focus_offset: float = 0
var start_position: Vector2 = Vector2.ZERO
var on_btn_color: Color = Color("#f2e4c4")
var off_btn_color: Color = Color("#f92c00")

onready var title: Label = $Title
onready var focused_display: Control = $Focused
onready var unfocused_display: Panel = $Unfocused
onready var texture_rect: TextureRect = $TextureRect


func _ready() -> void:

	start_position = rect_position
	#	yield(get_tree(),"idle_frame")
	#	rect_position.y = start_position.y + focus_offset
	focused_display.hide()


func _on_LevelBtn_focus_entered() -> void:

	focused_display.modulate.a = 0
	focused_display.show()

	var slide_tween = get_tree().create_tween()
	slide_tween.tween_property(self, "rect_position:y", rect_position.y - focus_offset, 0.1). set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	slide_tween.parallel().tween_property(unfocused_display, "modulate:a", 0, 0.1)
	slide_tween.parallel().tween_property(focused_display, "modulate:a", 1, 0.1).set_delay(0.1)


func _on_LevelBtn_focus_exited() -> void:

	var slide_tween = get_tree().create_tween()
	slide_tween.tween_property(self, "rect_position:y", start_position.y, 0.1). set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	slide_tween.parallel().tween_property(focused_display, "modulate:a", 0, 0.1)
	slide_tween.parallel().tween_property(unfocused_display, "modulate:a", 1, 0.1).set_delay(0.1)
	slide_tween.tween_callback(focused_display, "hide")
