extends Node


onready var animation_player: AnimationPlayer = $AnimationPlayer
#onready var animacija: AnimationNodeAnimation = $


onready var back_btn: Button = $PauseUI/BackBtn
onready var restart_btn: Button = $PauseUI/RestartBtn
onready var quit_btn: Button = $PauseUI/QuitBtn


func _ready() -> void:

	# main
	back_btn.connect("pressed", self, "_on_back_btn_pressed")
	restart_btn.connect("pressed", self, "_on_restart_btn_pressed")
	quit_btn.connect("pressed", self, "_on_quit_btn_pressed")


func _on_back_btn_pressed():
	animation_player.play("play_in")

func _on_restart_btn_pressed():
	animation_player.play("settings_in")

func _on_quit_btn_pressed():
	Global.switch_to_scene("res://scenes/GameInterface.tscn")


