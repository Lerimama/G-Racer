extends Sprite


export (NodePath) var shadow_casting_node_path: String
export var node_height: float = 0 # pravo dobi iz parenta ... debelina pomeni debelino sence
export var node_elevation: float = 7 # pravo dobi iz parenta ... dvignjenost pomeni zamik sence
export var shadow_color: Color = Color(Color.black, 1)

onready var shadow_casting_node: Node2D = get_node(shadow_casting_node_path)
onready var shadow_direction: Vector2 = Refs.game_manager.shadows_direction_from_source # odvisno od igre

# owner
onready var shadow_owner: Node2D = owner


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
		node_height = shadow_owner.height
		node_elevation = shadow_owner.elevation
		shadow_direction = Refs.game_manager.shadows_direction_from_source
		global_position = shadow_casting_node.global_position - node_elevation * shadow_direction.rotated(deg2rad(180))
		if not visible:
			show()
