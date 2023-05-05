extends Node


onready var animation_player: AnimationPlayer = $AnimationPlayer
#onready var animacija: AnimationNodeAnimation = $

# main
onready var play_btn: Button = $HomeUI/MainMenu/Menu/PlayBtn
onready var settings_btn: Button = $HomeUI/MainMenu/Menu/SettingsBtn
onready var about_btn: Button = $HomeUI/MainMenu/Menu/AboutBtn
onready var quit_btn: Button = $HomeUI/MainMenu/Menu/QuitBtn

# about
onready var about_back_btn: Button = $HomeUI/About/BackBtn

# settings
onready var settings_back_btn: Button = $HomeUI/Settings/BackBtn

#play
onready var play1_confirm_btn: Button = $HomeUI/Play/ItemList/thumb/ConfirmBtn
onready var play2_confirm_btn: Button = $HomeUI/Play/ItemList/thumb2/ConfirmBtn
onready var play3_confirm_btn: Button = $HomeUI/Play/ItemList/thumb3/ConfirmBtn
onready var play4_confirm_btn: Button = $HomeUI/Play/ItemList/thumb4/ConfirmBtn
onready var play_back_btn: Button = $HomeUI/Play/BackBtn

# players
onready var players1_confirm_btn: Button = $HomeUI/Players/ItemList/thumb/ConfirmBtn
onready var players2_confirm_btn: Button = $HomeUI/Players/ItemList/thumb2/ConfirmBtn
onready var players3_confirm_btn: Button = $HomeUI/Players/ItemList/thumb3/ConfirmBtn
onready var players4_confirm_btn: Button = $HomeUI/Players/ItemList/thumb4/ConfirmBtn
onready var players_back_btn: Button = $HomeUI/Players/BackBtn

# arena
onready var generate_arena_btn: Button = $HomeUI/Arena/GenerateBtn
onready var arena_confirm_btn: Button = $HomeUI/Arena/ConfirmBtn
onready var arena_back_btn: Button = $HomeUI/Arena/BackBtn

# generate
onready var arena_world: PackedScene = preload("res://scenes/ArenaWorld.tscn")
onready var arena_view: Panel = $HomeUI/Arena/ArenaView
onready var new_world # : InstancePlaceholder
onready var clean_up_btn: Button = $HomeUI/Arena/CleanUpBtn
var arena_on = false
var game_on = false
export var steps_count_limit: int = 4000
	
# temp
onready var temp_back_btn: Button = $HomeUI/Arena/temp_BackBtn

	
func _on_temp_back_btn_pressed():
	animation_player.play_backwards("start_game")

	
func _ready() -> void:


	# main
	play_btn.connect("pressed", self, "_on_play_btn_pressed")
	settings_btn.connect("pressed", self, "_on_settings_btn_pressed")
	about_btn.connect("pressed", self, "_on_about_btn_pressed")
	quit_btn.connect("pressed", self, "_on_quit_btn_pressed")

	# about
	about_back_btn.connect("pressed", self, "_on_about_back_btn_pressed")

	# settings
	settings_back_btn.connect("pressed", self, "_on_settings_back_btn_pressed")

	#play
	play1_confirm_btn.connect("pressed", self, "_on_play1_confirm_btn_pressed")
	play2_confirm_btn.connect("pressed", self, "_on_play2_confirm_btn_pressed")
	play3_confirm_btn.connect("pressed", self, "_on_play3_confirm_btn_pressed")
	play4_confirm_btn.connect("pressed", self, "_on_play4_confirm_btn_pressed")
	play_back_btn.connect("pressed", self, "_on_play_back_btn_pressed")

	# players
	players1_confirm_btn.connect("pressed", self, "_on_players1_confirm_btn_pressed")
	players2_confirm_btn.connect("pressed", self, "_on_players2_confirm_btn_pressed")
	players3_confirm_btn.connect("pressed", self, "_on_players3_confirm_btn_pressed")
	players4_confirm_btn.connect("pressed", self, "_on_players4_confirm_btn_pressed")
	players_back_btn.connect("pressed", self, "_on_players_back_btn_pressed")

	# arena
	clean_up_btn.connect("pressed", self, "_on_clean_up_btn_pressed")
	generate_arena_btn.connect("pressed", self, "_on_generate_arena_btn_pressed")
	arena_confirm_btn.connect("pressed", self, "_on_arena_confirm_btn_pressed")
	arena_back_btn.connect("pressed", self, "_on_arena_back_btn_pressed")

	temp_back_btn.connect("pressed", self, "_on_temp_back_btn_pressed")

# main
func _on_play_btn_pressed():
	animation_player.play("play_in")
func _on_settings_btn_pressed():
	animation_player.play("settings_in")
func _on_about_btn_pressed():
	animation_player.play("about_in")

# settings
func _on_settings_back_btn_pressed():
	animation_player.play_backwards("settings_in")

# about
func _on_about_back_btn_pressed():
	animation_player.play_backwards("about_in")

# play
func _on_play1_confirm_btn_pressed():
	animation_player.play("players_in")
func _on_play_back_btn_pressed():
	animation_player.play_backwards("play_in")

# select players
func _on_players_btn_pressed():
	animation_player.play("players_in")
func _on_players1_confirm_btn_pressed():
	animation_player.play("arena_in")
func _on_players_back_btn_pressed():
	animation_player.play_backwards("players_in")

# generate arena
func _on_arena_confirm_btn_pressed():
	animation_player.play("start_game")
func _on_arena_back_btn_pressed():
	arena_on = false
	animation_player.play_backwards("arena_in")
# arena generator
func spawn_generator():	
	# spucaj
#	if not new_world == null:
#		new_world.queue_free()
	# spawn walker
	new_world = arena_world.instance()
	new_world.scale *=  0.25
	arena_view.add_child(new_world)
#	new_world.steps_count_limit = 5
	
	
func _on_generate_arena_btn_pressed():
	if not new_world == null:
		spawn_generator()
func _on_clean_up_btn_pressed():
	if not new_world == null:
		new_world.cleanup_map()




# quit
func _on_quit_btn_pressed():
#	Global.switch_to_scene("res://scenes/arena/Arena.tscn")
#	Global.switch_to_scene("res://scenes/Game.tscn")
	_on_players1_confirm_btn_pressed()


# --------------------------------------------------------------------------------------------------

onready var fejkarena: TileMap = $PseudoArena/Fejkarena
var arena_save_name = "prva arena"
	
	
func _on_AnimationPlayer_animation_finished(animation) -> void:
	
	match animation:
		"arena_in": 
			if not arena_on:
				arena_on = true
				spawn_generator()
			else:
				arena_on = false
				
		"start_game":
			
			print("Profiles.arena_tilemap_profiles------------------------------")
			# trenutna mapa
			var current_used_cells: Array = new_world.arena_tilemap.get_used_cells()
			# shrani trenutno mapo v profile
			Profiles.arena_tilemap_profiles[arena_save_name] = current_used_cells
			print(current_used_cells)
			switch_to_scene("res://scenes/arena/Arena.tscn", current_used_cells) # 2. arg je zato, da jih zbrišemo
			
			
var current_arena_scene = null		
func switch_to_scene(path, cells):
		call_deferred("_deferred_goto_scene", path, cells)

func _deferred_goto_scene(path, cells):
	
	# naložim areno
	var new_scene = ResourceLoader.load(path)
	current_arena_scene = new_scene.instance()
	get_tree().root.add_child(current_arena_scene) # direct child of root
#	get_tree().current_arena_scene = current_arena_scene # Optionally, to make it compatible with the SceneTree.change_scene() API.
	print ("new_arena: ", current_arena_scene)
		
	var current_arena_edge = current_arena_scene.level_edge
	
	# zbrišem vse celice
	for cell in current_arena_edge.get_used_cells():
		if current_arena_edge.get_cellv(cell) == 0: 
			current_arena_edge.set_cellv(cell, -1)
		elif current_arena_edge.get_cellv(cell) == 3: 
			current_arena_edge.set_cellv(cell, -1)

	# vzamem array celic iz tajlmap profila profila
	var new_arena_cells: Array = Profiles.arena_tilemap_profiles[arena_save_name]
	# za vsako celico v areju, kopiram lokacijo v arena tilemap ... in id seveda
	for new_arena_cell in new_arena_cells:
		# rabim id na grid lokaciji
		var cell_id = new_arena_cells.find(new_arena_cell)
		current_arena_edge.set_cellv(new_arena_cell, 0)
		
	current_arena_edge.update_bitmask_region(new_world.borders.position, new_world.borders.end)
		
