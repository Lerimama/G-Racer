extends AnimatedSprite


export (NodePath) var shadow_owner_shape_path: String
export var node_height: float = 0 # pravo dobi iz parenta ... debelina pomeni debelino sence
export var node_elevation: float = 1 # pravo dobi iz parenta ... dvignjenost pomeni zamik sence

var shadow_color: Color = Color.black
var shadow_transparency: float = 0.2

onready var shadow_owner_shape: Node2D# = get_node(shadow_owner_shape_path)
onready var shadow_owner: Node2D = get_parent()
onready var shadow_direction: Vector2 = Refs.game_manager.game_shadows_direction

# neu
var imitate_3d: bool = false


func _ready() -> void:

	add_to_group(Refs.group_shadows)

	if shadow_owner_shape_path:
		shadow_owner_shape = get_node(shadow_owner_shape_path)

	if shadow_owner_shape:
		frames = shadow_owner_shape.frames
		playing = shadow_owner_shape.playing
	else:
		hide()


func _process(delta: float) -> void:

	frame = 1 # debug
	if shadow_owner_shape and visible:
		update_shadows()


func update_shadows():

	if node_height == 0 and node_elevation == 0:
		if visible:
			hide()
	else:
		animation = shadow_owner_shape.animation
		playing = shadow_owner_shape.playing

		node_height = shadow_owner.height
		node_elevation = shadow_owner.elevation
		shadow_direction = Refs.game_manager.game_shadows_direction
		global_position = shadow_owner_shape.global_position - node_elevation * shadow_direction.rotated(deg2rad(180))
		if not visible:
			show()
