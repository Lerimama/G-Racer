extends Node


# GLOBAL NODES

var node_creation_parent = null	# variabla setana na NULL pomeni, da trenutno je "nič", isto uporabimo za na objektu, če ga želimo zbrisat 


# uporaba -> Global.node_creation_parent = self # na ready funkciji se določi, da je dotična scena node_creation_parent

#var player_manager = null	# variabla setana na NULL pomeni, da trenutno je "nič"
var weapon_manager = null
var game_manager = null
var game_profiles = null
var player_profiles = null
#var player = null	# čekiraš plejerja, če je prisoten, trenutno ne uporabljam (a sploh dela za vse plejerje

# INSTANCE NODE

func instance_node (node, location, direction, parent):

	var node_instance = node.instance()
	parent.add_child(node_instance) # instance je uvrščen v določenega starša
	node_instance.global_position = location
	node_instance.global_rotation = direction # dodal samostojno

	node_instance.set_name(str(node_instance.name))  # dodal samostojno, da nima generičnega imena  z @ znakci
	print("ustvarjen node: %s" % node_instance.name)

	return node_instance
#	add_child manjka?

# uporaba -> var bullet = instance_node(bullet_instance, global_position, get_parent()) -> bullet.scale = Vector(1,1)



# RANDOM POSITION ----------------------------------------------------------------------------------

func get_random_position(): # to funkcijo napišemo, da bo vrnila naključno pozicijo na ekranu

	randomize() # vedno če hočeš randomizirat
	var random_position = Vector2(rand_range(50, get_viewport().size.x - 100), rand_range(50, get_viewport().size.y - 100))
	return random_position

# uporaba -> object.global_position = Global.get_random_position()

func get_random_rotation(): # to funkcijo napišemo, da bo vrnila naključno pozicijo na ekranu

	randomize() # vedno če hočeš randomizirat
	var random_rotation = rand_range(-3, 3)
	return random_rotation


# GET DIRECTION ------------------------------------------------------------------------------------

func get_direction_to (A_position, B_position):

	var x_to_B = B_position.x - A_position.x
	var y_to_B = B_position.y - A_position.y

	var A_direction_to_B = atan2(y_to_B, x_to_B)

	return A_direction_to_B


# GET DISTANCE -------------------------------------------------------------------------------------

func get_distance_to (A_position, B_position):

	var x_to_B = B_position.x - A_position.x
	var y_to_B = B_position.y - A_position.y

	var A_distance_to_B = sqrt ((y_to_B * y_to_B) + (x_to_B * x_to_B))

	return A_distance_to_B


# GENERATE TIMER -----------------------------------------------------------------------------------

#var timer # if "onready var" We cache the children should we need to access them again
#var timer_target

func get_universal_timer(timer_name, timer_func_target, function_name):

	timer_name = Timer.new()
	timer_name.set_one_shot(false)
#	timer.set_timer_process_m	ode(TIMER_PROCESS_IDLE)
#	timer.set_wait_time(2)
#	timer.connect("timeout", self, "_timer_callback")
#	timer.start()
	timer_name.connect("timeout", timer_func_target, function_name)
	timer_func_target.add_child(timer_name)

#	timer_name.start(5)

func unisex_print(print_location : Node, print_variable_name, print_variable):

	print("")
	print("Iz: " + str(print_location.name))
	print("--------------------------------------------------")
	print(print_variable_name)
	print(print_variable)
	print("")


# INSTANCE FROM TILEMAPS ---------------------------------------------------------------------------

#func create_instance_from_tilemap(coord:Vector2, prefab:PackedScene, parent: Node2D, origin_zamik:Vector2 = Vector2.ZERO):	# primer dobre prakse ... static typing
#	print("COORD")
#	print(coord)
#	$BrickSet.set_cell(coord.x, coord.y, -1 )	# zbrišeš trenutni tile tako da ga zamenjaš z indexom -1 (prazen tile)
#	var pf = prefab.instance()
#	pf.position = $BrickSet.map_to_world(coord) - origin_zamik
#	parent.add_child(pf)
#	print("COORD")
#	print(coord)


# SHAKE --------------------------------------------------------------------------------------------

#var shake_amount : float
#
#func shake (new_shake, shake_time = 0.4, shake_limit = 100):
#	shake_amount += new_shake
#	if shake_amount > shake_limit:
#		shake_amount = shake_limit

#TOLE BI LAHKO DODAL -------------------------------------------------------------------------------

# var rng = RandomNumberGenerator.new()

#func wrap():
#	if position.x < 0:
#		position.x = velikost_ekrana.x
#	if position.x > velikost_ekrana.x:
#		position.x = 0
#	if position.y < 0:
#		position.y = velikost_ekrana.y
#	if position.y > velikost_ekrana.y:
#		position.y = 0
