## ---------------------------------------------------------------------------------------------
## 
## KAJ DOGAJA
## - spawna plejerje in druge entitete v areni
## - spavna levele
## - uravnava potek igre (uvaljevlja pravila)
## - je centralna baza za vso statistiko igre
## - povezava med igro in HUDom
##
## KAJ NE ...
## - nima povezave z izgradnjo levela
## 
## ---------------------------------------------------------------------------------------------

extends Node


signal stat_change_received (player_index, changed_stat, stat_new_value)
signal new_bolt_spawned # (name, ...)

# players
var player1_id = "P1"
var player2_id = "P2"
var player3_id = "P3"
var player4_id = "P4"
var enemy_id = "E1"
var bolts_in_game: Array
var spawned_bolt_index: int = 0

var pickables_in_game: Array
var available_pickable_positions: Array

onready var player1_profile = Profiles.default_player_profiles[player1_id]
onready var player2_profile = Profiles.default_player_profiles[player2_id]
onready var player3_profile = Profiles.default_player_profiles[player3_id]
onready var player4_profile = Profiles.default_player_profiles[player4_id]
onready var enemy_profile = Profiles.default_player_profiles[enemy_id]

onready var tilemap_floor_cells: Array
onready var navigation_line: Line2D = $"../NavigationPath"
onready var enemy: KinematicBody2D = $"../Enemy"

onready var player_bolt = preload("res://scenes/bolt/Player.tscn")
onready var enemy_bolt = preload("res://scenes/bolt/Enemy.tscn")

# slovar vseh plejerjev
var game_stats: Dictionary = {
	"round": 0,
	"winner_id": "NN",
	"final_score": 0,
}



	


	
func _ready() -> void:
	
	Global.game_manager = self	
#	$Enemy.connect("path_changed", self, "_on_Enemy_path_changed") # za prikaz linije, drugače ne rabiš
	pass

func _input(event: InputEvent) -> void:
#func _unhandled_key_input(event: InputEventKey) -> void:


	if Input.is_action_just_released("ui_cancel"):	
		print("juhej")
	var ppp1 = null

	if bolts_in_game.size() < 4:
		# P1
		if Input.is_key_pressed(KEY_1):
			spawn_bolt(player_bolt, get_parent().get_global_mouse_position(), player1_id, Global.ppp1)
		# P2
		if Input.is_key_pressed(KEY_2):
			spawn_bolt(player_bolt, get_parent().get_global_mouse_position(), player2_id, Global.ppp2)
		# P3
		if Input.is_key_pressed(KEY_3):
			spawn_bolt(player_bolt, get_parent().get_global_mouse_position(), player3_id, Global.ppp3)
		# P4
		if Input.is_key_pressed(KEY_4):
			spawn_bolt(player_bolt, get_parent().get_global_mouse_position(), player4_id, Global.ppp4)
		# Enemi
		if Input.is_key_pressed(KEY_5):
			spawn_bolt(enemy_bolt, get_parent().get_global_mouse_position(), enemy_id, Global.ppp4)
	
	if Input.is_action_just_pressed("x"):
		spawn_pickable()
		
	if Input.is_action_just_pressed("r"):
		restart()


func _process(delta: float) -> void:
	bolts_in_game = get_tree().get_nodes_in_group(Config.group_bolts)
	pickables_in_game = get_tree().get_nodes_in_group(Config.group_pickups)	


func spawn_bolt(bolt, spawned_position, spawned_player_id, ppp):
	
	
	spawned_bolt_index += 1
	
	var new_bolt = bolt.instance()
	new_bolt.bolt_id = spawned_player_id
	new_bolt.global_position = spawned_position
	Global.node_creation_parent.add_child(new_bolt)

	new_bolt.look_at(Vector2(320,180)) # rotacija proti centru ekrana
	
	# camera follor temp
	Global.node_creation_parent.camera_follow_target = new_bolt
	
	
	ppp = new_bolt
	
	# če je plejer komp mu pošljem navigation area
	if new_bolt == enemy_bolt:
		new_bolt.navigation_cells = tilemap_floor_cells

	# prikaz nav linije
	new_bolt.connect("path_changed", self, "_on_Enemy_path_changed")
	# statistika
	new_bolt.connect("stat_changed", self, "_on_Stat_changed") # za prikaz linije, drugače ne rabiš
	
	# ustvarimo statistiko plejerja ...duplikat defaulta
	var spawned_player_stats = Profiles.default_player_stats.duplicate()
	# statistiko plejerja damo v slovar vseh statistik
	game_stats[spawned_player_id] = spawned_player_stats
	
	emit_signal("new_bolt_spawned", spawned_bolt_index, spawned_player_id) # pošljem na hud, da prižge stat line in ga napolne
	
	
func spawn_pickable():
	
	
	# uteži
	if not available_pickable_positions.empty():
#		print(available_pickable_positions.size())

		var pickables_array = Profiles.Pickables_names # samo za evidenco pri debugingu

		# žrebanje tipa
		var pickables_dict = Profiles.pickable_profiles
		var selected_pickable_index: int = Global.get_random_member_index(pickables_dict)
		var selected_pickable_name = Profiles.Pickables_names[selected_pickable_index]
		var selected_pickable_path = pickables_dict[selected_pickable_index]["path"]

		# žrebanje pozicije
		var selected_cell_index: int = Global.get_random_member_index(tilemap_floor_cells)
		var selected_cell_position = tilemap_floor_cells[selected_cell_index]

		# spawn
		var new_pickable = selected_pickable_path.instance()
		new_pickable.global_position = selected_cell_position
		add_child(new_pickable)
#		printt(selected_pickable_name, selected_cell_position, selected_pickable_path)

		# odstranim celico iz arraya
		available_pickable_positions.remove(selected_cell_index)		
	

func restart():
	
	# če v grupi bolts obstaja kakšen bolt
	if not bolts_in_game.empty():
		for bolt in bolts_in_game:
			bolt.queue_free()
	if not pickables_in_game.empty():
		for p in pickables_in_game:
			p.queue_free()
	$"../UI/HUD".hide_player_stats()
	spawned_bolt_index = 0
	
	
func check_neighbour_cells(cell_grid_position, area_span):
	
	var selected_cells: Array # = []
	var neighbour_in_check: Vector2
	
	# preveri vse celice v erase_area_span
	for y in area_span:
		for x in area_span:
			neighbour_in_check = cell_grid_position + Vector2(x - 1, y - 1)
			selected_cells.append(neighbour_in_check)
	return selected_cells
	
	
func _on_Enemy_path_changed(path: Array) -> void:
# ta funkcija je vezana na signal bolta
# inline connect za primer, če je bolt spawnan
# def signal connect za primer, če je bolt "in-tree" node
	navigation_line.points = path
	pass


func _on_Stat_changed(stat_owner_id, changed_stat, new_stat_value):
# ne setaš tipa parametrov, ker je lahko v različnih oblikah (index, string, float, ...)
	
	# beleženje statistike igralcev ... če je player_stat ga preračunam
	var player_stats_to_change: Dictionary = game_stats[stat_owner_id]
	match changed_stat:
		"player_active" :
			# value je v tem primeru sprememba stata
			player_stats_to_change["player_active"] = new_stat_value
			# value, ki ga pošljem spremenim v izračunanega
			new_stat_value = player_stats_to_change["player_active"]
		"life":
			player_stats_to_change["life"] += new_stat_value
			new_stat_value = player_stats_to_change["life"]
		"points" :
			player_stats_to_change["points"] += new_stat_value
			new_stat_value = player_stats_to_change["points"]
		"wins" :
			player_stats_to_change["wins"] += new_stat_value
			new_stat_value = player_stats_to_change["wins"]
	
	
#	printt(player_stats_to_change) # pošljemo signal, ki je že prikloplje na HUD
	emit_signal("stat_change_received", stat_owner_id, changed_stat, new_stat_value) # pošljemo signal, ki je že prikloplje na HUD
	

func _on_Edge_navigation_completed(floor_cells:  Array) -> void:
	
	available_pickable_positions = floor_cells # za spawnanje pickablov
	
	tilemap_floor_cells = floor_cells # global cell positions
	# tole je zaradi nespawnanega enemija 
	call_deferred("pass_on", tilemap_floor_cells) # če ni te poti, pride do erorja pri nalaganju  ... vsami igri verjetno tega ne bo
	
	
func pass_on(deferred_floor_cells: Array):
#	enemy.navigation_cells = deferred_floor_cells
	pass


	
#signal Player_spawned #(current_player_profile)
#signal Player_spawned_Q #(current_player_profile)
#signal Player_HUD_change (player_index, changed_stat_name, changed_stat_new_value)
#
#
#var player = preload("res://player/Player.tscn")
#
#var game_is_paused : bool = false
#
#var available_player_profiles : Dictionary
#var available_controller_profiles : Dictionary
#var game_player_profiles : Dictionary
#var current_player_index: int = 0 # definiramo index pred kreiranjem igralcev
#
#
#onready var player_start_game_stats: Dictionary = GameProfiles.default_player_game_stats
#
#
## --------------------------------------------------------------------------------------------------------------------------------------
#
#
#func _ready() -> void:
#
#	Global.game_manager = self
#
#	# če ni določenega nobenega igralca, potem pogrebamo defolt igralce
#	if available_player_profiles.empty() == true:
#		available_player_profiles = GameProfiles.default_player_profiles
#
##	# če ni določenega nobenega igralca, potem pogrebamo defolt igralce
#	available_controller_profiles = GameProfiles.default_controller_profiles
#
#
#func _input(event: InputEvent) -> void:
#
#
#	if Input.is_action_just_pressed("1"):
#		current_player_index = 1		
#		_quick_spawn(GameProfiles.default_player_profiles["ACE"], GameProfiles.default_controller_profiles["UpLeDoRiAl"])
#
#
#	if Input.is_action_just_pressed("2"):
#		current_player_index = 2		
#		_quick_spawn(GameProfiles.default_player_profiles["RIT"], GameProfiles.default_controller_profiles["WASDSp"])
#
#
#func _quick_spawn(player_profile, controller_profile):
#
#
#		var new_player = player.instance()
#		new_player.player_index = current_player_index # da se pripiše uniq id številka ... more se vedet kateri player je 1 in 2 in 3 in ...
#		new_player.player_name = player_profile["player_name"]
#		new_player.player_color = player_profile["player_color"]
#		new_player.player_controller_profile = controller_profile
#		new_player.global_position = Global.get_random_position()
#		new_player.global_rotation = 0
#		new_player.player_game_stats = GameProfiles.default_player_game_stats
#		Global.node_creation_parent.add_child(new_player) # instance je uvrščen v določenega starša
#		new_player.connect("Player_stat_changed", self, "_on_Player_stat_changed") # poveži signal iz plejerja z GM
#
#		emit_signal("Player_spawned_Q", player_profile, GameProfiles.default_player_game_stats, current_player_index) 
#
#
#func on_Start_game(activated_player_profiles): # signal je povezan v Select players meniju
#
#
#	# za aktivnega igralca sestavimo in-game profil
#	for player_key in activated_player_profiles.keys():
#
#		# najprej sestavimo igralčev profil kontrol
#		var current_player_profile: Dictionary = activated_player_profiles[player_key] # potegnemo plejerjev profil
#		var current_controller_name: String = current_player_profile["player_controller"] # potegnemo ime kontrolerja
#		var current_player_controller_profile: Dictionary = available_controller_profiles[current_controller_name].duplicate() # dupliciram profil v seznamo profilov, da ga lahko prilagodim za plejerja
#
#		# v ime vsake akcije v dupliciranem profilu kontrol dodamo ime igralca
#		for controller_action in current_player_controller_profile.keys():
#			var new_controller_action = player_key + "_" + controller_action # sestavimo ime nove akcije
#			current_player_controller_profile[new_controller_action] = current_player_controller_profile[controller_action] # novo akcijo dodamo v slovar in ji damo vrednost stare akcije
#			current_player_controller_profile.erase(controller_action) # zbrišemo staro akcijo v profilu
#
#		current_player_index += 1
#		create_player_ingame_profile(current_player_profile, current_player_controller_profile)
#
#	# ko so vsi profili ustvarjeni in urejeni, spawnamo vse igralce
#	yield(get_tree().create_timer(0.5), "timeout") # countdown
#	spawn_players()
#
#
#func create_player_ingame_profile(current_player_profile: Dictionary, current_player_controller_profile: Dictionary):
#	# sestavimo igralčev profil: player profil + controler profil + game stats 
#
#	var player_ingame_profile : Dictionary = {
#		"player_active" : true,
#
#		# per-plejer lastnosti
#		"player_name" : current_player_profile["player_name"],
#		"player_color": current_player_profile["player_color"],
#		"player_avatar": current_player_profile["player_avatar"],
##		"player_start_position" : player_profile["player_start_position"],
#
#		# dodamo kontrole
#		"player_controller_profile" : current_player_controller_profile,
#
#		# dodamo def statistiko
#		"player_game_stats" : player_start_game_stats.duplicate()
#		}
#
#	# določimo ime igralnega profila glede na index
##	player_index += 1 # index ob kreaciji
#
#
#	# dodam ingame profil plejerja v slovar vseh ingame profilov
#	var player_ingame_profile_name = current_player_index
#	game_player_profiles[player_ingame_profile_name] = player_ingame_profile
#



#
##func spawn_players():
##
##	for player_profile_key in game_player_profiles.keys(): # player_profile_key je v bistv player_index
##
##		# opredelilmo profil igralca
##		var current_player_profile = game_player_profiles[player_profile_key]
##
##		var new_player = player.instance()
##		new_player.player_index = player_profile_key # da se pripiše uniq id številka ... more se vedet kateri player je 1 in 2 in 3 in ...
##		new_player.player_name = current_player_profile["player_name"]
##		new_player.player_color = current_player_profile["player_color"]
##		new_player.player_controller_profile = current_player_profile["player_controller_profile"]
##		new_player.global_position = Global.get_random_position()
##		new_player.global_rotation = 0
##		new_player.player_game_stats = current_player_profile["player_game_stats"]
##		Global.node_creation_parent.add_child(new_player) # instance je uvrščen v določenega starša
##
##		new_player.connect("Player_stat_changed", self, "_on_Player_stat_changed") # poveži signal iz plejerja z GM
##
##		emit_signal("Player_spawned", current_player_profile, player_profile_key) # signal pošljemo v hud, da kreira playerstats



#
#func _on_Player_stat_changed(player_index, changed_stat_name, changed_stat_new_value):
#
#	emit_signal("Player_HUD_change", player_index, changed_stat_name, changed_stat_new_value) # pošljemo signal, ki je že prikloplje na HUD
#
#
#func toggle_pause():
#
#	if game_is_paused == false:
#
#		# ugasni tipke v areni
#		Global.node_creation_parent.set_process_input(false)
#
#		# odpri meni
##		Global.node_creation_parent.get_node("MenuHolder/ConfigurePlayerMenu").open()
##		Global.node_creation_parent.get_node("MenuHolder/ConfigureControllerMenu").open()
#		Global.node_creation_parent.get_node("MenuHolder/SelectPlayersMenu").open()
#
#		# vse otroke v areni ... plejer, orožja, bonusi, level, ki se znotraj sebe še popavza
#		for child in Global.node_creation_parent.get_children():
#			if child.has_method("pause_me"):
#				child.pause_me()
#
#		game_is_paused = true
#
#	else:
#		for child in Global.node_creation_parent.get_children():
#			if child.has_method("unpause_me"):
#				child.unpause_me()
#		game_is_paused = false
#
#		Global.node_creation_parent.set_process_input(true)
#
#
#func toggle_pause_alt():
#
#	if game_is_paused == false:
#
#		# ugasni tipke v areni
#		Global.node_creation_parent.set_process_input(false)
#
#		# odpri meni
##		Global.node_creation_parent.get_node("MenuHolder/ConfigurePlayerMenu").open()
#		Global.node_creation_parent.get_node("MenuHolder/ConfigureControllerMenu").open()
##		Global.node_creation_parent.get_node("MenuHolder/SelectPlayersMenu").open()
#
#		# vse otroke v areni ... plejer, orožja, bonusi, level, ki se znotraj sebe še popavza
#		for child in Global.node_creation_parent.get_children():
#			if child.has_method("pause_me"):
#				child.pause_me()
#
#		game_is_paused = true
#
#
#	else:
#		for child in Global.node_creation_parent.get_children():
#			if child.has_method("unpause_me"):
#				child.unpause_me()
#		game_is_paused = false
#
#		Global.node_creation_parent.set_process_input(true)
