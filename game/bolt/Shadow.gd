extends Sprite


export var casting_node_name: String  = "CastingNodeName"
var casting_node: Node2D

var shadow_color: Color = Color.black
var shadow_transparency: float = 0.5 

var shadow_direction: Vector2 = Vector2.DOWN # odvisno od igre
var shadow_distance: float = 30 # odvisno od metalca sence


func _ready() -> void:
	
	shadow_direction = Set.game_enviroment_settings["shadow_direction"]
	
#	if casting_node_name == "CastingNodeName":
#		printt ("No casting node on ...", self)
#	else:
#		casting_node = get_parent().get_node(casting_node_name)
#		texture = casting_node.texture
#		if casting_node.region_enabled: # za atlas teksture
#			region_enabled = true
#			region_rect = casting_node.region_rect
	
	
func _process(delta: float) -> void:
	
	if casting_node:
		global_position = casting_node.global_position - shadow_distance * shadow_direction.rotated(deg2rad(180)) # rotated je zato, da je LEFT res levo
