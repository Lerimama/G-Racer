extends Node


var drivers_activated: Array
var enemies_mode: bool
var easy_mode: bool
var arena_on = false

onready var animation_player: AnimationPlayer = $AnimationPlayer

# arena
onready var generate_arena_btn: Button = $UI/Arena/GenerateBtn
onready var arena_confirm_btn: Button = $UI/Arena/ConfirmBtn
onready var temp_back_btn: Button = $UI/Arena/temp_BackBtn
# generate
onready var arena_world: PackedScene = preload("res://home/ArenaGenerator.tscn")
onready var arena_view: Panel = $UI/Arena/ArenaView
onready var new_world # : InstancePlaceholder
onready var clean_up_btn: Button = $UI/Arena/CleanUpBtn
# backs
onready var play_btn: Button = $UI/Menus/MainMenu/PlayBtn


func _ready() -> void:

	# arena
	#	clean_up_btn.connect("pressed", self, "_on_clean_up_btn_pressed")
	#	generate_arena_btn.connect("pressed", self, "_on_generate_arena_btn_pressed")
	#	arena_confirm_btn.connect("pressed", self, "_on_arena_confirm_btn_pressed")
	#	arena_back_btn.connect("pressed", self, "_on_arena_back_btn_pressed")

	$UI/Menus/PlayBtn.grab_focus()

func _process(delta: float) -> void:

	pass


func _on_AnimationPlayer_animation_finished(animation) -> void:

	pass


# generate arena
func _on_arena_confirm_btn_pressed():
	animation_player.play("start_game")
func _on_arena_back_btn_pressed():
	arena_on = false
	animation_player.play_backwards("arena_in")
func spawn_generator():
	# spucaj
#	if not new_world == null:
#		new_world.queue_free()
	# spawn walker
	new_world = arena_world.instance()
	new_world.scale *=  0.25
	arena_view.add_child(new_world)
#	new_world.steps_count_limit = 5
	pass
func _on_generate_arena_btn_pressed():
	if not new_world == null:
		spawn_generator()
func _on_clean_up_btn_pressed():
	if not new_world == null:
		new_world.cleanup_map()
func _on_temp_back_btn_pressed():
	animation_player.play_backwards("start_game")




