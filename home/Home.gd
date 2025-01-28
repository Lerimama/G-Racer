extends Node


onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:

	$UI/MainMenu/PlayBtn.grab_focus()



func _on_PlayBtn_pressed() -> void:

	Rfs.ultimate_popup.open_popup(true)
	yield(get_tree().create_timer(0.1),"timeout")
	Rfs.main_node.call_deferred("home_out")


func _on_QuitBtn_pressed() -> void:

	get_tree().quit()


func _process(delta: float) -> void:
	pass


func _on_AnimationPlayer_animation_finished(animation) -> void:
	pass
