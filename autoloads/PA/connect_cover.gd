extends CanvasLayer
# tukaj prebavimo vse morebitne inpute in prikazuje korake procesa


var cover_label_text: String = "" setget _update_label_text # teksti se v celoti sporočajo iz funkcije, ki kliče fazo
var cover_label_text_change_count: int = 0

onready var cover_label: Label = $Label
onready var undi: ColorRect = $Undi

var use_in_background: bool = false


#func _input(event: InputEvent) -> void:
#
#	if visible and not use_in_background: # v nodetu nastavim propagate "stop"
#		get_tree().set_input_as_handled() # kakršen koli input setamo kot da smo ga procesiral


func _ready() -> void:

	cover_label.modulate.a = 0
	undi.modulate.a = 0
	hide()


func open_cover(in_background: bool):

	use_in_background = in_background
	cover_label_text_change_count = 0

	if not use_in_background:
		var fade_in = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
		get_viewport().set_disable_input(true)
		fade_in.tween_callback(self, "show")
		fade_in.tween_property(cover_label, "modulate:a", 1, 0.3)
		fade_in.parallel().tween_property(undi, "modulate:a", 1, 0.3)


func close_cover():

	var fade_out = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(cover_label, "modulate:a", 0, 0.4)
	fade_out.parallel().tween_property(undi, "modulate:a", 0, 0.4)
	fade_out.tween_callback(self, "hide")
	yield(fade_out,"finished")
	get_viewport().set_disable_input(false)



func _update_label_text(new_text: String):

	cover_label_text = new_text
	$Label.text = cover_label_text
	cover_label_text_change_count += 1
