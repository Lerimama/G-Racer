extends Node2D


var tag_owner: Node
var cell_size_x: float = Global.current_tilemap.cell_size.x
var vertical_offset: float = cell_size_x

onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var label: Label = $Tag/Label


func _ready() -> void:

	modulate.a = 1
	
	if global_position.y < 2 * cell_size_x:
		animation_player.play("show_tag_downwards")
		vertical_offset = 0
	else:	
		animation_player.play("show_tag")
	
	# KVEFRI je v animaciji


func _physics_process(delta: float) -> void:
	
	if tag_owner:
		global_position = tag_owner.global_position - Vector2(cell_size_x/2, vertical_offset)
