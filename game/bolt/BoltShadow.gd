extends Sprite


export (NodePath) var shadow_casting_node_path: String
var node_height: float = 0 # pravo dobi iz parenta ... debelina pomeni debelino sence
var node_elevation: float = 7 # pravo dobi iz parenta ... dvignjenost pomeni zamik sence
export var shadow_color: Color = Color(Color.black, 0.3)

onready var shadow_casting_node: Node2D = get_node(shadow_casting_node_path)
onready var shadow_direction: Vector2 = Ref.game_manager.game_settings["shadows_direction"] # odvisno od igre


func _ready() -> void:

	if shadow_casting_node:
		update_shadows()
	else:
		printerr ("No shadow casting node on: ", get_parent())
		hide()


func _process(delta: float) -> void:

	if shadow_casting_node and visible:
		update_shadows()


func update_shadows():

	if node_height == 0 and node_elevation == 0:
		if visible:
			hide()
	else:
		modulate = shadow_color
		node_height = owner.height
		node_elevation = owner.elevation
		shadow_direction = Ref.game_manager.shadows_direction
		global_position = shadow_casting_node.global_position - node_elevation * shadow_direction.rotated(deg2rad(180)) 
		if not visible:
			show()
