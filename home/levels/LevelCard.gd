extends Button


var focus_offset: float = 0
var start_position: Vector2 = Vector2.ZERO

var level_profile: Dictionary = {}
var title: String
var description: String
var thumb_texture: Texture

onready var focused_display: Control = $Focused
onready var unselected_display: Panel = $Deactivated
onready var selected_display: Panel = $Activated

var level_laps_limit: int = 10
onready var laps_btn: Button = $LapsBtn

var mirror_mode: bool = false
onready var mirror_btn: Button = $MirrorBtn
onready var level_preview: ColorRect = $LevelPreview

var is_selected: bool = false setget _change_selected
onready var _enabled_panel: Panel = $_enabled_panel


func _ready() -> void:


	start_position = rect_position
	unselected_display.show()
	focused_display.hide()
	selected_display.hide()
	level_preview.hide()

	if not level_profile.empty(): # naloadane debug nimajo profila
#		prints ("%s level_profile" % level_profile["level_name"])
#		prints (level_profile)
#		prints (level_profile["level_lap_count"])
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

		# btn state
		if not level_profile.empty():
			laps_btn.text = "LAPS: %02d" % level_profile["level_lap_count"]
		if mirror_mode:
			mirror_btn.text = "MIRROR: ON"
		else:
			mirror_btn.text = "MIRROR: OFF"


func _change_selected(new_is_selected: bool):

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

	level_preview.hide()
	focused_display.hide()


func _on_LapsBtn_pressed() -> void:

	level_profile["level_lap_count"] += 1

	if level_profile["level_lap_count"] > level_laps_limit:
		level_profile["level_lap_count"] = 0
	laps_btn.text = "LAPS: %02d" % level_profile["level_lap_count"]


func _on_MirrorBtn_pressed() -> void:

	mirror_mode = not mirror_mode

	if mirror_mode:
		mirror_btn.text = "MIRROR: ON"
	else:
		mirror_btn.text = "MIRROR: OFF"


func _on_PreviewBtn_pressed() -> void:
	pass # Replace with function body.
