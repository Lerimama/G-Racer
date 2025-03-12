extends Control


#signal countdown_finished
#
#onready var animation_player: AnimationPlayer = $AnimationPlayer
#onready var position_control: Control = $Countdown/PositionControl
#
#
#func _ready() -> void:
#
#	visible = false
#
#
#func start_countdown():
#
#	if Rfs.game_manager.game_settings["start_countdown"]:
#		modulate.a = 0
#		visible = true
#		animation_player.play("countdown_3")
#	else:
#		yield(get_tree().create_timer(0.5), "timeout")
#		emit_signal("countdown_finished") # GM yielda za ta signal
#
#
#func play_countdown_a_sound():
#
##	sound_manager.play_gui_sfx("start_countdown_a")
#	pass
#
#func play_countdown_b_sound():
#
##	sound_manager.play_gui_sfx("start_countdown_b")
#	pass
#
#
#func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
#
#	emit_signal("countdown_finished") # preda štafeto na GM
#	visible = false
