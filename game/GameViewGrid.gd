# tukaj je koda za grebanje vseh igralcev in določitev ekranov

extends GridContainer


export var active_players_count: int = 1 setget _on_change_players
var viewport_containers_in_game: Array
var game_view_index = 0
onready var player_viewport_container = preload("res://game/GameView.tscn")

var vp_scale_1 = Vector2.ONE
var vp_scale_2 = Vector2(0.5,1)
var vp_scale_3 = Vector2(0.5,0.5)

var player_in_view

func _ready() -> void:

	# za vsakega od igralcev na voljo ...
	for player in active_players_count:
		game_view_index += 1 # usklajen s plejerja
		
	
	match active_players_count:
		1: 
			columns = 1
		2: 
			columns = 2
		3: 
			columns = 2
		4: 
			columns = 2
			
		# old ... get_child(i).player_id = i+1
onready var game_view: ViewportContainer = $GameView
#onready var game_view2: ViewportContainer = $GameView2

func _process(delta: float) -> void:
#	$GameView/Viewport/Arena/Camera.position = $GameView/Viewport/Arena/Player.global_position
#	$GameView2/Viewport/Arena/Camera.position = $GameView/Viewport/Arena/Player2.global_position
	viewport_containers_in_game = get_tree().get_nodes_in_group("VP")	
#	print("viewports_in_game: ", viewports_in_game)
	
	
func _on_change_players(new_player_count):
	
	match new_player_count:
		1: 
			free_viewports()
			columns = 1
			spawn_viewport(1, vp_scale_1, $GameView/Viewport/Arena/Player)
		2: 
			free_viewports()
			columns = 2
			spawn_viewport(1, vp_scale_2, $GameView/Viewport/Arena/Player)
			spawn_viewport(2, vp_scale_2, $GameView/Viewport/Arena/Enemy)
		3: 
			print("to še ni naštimano ppp")
#			free_viewports()
#			columns = 2
#			spawn_viewport(1, vp_scale_3, Ref.ppp1)
#			spawn_viewport(2, vp_scale_3, Ref.ppp2)
#			spawn_viewport(3, vp_scale_3, null)
		4: 
			print("to še ni naštimano ppp")
#			free_viewports()
#			columns = 2
##			spawn_viewport(1, vp_scale_3, Ref.ppp1)
##			spawn_viewport(2, vp_scale_3, Ref.ppp2)
#			spawn_viewport(3, vp_scale_3, null	)
#			spawn_viewport(4, vp_scale_3, null)
			
	print("new_player_count", new_player_count)
				
	
	pass
	
func spawn_viewport(vp_id, vp_scale, global_player):
	var new_viewport_container = player_viewport_container.instance()
	new_viewport_container.rect_scale = vp_scale
	new_viewport_container.viewport_id = vp_id
	add_child(new_viewport_container)
	
	print ("new_viewport_container: ", new_viewport_container.viewport_id, new_viewport_container.rect_scale )
	
	# follow player
	$GameView/Viewport/Arena.camera_follow_target = global_player
	
	pass
	
func free_viewports():
	
	for viewport_cont in viewport_containers_in_game:
		print ("free viewport: ", viewport_cont)
		viewport_cont.queue_free() 
