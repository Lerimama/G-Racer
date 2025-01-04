extends Polygon2D


export (NodePath) var shadow_casting_polygon_path: String
export var node_height: float = 30 # pravo dobi iz parenta ... debelina pomeni debelino sence
export var node_elevation: float = 100 # pravo dobi iz parenta ... dvignjenost pomeni zamik sence

var shadow_color: Color = Color.black
var shadow_transparency: float = 0.2

onready var shadow_casting_node: Node2D = get_node(shadow_casting_polygon_path)
onready var shadow_direction: Vector2 = Refs.game_manager.shadows_direction # odvisno od igre

# owner
onready var shadow_owner: Node2D = get_parent()


func _ready() -> void:

	if shadow_casting_node:
		update_shadows()
	else:
		printerr ("No shadow casting node for: ", self)
		hide()


func _process(delta: float) -> void:

	if shadow_casting_node and visible:
		node_height = shadow_owner.height
		node_elevation = shadow_owner.elevation
		shadow_direction = Refs.game_manager.shadows_direction
		var shadow_polygon: Array = inject_corners(shadow_casting_node.polygon)
		polygon = shadow_polygon
		position += shadow_direction * node_elevation


func update_shadows():

		# trenutne vrednosti
		node_height = shadow_owner.height
		node_elevation = shadow_owner.elevation
		shadow_direction = Refs.game_manager.shadows_direction

		# skrijem, če je vse 0
		if node_height == 0 and node_elevation == 0:
			if visible:
				hide()
		else:
			# popravim rotacijo sence glede na globalno rotacijo poligona
			shadow_direction = shadow_direction.rotated(- global_rotation)
			# oblikujem senco
			var shadow_polygon: Array = inject_corners(shadow_casting_node.polygon)
			polygon = shadow_polygon
			# premaknem še za elevation
			position += shadow_direction * node_elevation
			# LNF
			color = shadow_color
			modulate.a = shadow_transparency
			if not visible:
				show()
#	node_height = shadow_owner.height
#	node_elevation = shadow_owner.elevation
#	shadow_direction = Refs.game_manager.shadows_direction
#	var shadow_polygon: Array = inject_corners(shadow_casting_node.polygon)
#	polygon = shadow_polygon
#	position += shadow_direction * node_elevation


#func _update_shadow(new_direction: Vector2):
#	if shadow_casting_node:
#
#		shadow_direction = new_direction
#
#		var shadow_polygon: Array = inject_new_corners(shadow_casting_node.polygon)
#		polygon = shadow_polygon


func inject_corners(polygon_to_upgrade: Array):
		# deluje če je poligon 4-kotnik (naredi še iskanje skrajnih točke, če ni)

		# premaknem poligon
		position = shadow_direction * node_height

		# opredelim osnovno smer sence in glede na to dodam pike
		if shadow_direction.x >= 0 and shadow_direction.y >= 0: # DOWN RIGHT
			# apliciram nove pike v array pik in ga prenesem v polygon sence
			polygon_to_upgrade.insert(1, polygon_to_upgrade[1] - shadow_direction * node_height)
			polygon_to_upgrade.insert(5, polygon_to_upgrade[4] - shadow_direction * node_height) # pri indexu upoštevam že dodanega
			# premaknem še nevidno (bazno točko)
			polygon_to_upgrade[0] -= shadow_direction * node_height
		elif shadow_direction.x < 0 and shadow_direction.y >= 0: # DOWN LEFT
			polygon_to_upgrade.insert(1, polygon_to_upgrade[0] - shadow_direction * node_height)
			polygon_to_upgrade.insert(3, polygon_to_upgrade[3] - shadow_direction * node_height)
			polygon_to_upgrade[2] -= shadow_direction * node_height
		elif shadow_direction.x >= 0 and shadow_direction.y < 0: # UP RIGHT
			polygon_to_upgrade.insert(3, polygon_to_upgrade[2] - shadow_direction * node_height)
			polygon_to_upgrade.insert(5, polygon_to_upgrade[0] - shadow_direction * node_height)
			polygon_to_upgrade[4] -= shadow_direction * node_height
		elif shadow_direction.x < 0 and shadow_direction.y < 0: # UP LEFT
			polygon_to_upgrade.insert(2, polygon_to_upgrade[1] - shadow_direction * node_height)
			polygon_to_upgrade.insert(4, polygon_to_upgrade[4] - shadow_direction * node_height)
			polygon_to_upgrade[3] -= shadow_direction * node_height


		return polygon_to_upgrade
