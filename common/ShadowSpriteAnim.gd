extends AnimatedSprite


export (NodePath) var shadow_casting_node_path: String
export var node_height: float = 0 # pravo dobi iz parenta ... debelina pomeni debelino sence
export var node_elevation: float = 1 # pravo dobi iz parenta ... dvignjenost pomeni zamik sence

var shadow_color: Color = Color.black
var shadow_transparency: float = 0.2

onready var shadow_casting_node: Node2D = get_node(shadow_casting_node_path)
onready var shadow_direction: Vector2 = Ref.game_manager.game_settings["shadows_direction"] # odvisno od igre


func _ready() -> void:
	
	if shadow_casting_node:
		frames = shadow_casting_node.frames
		playing = shadow_casting_node.playing
		
		update_shadows()
	else:
		printerr ("No shadow casting node on: ", get_parent())
		hide()
	
	
func _process(delta: float) -> void:
	
	frame = 2 # debug
	if shadow_casting_node and visible:
		update_shadows()


func update_shadows():
	
	if node_height == 0 and node_elevation == 0:
		if visible:
			hide()
	else:
		animation = shadow_casting_node.animation
		playing = shadow_casting_node.playing
		
		node_height = owner.height
		node_elevation = owner.elevation + 6
		shadow_direction = Ref.game_manager.shadows_direction
		global_position = shadow_casting_node.global_position - 10 * shadow_direction.rotated(deg2rad(180)) 
		if not visible:
			show()
