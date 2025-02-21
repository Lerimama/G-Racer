extends Node2D
# predvsem povezovanja
# z indexi so pomebni


var positions_equiped: Dictionary = {} # "position": "equiped_node"

# z btm
export (NodePath) var btm_front_eqip_path: String
onready var position_btm_front: Position2D = $PositionBtmFront
export (NodePath) var btm_back_eqip_path: String
onready var position_btm_back: Position2D = $PositionBtmBack

# z side
export (NodePath) var downside_left_eqip_path: String
onready var position_downside_left: Position2D = $PositionDownSideLeft
export (NodePath) var downside_right_eqip_path: String
onready var position_downside_right: Position2D = $PositionDownSideRight
export (NodePath) var downside_front_eqip_path: String
onready var position_downside_front: Position2D = $PositionDownSideFront
export (NodePath) var downside_back_eqip_path: String
onready var position_downside_back: Position2D = $PositionDownSideBack

# z upside
export (NodePath) var upside_l_eqip_path: String
onready var position_upside_l: Position2D = $PositionUpsideL
export (NodePath) var upside_r_eqip_path: String
onready var position_upside_r: Position2D = $PositionUpsideR
export (NodePath) var hood_eqip_path: String
onready var position_hood: Position2D = $PositionHood

# z roof
export (NodePath) var roof_left_eqip_path: String
onready var position_roof_left: Position2D = $PositionRoofLeft
export (NodePath) var roof_right_eqip_path: String
onready var position_roof_right: Position2D = $PositionRoofRight
export (NodePath) var roof_eqip_path: String
onready var position_roof: Position2D = $PositionRoof


func _ready() -> void:

	_equip_position(btm_back_eqip_path, position_btm_back)
	_equip_position(btm_front_eqip_path, position_btm_front)
	_equip_position(downside_left_eqip_path, position_downside_left)
	_equip_position(downside_right_eqip_path, position_downside_right)
	_equip_position(downside_front_eqip_path, position_downside_front)
	_equip_position(downside_back_eqip_path, position_downside_back)
	_equip_position(hood_eqip_path, position_hood)
	_equip_position(upside_l_eqip_path, position_upside_l)
	_equip_position(upside_r_eqip_path, position_upside_r)
	_equip_position(roof_left_eqip_path, position_roof_left)
	_equip_position(roof_right_eqip_path, position_roof_right)
	_equip_position(roof_eqip_path, position_roof)


func _equip_position(equip_with_path: NodePath, equip_position: Node2D):

	if equip_with_path and not equip_with_path == "" :
		var equip_node: Node2D = get_node(equip_with_path)
		equip_node.position = equip_position.position
		equip_node.rotation_degrees = equip_position.rotation_degrees
		equip_node.z_index = equip_position.z_index
		positions_equiped[equip_position] = equip_node

		# btm poszicije so nevidne
#		if equip_position.z_index == z_index_btm:
#			equip_node.modulate = 0 # ga ne skrijem, da ne bo kakšen notranji proces brejkan
