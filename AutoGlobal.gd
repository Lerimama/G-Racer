extends Node

# GLOBAL NODES
var level_tilemap = null
var node_creation_parent = null
var effects_creation_parent = null
var current_camera = null
var game_manager = null
#var player_manager = null	# variabla setana na NULL pomeni, da trenutno je "nič"
#var weapon_manager = null
#var game_profiles = null
#var player_profiles = null
#var player = null	# čekiraš plejerja, če je prisoten, trenutno ne uporabljam (a sploh dela za vse plejerje

onready var indikator: PackedScene = preload("res://indikator.tscn")
# spawn indikator

func spawn_indikator(pos, rot): # neki ne štima
	
	var new_indikator = indikator.instance()
	new_indikator.global_position = pos
	new_indikator.global_rotation = rot
#	new_indikator.global_position = bolt_sprite.global_position + pos
#	new_indikator.global_rotation = bolt_sprite.global_rotation
	new_indikator.modulate = Color.red
	Global.node_creation_parent.add_child(new_indikator)
	
#	print(new_indikator.new_indikator.global_position)
	pass


# Changing scenes is most easily done using the functions `change_scene`
# and `change_scene_to` of the SceneTree. This script demonstrates how to
# change scenes without those helpers.

func goto_scene(path):
	# This function will usually be called from a signal callback,
	# or some other function from the running scene.
	# Deleting the current scene at this point might be
	# a bad idea, because it may be inside of a callback or function of it.
	# The worst case will be a crash or unexpected behavior.

	# The way around this is deferring the load to a later time, when
	# it is ensured that no code from the current scene is running:
	call_deferred("_deferred_goto_scene", path)


func _deferred_goto_scene(path):
	# Immediately free the current scene, there is no risk here.
	get_tree().get_current_scene().free()

	# Load new scene
	var packed_scene = ResourceLoader.load(path)

	# Instance the new scene
	var instanced_scene = packed_scene.instance()

	# Add it to the scene tree, as direct child of root
	get_tree().get_root().add_child(instanced_scene)

	# Set it as the current scene, only after it has been added to the tree
	get_tree().set_current_scene(instanced_scene)


# OLD ------------------------------------------------------------------------------


## INSTANCE NODE
#
#func instance_node (node, location, direction, parent):
#
#	var node_instance = node.instance()
#	parent.add_child(node_instance) # instance je uvrščen v določenega starša
#	node_instance.global_position = location
#	node_instance.global_rotation = direction # dodal samostojno
#
#	node_instance.set_name(str(node_instance.name))  # dodal samostojno, da nima generičnega imena  z @ znakci
#	print("ustvarjen node: %s" % node_instance.name)
#
#	return node_instance
##	add_child manjka?
#
## uporaba -> var bullet = instance_node(bullet_instance, global_position, get_parent()) -> bullet.scale = Vector(1,1)
#
#
#
## RANDOM POSITION ----------------------------------------------------------------------------------
#
#func get_random_position(): # to funkcijo napišemo, da bo vrnila naključno pozicijo na ekranu
# 
#	randomize() # vedno če hočeš randomizirat
#	var random_position = Vector2(rand_range(50, get_viewport_rect().size.x - 100), rand_range(50, get_viewport_rect().size.y - 100))
#	return random_position
#
## uporaba -> object.global_position = Global.get_random_position()
#
#func get_random_rotation(): # to funkcijo napišemo, da bo vrnila naključno pozicijo na ekranu
#
#	randomize() # vedno če hočeš randomizirat
#	var random_rotation = rand_range(-3, 3)
#	return random_rotation
#
#
## GET DIRECTION ------------------------------------------------------------------------------------
#
#func get_direction_to (A_position, B_position):
#
#	var x_to_B = B_position.x - A_position.x
#	var y_to_B = B_position.y - A_position.y
#
#	var A_direction_to_B = atan2(y_to_B, x_to_B)
#
#	return A_direction_to_B
#
#
## GET DISTANCE -------------------------------------------------------------------------------------
#
#func get_distance_to (A_position, B_position):
#
#	var x_to_B = B_position.x - A_position.x
#	var y_to_B = B_position.y - A_position.y
#
#	var A_distance_to_B = sqrt ((y_to_B * y_to_B) + (x_to_B * x_to_B))
#
#	return A_distance_to_B
#
#
## INSTANCE FROM TILEMAPS ---------------------------------------------------------------------------
#
##func create_instance_from_tilemap(coord:Vector2, prefab:PackedScene, parent: Node2D, origin_zamik:Vector2 = Vector2.ZERO):	# primer dobre prakse ... static typing
##	print("COORD")
##	print(coord)
##	$BrickSet.set_cell(coord.x, coord.y, -1 )	# zbrišeš trenutni tile tako da ga zamenjaš z indexom -1 (prazen tile)
##	var pf = prefab.instance()
##	pf.position = $BrickSet.map_to_world(coord) - origin_zamik
##	parent.add_child(pf)
##	print("COORD")
##	print(coord)
