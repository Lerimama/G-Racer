extends Node2D
# predvsem povezovanja
# z indexi so pomebni

var z_index_btm: int = 0
var z_index_side: int = 1
var z_index_top: int = 2
var z_index_roof: int = 3

# z btm
onready var weapon_position_btm_back: Position2D = $WeaponPositionBtmBack
onready var weapon_position_btm_front: Position2D = $WeaponPositionBtmFront
# z side
onready var weapon_position_side_left: Position2D = $WeaponPositionSideLeft
onready var weapon_position_side_right: Position2D = $WeaponPositionSideRight
onready var weapon_position_side_front: Position2D = $WeaponPositionSideFront
onready var weapon_position_side_back: Position2D = $WeaponPositionSideBack
# z top
onready var weapon_position_top_l: Position2D = $WeaponPositionTopL
onready var weapon_position_top_r: Position2D = $WeaponPositionTopR
onready var weapon_position_hood: Position2D = $WeaponPositionHood
# z roof
onready var weapon_position_roof_left: Position2D = $WeaponPositionRoofLeft
onready var weapon_position_roof_right: Position2D = $WeaponPositionRoofRight
onready var weapon_position_roof: Position2D = $WeaponPositionRoof

weapon_position_btm_back
weapon_position_btm_front
weapon_position_side_left
weapon_position_side_right
weapon_position_side_front
weapon_position_side_back
weapon_position_top_l
weapon_position_top_r
weapon_position_hood
weapon_position_roof_left
weapon_position_roof_right
weapon_position_roof


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

