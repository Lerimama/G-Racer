extends Node

signal Player_spawned #(current_player_profile)
signal Player_spawned_Q #(current_player_profile)
signal Player_HUD_change (player_index, changed_stat_name, changed_stat_new_value)


var player = preload("res://player/Player.tscn")

var game_is_paused : bool = false

var available_player_profiles : Dictionary
var available_controller_profiles : Dictionary
var game_player_profiles : Dictionary
var current_player_index: int = 0 # definiramo index pred kreiranjem igralcev


onready var player_start_game_stats: Dictionary = GameProfiles.default_player_game_stats


# --------------------------------------------------------------------------------------------------------------------------------------


func _ready() -> void:

	Global.game_manager = self
	
	# če ni določenega nobenega igralca, potem pogrebamo defolt igralce
	if available_player_profiles.empty() == true:
		available_player_profiles = GameProfiles.default_player_profiles

#	# če ni določenega nobenega igralca, potem pogrebamo defolt igralce
	available_controller_profiles = GameProfiles.default_controller_profiles


func _input(event: InputEvent) -> void:


	if Input.is_action_just_pressed("1"):
		current_player_index = 1		
		_quick_spawn(GameProfiles.default_player_profiles["ACE"], GameProfiles.default_controller_profiles["UpLeDoRiAl"])
			
	
	if Input.is_action_just_pressed("2"):
		current_player_index = 2		
		_quick_spawn(GameProfiles.default_player_profiles["RIT"], GameProfiles.default_controller_profiles["WASDSp"])
		
		
func _quick_spawn(player_profile, controller_profile):

	
		var new_player = player.instance()
		new_player.player_index = current_player_index # da se pripiše uniq id številka ... more se vedet kateri player je 1 in 2 in 3 in ...
		new_player.player_name = player_profile["player_name"]
		new_player.player_color = player_profile["player_color"]
		new_player.player_controller_profile = controller_profile
		new_player.global_position = Global.get_random_position()
		new_player.global_rotation = 0
		new_player.player_game_stats = GameProfiles.default_player_game_stats
		Global.node_creation_parent.add_child(new_player) # instance je uvrščen v določenega starša
		new_player.connect("Player_stat_changed", self, "_on_Player_stat_changed") # poveži signal iz plejerja z GM
		
		emit_signal("Player_spawned_Q", player_profile, GameProfiles.default_player_game_stats, current_player_index) 
		


func on_Start_game(activated_player_profiles): # signal je povezan v Select players meniju
	
	
	# za aktivnega igralca sestavimo in-game profil
	for player_key in activated_player_profiles.keys():
		
		# najprej sestavimo igralčev profil kontrol
		var current_player_profile: Dictionary = activated_player_profiles[player_key] # potegnemo plejerjev profil
		var current_controller_name: String = current_player_profile["player_controller"] # potegnemo ime kontrolerja
		var current_player_controller_profile: Dictionary = available_controller_profiles[current_controller_name].duplicate() # dupliciram profil v seznamo profilov, da ga lahko prilagodim za plejerja
		
		# v ime vsake akcije v dupliciranem profilu kontrol dodamo ime igralca
		for controller_action in current_player_controller_profile.keys():
			var new_controller_action = player_key + "_" + controller_action # sestavimo ime nove akcije
			current_player_controller_profile[new_controller_action] = current_player_controller_profile[controller_action] # novo akcijo dodamo v slovar in ji damo vrednost stare akcije
			current_player_controller_profile.erase(controller_action) # zbrišemo staro akcijo v profilu
		
		current_player_index += 1
		create_player_ingame_profile(current_player_profile, current_player_controller_profile)

	# ko so vsi profili ustvarjeni in urejeni, spawnamo vse igralce
	yield(get_tree().create_timer(0.5), "timeout") # countdown
	spawn_players()


func create_player_ingame_profile(current_player_profile: Dictionary, current_player_controller_profile: Dictionary):
	# sestavimo igralčev profil: player profil + controler profil + game stats 
	
	var player_ingame_profile : Dictionary = {
		"player_active" : true,
		
		# per-plejer lastnosti
		"player_name" : current_player_profile["player_name"],
		"player_color": current_player_profile["player_color"],
		"player_avatar": current_player_profile["player_avatar"],
#		"player_start_position" : player_profile["player_start_position"],
		
		# dodamo kontrole
		"player_controller_profile" : current_player_controller_profile,
		
		# dodamo def statistiko
		"player_game_stats" : player_start_game_stats.duplicate()
		}

	# določimo ime igralnega profila glede na index
#	player_index += 1 # index ob kreaciji
	
	 
	# dodam ingame profil plejerja v slovar vseh ingame profilov
	var player_ingame_profile_name = current_player_index
	game_player_profiles[player_ingame_profile_name] = player_ingame_profile


func spawn_players():

	for player_profile_key in game_player_profiles.keys(): # player_profile_key je v bistv player_index

		# opredelilmo profil igralca
		var current_player_profile = game_player_profiles[player_profile_key]

		var new_player = player.instance()
		new_player.player_index = player_profile_key # da se pripiše uniq id številka ... more se vedet kateri player je 1 in 2 in 3 in ...
		new_player.player_name = current_player_profile["player_name"]
		new_player.player_color = current_player_profile["player_color"]
		new_player.player_controller_profile = current_player_profile["player_controller_profile"]
		new_player.global_position = Global.get_random_position()
		new_player.global_rotation = 0
		new_player.player_game_stats = current_player_profile["player_game_stats"]
		Global.node_creation_parent.add_child(new_player) # instance je uvrščen v določenega starša
		
		new_player.connect("Player_stat_changed", self, "_on_Player_stat_changed") # poveži signal iz plejerja z GM
		
		emit_signal("Player_spawned", current_player_profile, player_profile_key) # signal pošljemo v hud, da kreira playerstats

	
func _on_Player_stat_changed(player_index, changed_stat_name, changed_stat_new_value):
	
	emit_signal("Player_HUD_change", player_index, changed_stat_name, changed_stat_new_value) # pošljemo signal, ki je že prikloplje na HUD
	

func toggle_pause():

	if game_is_paused == false:

		# ugasni tipke v areni
		Global.node_creation_parent.set_process_input(false)

		# odpri meni
		Global.node_creation_parent.get_node("MenuHolder/ConfigurePlayerMenu").open()
#		Global.node_creation_parent.get_node("MenuHolder/ConfigureControllerMenu").open()
#		Global.node_creation_parent.get_node("MenuHolder/SelectPlayersMenu").open()

		# vse otroke v areni ... plejer, orožja, bonusi, level, ki se znotraj sebe še popavza
		for child in Global.node_creation_parent.get_children():
			if child.has_method("pause_me"):
				child.pause_me()

		game_is_paused = true

	else:
		for child in Global.node_creation_parent.get_children():
			if child.has_method("unpause_me"):
				child.unpause_me()
		game_is_paused = false

		Global.node_creation_parent.set_process_input(true)
		
		
func toggle_pause_alt():

	if game_is_paused == false:

		# ugasni tipke v areni
		Global.node_creation_parent.set_process_input(false)

		# odpri meni
#		Global.node_creation_parent.get_node("MenuHolder/ConfigurePlayerMenu").open()
#		Global.node_creation_parent.get_node("MenuHolder/ConfigureControllerMenu").open()
		Global.node_creation_parent.get_node("MenuHolder/SelectPlayersMenu").open()

		# vse otroke v areni ... plejer, orožja, bonusi, level, ki se znotraj sebe še popavza
		for child in Global.node_creation_parent.get_children():
			if child.has_method("pause_me"):
				child.pause_me()

		game_is_paused = true


	else:
		for child in Global.node_creation_parent.get_children():
			if child.has_method("unpause_me"):
				child.unpause_me()
		game_is_paused = false

		Global.node_creation_parent.set_process_input(true)
