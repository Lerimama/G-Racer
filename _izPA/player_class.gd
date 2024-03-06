extends KinematicBody2D
class_name Player


signal stat_changed # spremenjeno statistiko javi v hud
signal rewarded_on_game_over # da je dobil nagrado ob cleaned javi v GM
signal player_pixel_set # player je pripravljen

enum States {IDLE, STEPPING, SKILLED, SKILLING, COCKING, RELEASING, BURSTING}
var current_state # = States.IDLE

var direction = Vector2.ZERO # prenosna
var player_camera: Node
var player_stats: Dictionary # se aplicira ob spawnanju
var collision: KinematicCollision2D
var teleporting_wall_tile_id = 3

# colors
var pixel_color: Color = Global.game_manager.game_settings["player_start_color"]
var change_color_tween: SceneTreeTween # če cockam pred končanjem tweena, vzamem to barvo
var change_to_color: Color

# steping
var step_time_fast: float = Global.game_manager.game_settings["step_time_fast"]
var step_time_slow: float = Global.game_manager.game_settings["step_time_slow"]
var step_slowdown_rate: float = Global.game_manager.game_settings["step_slowdown_rate"]

# bursting
var cocking_room: bool = true
var uncocking: bool = false
var cocking_loop_pause: float = 1
var cock_ghost_cocking_time: float = 0.1 # čas nastajanja ghosta in njegova animacija ... original 0.12
var current_ghost_cocking_time: float = 0 # trenuten čas nastajanja ghosta ... tukaj, da ga ne nulira z vsakim frejmom
var cocked_ghost_max_count: int = 5
var cock_ghost_speed_addon: float = 10
var cocked_ghosts: Array
var burst_speed: float = 0 # trenutna hitrost
var burst_velocity: Vector2

# heartbeat
var heartbeat_loop: int = 0
var got_hit: bool # heartbeat animacija počaka die animacijo, ko je po karambolu energija = 1

# controls
var key_left: String
var key_right: String
var key_up: String
var key_down: String
var key_burst: String

onready var collision_shape: CollisionShape2D = $CollisionShape2D
onready var collision_shape_ext: CollisionShape2D = $CollisionShapeExt
onready var vision_rays: Array = [$Vision/VisionRay1, $Vision/VisionRay2, $Vision/VisionRay3]
onready var vision: Node2D = $Vision
onready var color_poly: Polygon2D = $ColorPoly # on daje barvo celemu pixlu
onready var burst_light: Light2D = $BurstLight
onready var skill_light: Light2D = $SkillLight
onready var glow_light: Light2D = $GlowLight
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var game_settings: Dictionary = Global.game_manager.game_settings 
onready var cell_size_x: int = Global.current_tilemap.cell_size.x  # pogreba od GMja, ki jo dobi od tilemapa
onready var Ghost: PackedScene = preload("res://game/pixel/ghost.tscn")
onready var PixelCollisionParticles: PackedScene = preload("res://game/pixel/pixel_collision_particles.tscn")
onready var PixelDizzyParticles: PackedScene = preload("res://game/pixel/pixel_dizzy_particles.tscn")
onready var FloatingTag: PackedScene = preload("res://game/hud/floating_tag.tscn")


func _unhandled_input(event: InputEvent) -> void:

	if name == "p1":
		if Input.is_action_pressed("no1"):
			change_stat("debug_player_energy", -10)

	elif name == "p2":
		if Input.is_action_pressed("no2"):
			change_stat("debug_player_energy", -10)


func _ready() -> void:
		
	add_to_group(Global.group_players)
	randomize() # za random blink animacije
	
	# controler setup
	if Global.game_manager.start_players_count == 2:
		key_left = "%s_left" % name
		key_right = "%s_right" % name
		key_up = "%s_up" % name
		key_down = "%s_down" % name
		key_burst = "%s_burst" % name
	else:
		key_left = "ui_left"
		key_right = "ui_right"
		key_up = "ui_up"
		key_down = "ui_down"
		key_burst = "burst"
	
	skill_light.enabled = false
	burst_light.enabled = false
	
	current_state = States.IDLE
	
	
func _physics_process(delta: float) -> void:
	# print("PLAYER PF")
	
	color_poly.modulate = pixel_color # povezava med variablo in barvo mora obstajati non-stop
	
	# glow light setup
	if pixel_color == Global.game_manager.game_settings["player_start_color"]:
		glow_light.color = Color.white
		glow_light.energy = 1.7
	else:
		glow_light.color = pixel_color
		glow_light.energy = 1.5 # če spremeniš, je treba spremenit tudi v animacijah
	
	state_machine()
	manage_heartbeat()
	
						
func state_machine():
	
	match current_state:
		States.IDLE:
			idle_inputs()
		States.SKILLED:
			if player_stats["player_energy"] > 1:
				skill_inputs()
		States.COCKING:
			cocking_inputs()
		States.BURSTING:
			burst_velocity = direction * burst_speed
			collision = move_and_collide(burst_velocity) 
			if collision:
				on_collision()
			bursting_inputs()

	
func on_collision(): 
	
	stop_sound("burst")
	
	if collision.collider.is_in_group(Global.group_tilemap):
		on_hit_wall()
	elif collision.collider is StaticBody2D: # top screen limit
		on_hit_wall()
	elif collision.collider.is_in_group(Global.group_strays):
		on_hit_stray(collision.collider)
	elif collision.collider.is_in_group(Global.group_players):
		on_hit_player(collision.collider)

	
# INPUTS ------------------------------------------------------------------------------------------


func idle_inputs():
	
	if player_stats["player_energy"] > 1:
		var current_collider: Node2D = detect_collision_in_direction(direction)
		if not current_collider:
		# dokler ne zazna kolizije se premika zvezno ... is_action_pressed
			if Input.is_action_pressed(key_up):
				direction = Vector2.UP
				step()
			elif Input.is_action_pressed(key_down):
				direction = Vector2.DOWN
				step()
			elif Input.is_action_pressed(key_left):
				direction = Vector2.LEFT
				step()
			elif Input.is_action_pressed(key_right):
				direction = Vector2.RIGHT
				step()
		else:
		# ko zazna kolizijo postane skilled ali pa end move 
		# kontrole prevzame skilled_input
			if current_collider.is_in_group(Global.group_strays):
				current_state = States.SKILLED
				current_collider.current_state = current_collider.States.STATIC # ko ga premakneš postane MOVING
			elif current_collider.is_in_group(Global.group_tilemap):
				if current_collider.get_collision_tile_id(self, direction) == teleporting_wall_tile_id:
					current_state = States.SKILLED
				else: # druge stene
					end_move()
			elif current_collider.is_in_group(Global.group_players):
				end_move()
			elif current_collider is StaticBody2D: # static body, 
				end_move()
	
	if Input.is_action_just_pressed(key_burst): # brez "just" dela po stisku smeri ... ni ok
		current_state = States.COCKING
		if change_color_tween and change_color_tween.is_running(): # če sprememba barve še poteka, jo spremenim takoj
			change_color_tween.kill()
			pixel_color = change_to_color
		burst_light_on()


func skill_inputs():
	
	skill_light_on()
	
	var new_direction: Vector2 # nova smer, ker pritisnem še enkrat
	
	# s tem inputom prekinem "is_pressed" input
	if Input.is_action_just_pressed(key_up):
		new_direction = Vector2.UP
	elif Input.is_action_just_pressed(key_down):
		new_direction = Vector2.DOWN
	elif Input.is_action_just_pressed(key_left):
		new_direction = Vector2.LEFT
	elif Input.is_action_just_pressed(key_right):
		new_direction = Vector2.RIGHT
		
	# prehod v cocking stanje
	if Input.is_action_just_pressed(key_burst): # brez "just" dela po stisku smeri ... ni ok
		current_state = States.COCKING
		skill_light_off()
		burst_light_on()
		return	
			
	# izbor skila v novi smeri
	var current_collider: Object = detect_collision_in_direction(direction)
	if current_collider: # zaščita, če se povežeš in ti potem pobegne
		if new_direction:
			if new_direction == direction: # naprej
				if current_collider.is_in_group(Global.group_tilemap):
					teleport()
				elif current_collider.is_in_group(Global.group_strays) and not current_collider.current_state == current_collider.States.MOVING:
					push(current_collider)
			elif new_direction == - direction: # nazaj
				if current_collider.is_in_group(Global.group_strays) and not current_collider.current_state == current_collider.States.MOVING:
					pull(current_collider)	
				elif current_collider.is_in_group(Global.group_tilemap):
					end_move() # nazaj ... izhod iz skilla, če gre za steno
			else: # levo/desno ... izhod iz skilla
				end_move()
				if current_collider.is_in_group(Global.group_strays):
					current_collider.current_state = current_collider.States.IDLE
	else:
		end_move()
					
					
func cocking_inputs():

	# cocking
	if Input.is_action_pressed(key_up):
		if cocked_ghosts.empty(): # če je smer setana, ni pa potrjena
			direction = Vector2.DOWN
		if direction == Vector2.DOWN: # če je smer setana (ista)
			cock_burst()
	elif Input.is_action_pressed(key_down):
		if cocked_ghosts.empty():
			direction = Vector2.UP
		if direction == Vector2.UP:
			cock_burst()
	elif Input.is_action_pressed(key_left):
		if cocked_ghosts.empty():
			direction = Vector2.RIGHT
		if direction == Vector2.RIGHT:
			cock_burst()
	elif Input.is_action_pressed(key_right):
		if cocked_ghosts.empty():
			direction = Vector2.LEFT
		if direction == Vector2.LEFT:
			cock_burst()
	
	# releasing		
	if Input.is_action_just_released(key_burst):
		if cocked_ghosts.empty():
			end_move()
		else:
			release_burst()
			burst_light_off()
			

func bursting_inputs():
	
	# stop burst
	if Input.is_action_just_pressed(key_burst):
		end_move()
		Input.start_joy_vibration(0, 0.6, 0.2, 0.2)
		play_sound("burst_stop")
		stop_sound("burst_cocking")
		stop_sound("burst_uncocking")	

				
# MOVEMENT ------------------------------------------------------------------------------------------

	
func step(): # step koda se ob držanju tipke v smeri izvaja stalno
	 
	var step_direction = direction
		
	# preverim, če kolajda v smeri
	if not detect_collision_in_direction(step_direction):
		
		current_state = States.STEPPING
		
		collision_shape_ext.position = step_direction * cell_size_x # vržem koližn v smer premika
		spawn_trail_ghost()
		var step_time = get_step_time()
		
		var step_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)	
		step_tween.tween_property(self, "position", global_position + direction * cell_size_x, step_time)
		step_tween.parallel().tween_property(collision_shape_ext, "position", Vector2.ZERO, step_time)
		step_tween.tween_callback(self, "end_move")
		step_tween.tween_callback(self, "change_stat", ["cells_traveled", 1]) # točke in energija kot je določeno v settingsih
		
		play_stepping_sound(player_stats["player_energy"] / float(Global.game_manager.game_settings["player_max_energy"])) # ulomek je za pitch zvoka
	
		
func end_move():
	
	# reset burst
	burst_speed = 0
	cocking_room = true
	uncocking = false
	while not cocked_ghosts.empty():
		var ghost = cocked_ghosts.pop_back()
		ghost.queue_free()
		
	# ugasnem lučke
	burst_light_off()
	skill_light_off()
	
	# reset ključnih vrednosti (če je v skill tweenu, se poštima)
	direction = Vector2.ZERO 
	collision_shape_ext.position = Vector2.ZERO
	
	# always
	global_position = Global.snap_to_nearest_grid(global_position) 
	current_state = States.IDLE # more bit na kocnu
	

# BURST ------------------------------------------------------------------------------------------


func cock_burst():
	
	var burst_direction = direction
	var cock_direction = - burst_direction
	
	# prostor za začetek napenjanja preverja pixel
	if detect_collision_in_direction(cock_direction):
		stop_sound("burst_cocking")
		end_move()
		return
	
	if not uncocking:
		if cocked_ghosts.size() < cocked_ghost_max_count and cocking_room: # prostor za napenjanje preverja ghost
			play_sound("burst_cocking")
			current_ghost_cocking_time += 1 / 60.0 # čas držanja tipke (znotraj nastajanja ene cock celice) ... fejk delta
			if current_ghost_cocking_time > cock_ghost_cocking_time: # ko je čas za eno celico mimo, jo spawnam
				current_ghost_cocking_time = 0
				var new_cock_ghost = spawn_cock_ghost(cock_direction)
				cocked_ghosts.append(new_cock_ghost)	
		elif cocked_ghosts.size() == cocked_ghost_max_count:
			current_ghost_cocking_time += 1 / 60.0 # čas držanja tipke (znotraj nastajanja ene cock celice) ... fejk delta
			if current_ghost_cocking_time > 6 * cock_ghost_cocking_time: # auto burst
				release_burst()
				burst_light_off()
#			yield(get_tree().create_timer(cocking_loop_pause), "timeout")
#			uncocking = true
#	else:
#		if not cocked_ghosts.empty():
#			current_ghost_cocking_time += 1 / 60.0 
#			if current_ghost_cocking_time > cock_ghost_cocking_time:
#				play_sound("burst_uncocking")
#				current_ghost_cocking_time = 0
#				var last_cocked_ghost = cocked_ghosts.back() # najdem zadnjega cockanega in ga odfejdam
#				var cock_cell_tween = get_tree().create_tween()
#				cock_cell_tween.tween_property(last_cocked_ghost, "modulate:a", 0, cock_ghost_cocking_time)
#				yield(cock_cell_tween, "finished")
#				cocked_ghosts.pop_back()
#				last_cocked_ghost.queue_free()
#		else:
#			yield(get_tree().create_timer(cocking_loop_pause), "timeout")
#			uncocking = false

		
func release_burst():
	
	current_state = States.RELEASING
	
	play_sound("burst_cocked")

	var cocked_ghost_fill_time: float = 0.015 # čas za napolnitev vseh spawnanih ghostov (tik pred burstom)
	var cocked_pause_time: float = 0.03 # pavza pred strelom

	# napeti ghosti animirajo do alfa 1
	for ghost in cocked_ghosts:
		var get_set_tween = get_tree().create_tween()
		get_set_tween.tween_property(ghost, "modulate:a", 1, cocked_ghost_fill_time)
		yield(get_tree().create_timer(cocked_ghost_fill_time),"timeout")

	yield(get_tree().create_timer(cocked_pause_time), "timeout")
	
	burst()
		

func burst():
	
	var burst_direction = direction
	var backup_direction = - burst_direction
	var current_ghost_count = cocked_ghosts.size()
	
	# spawn stretch ghost
	var new_stretch_ghost = spawn_ghost(global_position)
	if burst_direction.y == 0: # če je smer hor
		new_stretch_ghost.scale = Vector2(current_ghost_count, 1)
	elif burst_direction.x == 0: # če je smer ver
		new_stretch_ghost.scale = Vector2(1, current_ghost_count)
	new_stretch_ghost.position = global_position - (burst_direction * cell_size_x * current_ghost_count)/2 - burst_direction * cell_size_x/2
	
	# release cocked ghosts
	while not cocked_ghosts.empty():
		var ghost = cocked_ghosts.pop_back()
		ghost.queue_free()
	
	stop_sound("burst_cocking")
	stop_sound("burst_uncocking")
	play_sound("burst")
	
	# release ghost 
	var strech_ghost_shrink_time: float = 0.2
	var release_tween = get_tree().create_tween()
	release_tween.tween_property(new_stretch_ghost, "scale", Vector2.ONE, strech_ghost_shrink_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	release_tween.parallel().tween_property(new_stretch_ghost, "position", global_position - burst_direction * cell_size_x, strech_ghost_shrink_time).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	release_tween.tween_callback(new_stretch_ghost, "queue_free")
	
	# release pixel
	yield(get_tree().create_timer(strech_ghost_shrink_time), "timeout") # čaka na zgornji tween
	current_state = States.BURSTING
	burst_speed = current_ghost_count * cock_ghost_speed_addon
	change_stat("burst_released", 1)

	
# SKILLS ------------------------------------------------------------------------------------------

		
func push(stray_to_move: KinematicBody2D): # skilled inputs opredeli vrsto skila glede na kolajderja
	
	var push_direction = direction
	var backup_direction = - push_direction
	
	# prostor za zalet?
	if detect_collision_in_direction(backup_direction):
		end_move()
		return
	
	current_state = States.SKILLING
	
	var push_cock_time: float = 0.3
	var push_time: float = 0.2
	var sound_delay: float = 0.07 # LNF
	var new_push_ghost_position = global_position + push_direction * cell_size_x
	var new_push_ghost = spawn_ghost(new_push_ghost_position)
	var room_for_push: bool = true
	var strays_to_move: Array = [stray_to_move]

	# naberi sosede na liniji in preveri prostor
	for stray in strays_to_move:
		var stray_neighbor = stray.detect_collision_in_direction(push_direction)
		if stray_neighbor:
			if stray_neighbor.is_in_group(Global.group_strays):
				strays_to_move.append(stray_neighbor)
			elif stray_neighbor.is_in_group(Global.group_tilemap):
				room_for_push =  false
	
	play_sound("pushpull_start")
		
	collision_shape_ext.position = backup_direction * cell_size_x # vržem koližn v smer zaleta, smer premika pokriva strayev extension
	
	var push_tween = get_tree().create_tween()
	# cock
	push_tween.tween_property(self, "position", global_position + backup_direction * cell_size_x, push_cock_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if room_for_push:
		for stray_to_move in strays_to_move:
			push_tween.parallel().tween_callback(stray_to_move, "push_stray", [push_direction, push_cock_time, push_time])
	push_tween.parallel().tween_property(collision_shape_ext, "position", Vector2.ZERO, push_cock_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT) # animiram s plejerjem na 0 pozicijo
	push_tween.parallel().tween_property(new_push_ghost, "position", new_push_ghost.global_position + backup_direction * cell_size_x, push_cock_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# lučko zapeljem na začetek ghosta (ostane ob strayu)
	push_tween.parallel().tween_property(skill_light, "position", skill_light.position - backup_direction * cell_size_x, push_cock_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
	# release
	push_tween.tween_callback(self, "play_sound", ["pushpull_end"])
	push_tween.tween_callback(self, "skill_light_off") # lučko dam v proces ugašanja
	push_tween.tween_property(self, "position", global_position, push_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	push_tween.parallel().tween_property(skill_light, "position", Vector2.ZERO, push_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN) # lučko zapeljem nazaj na začetno lokacijo
	if room_for_push:
		push_tween.tween_callback(self, "play_sound", ["pushed"]).set_delay(sound_delay)
	push_tween.tween_callback(new_push_ghost, "queue_free")
	# reset
	push_tween.tween_callback(self, "end_move")
	
	change_stat("skill_used", 1) # zazih ni v tweenu


func pull(stray_to_move: KinematicBody2D): # skilled inputs opredeli vrsto skila glede na kolajderja
	
	var target_direction = direction 
	var pull_direction = - target_direction
	
	# prostor v smeri premika?
	if detect_collision_in_direction(pull_direction): 
		end_move()
		return	
	
	current_state = States.SKILLING
	collision_shape_ext.position = pull_direction * cell_size_x # vržem koližn v smer premika

	var pull_cock_time: float = 0.3
	var pull_time: float = 0.2	
	var pull_end_delay: float = 0.1 # zaradi LNF
	var new_pull_ghost = spawn_ghost(global_position + target_direction * cell_size_x)
	
	play_sound("pushpull_start")

	var pull_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	# move self
	pull_tween.tween_property(self, "position", global_position + pull_direction * cell_size_x, pull_cock_time)
	pull_tween.parallel().tween_callback(stray_to_move, "pull_stray", [pull_direction, pull_cock_time, pull_time]) # kličem tukaj, da animiram njegov collision_ext
	pull_tween.parallel().tween_property(collision_shape_ext, "position", Vector2.ZERO, pull_cock_time) # reset collision_ext
	pull_tween.parallel().tween_property(skill_light, "position", skill_light.position - pull_direction * cell_size_x, pull_cock_time) # lučko zapeljem na začetek ghosta (ostane ob strayu)
	pull_tween.parallel().tween_property(new_pull_ghost, "position", new_pull_ghost.global_position + pull_direction * cell_size_x, pull_cock_time)
	pull_tween.parallel().tween_callback(self, "play_sound", ["pulled"])
	# pull stray
	pull_tween.tween_callback(self, "skill_light_off") # lučko dam v proces ugašanja
	pull_tween.tween_property(skill_light, "position", Vector2.ZERO, pull_time) # lučko zapeljem nazaj na začetno lokacijo	
	# reset
	pull_tween.tween_callback(self, "end_move")
	pull_tween.tween_callback(new_pull_ghost, "queue_free").set_delay(pull_end_delay) # delay je zato, ker se pixel premakne kasneje
	
	change_stat("skill_used", 2) # zazih ni v tweenu
	
			
func teleport(): # skilled inputs opredeli vrsto skila glede na kolajderja
		
	var teleport_direction = direction

	current_state = States.SKILLING

	# teleporting ghost
	var new_teleport_ghost = spawn_ghost(global_position)
	new_teleport_ghost.direction = teleport_direction
	new_teleport_ghost.modulate.a = 0
	new_teleport_ghost.z_index = 3
	new_teleport_ghost.connect("ghost_target_reached", self, "_on_ghost_target_reached")

	# kamera target
	if player_camera:
		player_camera.camera_target = new_teleport_ghost
	collision_shape.disabled = true
	collision_shape_ext.disabled = true

	var ghost_max_speed: float = 10
	var teleporting_start_delay: float = 0.3

	yield(get_tree().create_timer(teleporting_start_delay), "timeout")
	
	skill_light_off()
	Input.start_joy_vibration(0, 0.3, 0, 0)
	play_sound("teleport")
	new_teleport_ghost.max_speed = ghost_max_speed
	new_teleport_ghost.modulate.a = 1
	modulate.a = 0	

	# zaključek v signalu _on_ghost_target_reached


# ON HIT ------------------------------------------------------------------------------------------


func on_hit_stray(hit_stray: KinematicBody2D):
	
	Input.start_joy_vibration(0, 0.5, 0.6, 0.2)
	play_sound("hit_stray")	
	spawn_collision_particles()
	shake_player_camera(burst_speed)			
	
	if hit_stray.current_state == hit_stray.States.DYING or hit_stray.current_state == hit_stray.States.WALL: # če je že v umiranju, samo kolajdaš
	# if hit_stray.current_state == hit_stray.States.DYING: # če je že v umiranju, samo kolajdaš
		end_move()
		return
	
	tween_color_change(hit_stray.stray_color)

	# preverim sosede
	var hit_stray_neighbors = check_strays_neighbors(hit_stray)
	# naberem strayse za destrojat
	var burst_speed_units_count = burst_speed / cock_ghost_speed_addon
	var strays_to_destroy: Array = []
	strays_to_destroy.append(hit_stray)
	if not hit_stray_neighbors.empty():
		for neighboring_stray in hit_stray_neighbors: # še sosedi glede na moč bursta
			if strays_to_destroy.size() < burst_speed_units_count or burst_speed_units_count == cocked_ghost_max_count:
				strays_to_destroy.append(neighboring_stray)
			else: break
	
	# jih destrojam
	for stray in strays_to_destroy:
		var stray_index = strays_to_destroy.find(stray)
		stray.die(stray_index, strays_to_destroy.size()) # podatek o velikosti rabi za izbor animacije
		Global.hud.show_color_indicator(stray.stray_color) # če je scroller se returna na fuknciji
	
	end_move() # more bit za collision partikli zaradi smeri
	
	change_stat("hit_stray", strays_to_destroy.size()) # štetje, točke in energija glede na število uničenih straysov

	
func on_hit_player(hit_player: KinematicBody2D):
	
	Input.start_joy_vibration(0, 0.5, 0.6, 0.2)
	play_sound("hit_stray")
	spawn_collision_particles()
	shake_player_camera(burst_speed)			

	# korekcija pozicije
	var player_direction = direction # za korekcijo
	global_position = hit_player.global_position + (cell_size_x * (- player_direction)) # plejer eno polje ob zadetem
	
	# opredeli zmagovalca
	if burst_speed == hit_player.burst_speed: # neodločeno
		end_move()
		hit_player.end_move() # plejer, ki prvi zazna kontakt ukaže naprej, da je zaporedje pod kontrolo 
	
	elif burst_speed > hit_player.burst_speed: # zmaga
		if not hit_player.pixel_color == Global.game_manager.game_settings["player_start_color"]: # če nima nobene barve mu je ne prevzamem
			tween_color_change(hit_player.pixel_color)
		end_move()
		change_stat("hit_player", hit_player.player_stats["player_points"]) # točke glede na delež loserjevih točk, energija se resetira na 100%
		hit_player.on_get_hit(burst_speed) # po statistiki, da winer pobere od luserja, ko so točke še polne  
	
		
func on_hit_wall():
	
	Input.start_joy_vibration(0, 0.5, 0.6, 0.7)
	play_sound("hit_wall")
	spawn_dizzy_particles()
	spawn_collision_particles()
	shake_player_camera(burst_speed)
	
	got_hit = true # da heartbeat animacija ne povozi die animacije
	
	if player_stats["player_energy"] <= 1: # more bit pred statistiko
		stop_heart()
	
	
	change_stat("hit_wall", 1) # točke in energija glede na delež v settingsih, energija na 0 in izguba lajfa, če je "lose_life_on_hit"
	
	die() # vedno sledi statistiki


func on_get_hit(hit_burst_speed: float):
	
	# efekti
	Input.start_joy_vibration(0, 0.5, 0.6, 0.7)
	play_sound("hit_wall")
	spawn_dizzy_particles()
	shake_player_camera(hit_burst_speed)
	
	pixel_color = Global.game_manager.game_settings["player_start_color"] # postane začetne barve
	got_hit = true # da heartbeat animacija ne poveozi die animacije
	
	if player_stats["player_energy"] <= 1: # more bit pred statistiko
		stop_heart()
	
	change_stat("get_hit", 1) # točke in energija glede na delež v settingsih, energija na 0 in izguba lajfa, če je "lose_life_on_hit"
	
	die() # vedno sledi statistiki
	
	

# LIFE LOOP ----------------------------------------------------------------------------------------


func die():
	
	end_move()
	
	set_physics_process(false)
	animation_player.stop()
	animation_player.play("die_player")

	change_stat("die", 1) # izguba lajfa, če je energija 0

	
func revive():
	
	var dead_time: float = 0.3
	yield(get_tree().create_timer(dead_time), "timeout")
	animation_player.play("revive")


func stop_heart():
	
	# resetiram problematično
	modulate.a = 1
	burst_light.enabled = false
	
	change_stat("stop_heart", 1) # energija = 0
	

func all_cleaned():
	
	animation_player.play("become_white_again")
	set_physics_process(false) # malo kasneje se kliče tudi v GM
	
	
# SPAWNING ------------------------------------------------------------------------------------------


func spawn_dizzy_particles():
	
	var new_dizzy_pixels = PixelDizzyParticles.instance()
	new_dizzy_pixels.global_position = global_position
	if pixel_color == Global.game_manager.game_settings["player_start_color"]:
		new_dizzy_pixels.modulate = Color.white
	else:
		new_dizzy_pixels.modulate = pixel_color
	Global.node_creation_parent.add_child(new_dizzy_pixels)
	

func spawn_collision_particles():
	
	var new_collision_pixels = PixelCollisionParticles.instance()
	new_collision_pixels.global_position = global_position
	if pixel_color == Global.game_manager.game_settings["player_start_color"]:
		new_collision_pixels.modulate = Color.white
	else:
		new_collision_pixels.modulate = pixel_color
	match direction:
		Vector2.UP: new_collision_pixels.rotate(deg2rad(-90))
		Vector2.DOWN: new_collision_pixels.rotate(deg2rad(90))
		Vector2.LEFT: new_collision_pixels.rotate(deg2rad(180))
		Vector2.RIGHT:new_collision_pixels.rotate(deg2rad(0))
	Global.node_creation_parent.add_child(new_collision_pixels)
	

func spawn_cock_ghost(cocking_direction: Vector2):
	
	var cocked_ghost_alpha: float = 1 # najnižji alfa za ghoste ... old 0.55
	var cocked_ghost_alpha_divider: float = 5 # faktor nižanja po zaporedju (manjši je bolj oster) ... old 14
	
	# spawn ghosta pod manom
	var cock_ghost_position = (global_position - cocking_direction * cell_size_x/2) + (cocking_direction * cell_size_x * (cocked_ghosts.size() + 1)) # +1, da se ne začne na pixlu
	var new_cock_ghost = spawn_ghost(cock_ghost_position)
	new_cock_ghost.z_index = 3 # nad straysi in playerjem
	new_cock_ghost.modulate.a  = cocked_ghost_alpha - (cocked_ghosts.size() / cocked_ghost_alpha_divider)
	new_cock_ghost.direction = cocking_direction
	
	# v kateri smeri je scale
	if direction.y == 0: # smer horiz
		new_cock_ghost.scale.x = 0
	elif direction.x == 0: # smer ver
		new_cock_ghost.scale.y = 0

	# animiram cock celico
	var cock_cell_tween = get_tree().create_tween()
	cock_cell_tween.tween_property(new_cock_ghost, "scale", Vector2.ONE, cock_ghost_cocking_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	cock_cell_tween.parallel().tween_property(new_cock_ghost, "position", global_position + cocking_direction * cell_size_x * (cocked_ghosts.size() + 1), cock_ghost_cocking_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# ray detect velikost je velikost napenjanja
	new_cock_ghost.ghost_ray.cast_to = direction * cell_size_x
	new_cock_ghost.connect("ghost_detected_body", self, "_on_ghost_detected_body")
	
	return new_cock_ghost
	
	
func spawn_trail_ghost():
	
	var trail_alpha: float = 0.25
	var trail_ghost_fade_time: float = 0.4
	var new_trail_ghost = spawn_ghost(global_position)
	new_trail_ghost.modulate = pixel_color
	new_trail_ghost.modulate.a = trail_alpha
	
	# fadeout
	var trail_fade_tween = get_tree().create_tween()
	trail_fade_tween.tween_property(new_trail_ghost, "modulate:a", 0, trail_ghost_fade_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	trail_fade_tween.tween_callback(new_trail_ghost, "queue_free")
	
	
func spawn_ghost(ghost_spawn_position: Vector2):
	
	var new_pixel_ghost = Ghost.instance()
	new_pixel_ghost.global_position = ghost_spawn_position
	new_pixel_ghost.modulate = pixel_color
	new_pixel_ghost.ghost_owner = self # da "sebe" ne čekira
	Global.node_creation_parent.add_child(new_pixel_ghost)

	return new_pixel_ghost

	
func spawn_floating_tag(value: int):
	
	if value == 0:
		return
	
	var new_floating_tag = FloatingTag.instance()
	new_floating_tag.z_index = 4 # višje od straysa in playerja
	new_floating_tag.global_position = global_position
	new_floating_tag.tag_owner = self
	Global.node_creation_parent.add_child(new_floating_tag)
	
	if value < 0:
		new_floating_tag.modulate = Global.color_red
		new_floating_tag.label.text = str(value)
	elif value > 0:
		new_floating_tag.label.text = "+" + str(value)
		

# UTIL --------------------------------------------------------------------------------------------


func detect_collision_in_direction(direction_to_check):

	if direction_to_check == Vector2.ZERO:
		# vision.look_at(global_position)
		for ray in vision_rays:
			ray.cast_to = Vector2.ZERO
		return
		
	# obrnem vision grupo v smeri...
	vision.look_at(global_position + direction_to_check)
	
	# vsi ray gledajo naravnost
	for ray in vision_rays:
		ray.cast_to = Vector2(47.5, 0) # en pixel manj kot 48, da ne seže preko celice
	
	# grebanje kolajderja	
	var first_collider: Node2D
	for ray in vision_rays:
		ray.add_exception(self)
		ray.force_raycast_update()
		if ray.is_colliding():
			first_collider = ray.get_collider()
			break # ko je kolajder neham čekirat
	
	return first_collider
	
	
func get_step_time():
	
	if Global.game_manager.game_settings["step_slowdown_mode"]:
		var slow_trim_size: float = step_time_slow * Global.game_manager.game_settings["player_max_energy"]
		var energy_factor: float = (Global.game_manager.game_settings["player_max_energy"] - slow_trim_size) / player_stats["player_energy"]
		var energy_step_time = energy_factor / step_slowdown_rate # variabla, da FP ne kliče na vsak frejm
		return clamp(energy_step_time, step_time_fast, step_time_slow) # omejim najbolj počasno korakanje
	else:
		return step_time_fast	
		

func shake_player_camera(current_burst_speed: float):
	
	var shake_multiplier: float = current_burst_speed / cock_ghost_speed_addon
	var shake_multiplier_factor: float = 0.03
	
	var shake_power: float = 0.2
	var shake_power_multiplied: float = shake_power + shake_multiplier_factor * shake_multiplier
	var shake_time: float = 0.3
	var shake_time_multiplied: float = shake_time + shake_multiplier_factor * shake_multiplier
	var shake_decay: float = 0.7
		
	player_camera.shake_camera(shake_power_multiplied, shake_time_multiplied, shake_decay)	

				
func check_strays_neighbors(hit_stray: KinematicBody2D):

		var all_neighboring_strays: Array = [] # vsi nabrani sosedi
		var neighbors_checked: Array = [] # vsi sosedi, katerih sosede sem že preveril
		
		var hit_direction = direction
		
		# prva runda ... sosede zadetega straya
#		var first_neighbors: Array = hit_stray.check_for_neighbors(hit_direction) # hit direction je zato da opredelim smer preverjanja sosedov
#		var first_neighbors: Array = hit_stray.check_for_neighbor_strays() # hit direction je zato da opredelim smer preverjanja sosedov
		var first_neighbors: Array = hit_stray.get_neighbor_strays_on_hit() # hit direction je zato da opredelim smer preverjanja sosedov
		for first_neighbor in first_neighbors:
			if not all_neighboring_strays.has(first_neighbor): # če še ni dodan med vse sosede
				all_neighboring_strays.append(first_neighbor) # ... ga dodam med vse sosede
		neighbors_checked.append(hit_stray) # zadeti stray gre med "že preverjene" 
		
		# druga runda ... sosede vseh sosed
		for neighbor in all_neighboring_strays:
			if not neighbors_checked.has(neighbor): # če še ni med "že preverjenimi" ...
				var extra_neighbors: Array = neighbor.get_neighbor_strays_on_hit() # ... preverim še njegove sosede
#				var extra_neighbors: Array = neighbor.check_for_neighbor_strays() # ... preverim še njegove sosede
				for extra_neighbor in extra_neighbors:
					if not all_neighboring_strays.has(extra_neighbor):  # če še ni dodan med vse sosede ...
						all_neighboring_strays.append(extra_neighbor) # ... ga dodam med vse sosede
				neighbors_checked.append(neighbor) # po nabirki ga dodam med preverjene sosede
		
		# hit stray izbrišem iz sosed, ker bo uničen posebej
		if all_neighboring_strays.has(hit_stray): 
			all_neighboring_strays.erase(hit_stray)
			
		return all_neighboring_strays
		

func tween_color_change (new_color: Color):
	
	change_to_color = new_color # če kokam pred končanjem tweena, vzamem to barvo
	
	change_color_tween = get_tree().create_tween().set_pause_mode(SceneTreeTween.TWEEN_PAUSE_PROCESS)
	change_color_tween.tween_property(self, "pixel_color", new_color, 0.5).set_ease(Tween.EASE_IN) #.set_trans(Tween.TRANS_CIRC)


func burst_light_on():
	
	if burst_light.enabled:
		return	
		
	var burst_light_base_energy: float = 0.6
	var burst_light_energy: float = burst_light_base_energy / pixel_color.v
	burst_light_energy = clamp(burst_light_energy, 0.5, 1.4) # klempam za dark pixel
	
	var light_fade_in = get_tree().create_tween()
	light_fade_in.tween_callback(burst_light, "set_enabled", [true])
	light_fade_in.tween_property(burst_light, "energy", burst_light_energy, 0.2).set_ease(Tween.EASE_IN)


func burst_light_off():

	if not burst_light.enabled:
		return	
			
	var light_fade_out = get_tree().create_tween()
	light_fade_out.tween_property(burst_light, "energy", 0, 0.3).set_ease(Tween.EASE_IN)
	light_fade_out.tween_callback(burst_light, "set_enabled", [false])


func skill_light_on(): 
	
	if skill_light.enabled:
		return
	
	skill_light.rotation = vision.rotation
	
	var skilled_light_base_energy: float = 0.7
	var skilled_light_energy: float = skilled_light_base_energy / pixel_color.v
	skilled_light_energy = clamp(skilled_light_energy, 0.5, 1.3) # klempam za dark pixel
	
	var light_fade_in = get_tree().create_tween()
	light_fade_in.tween_callback(skill_light, "set_enabled", [true])
	light_fade_in.tween_property(skill_light, "energy", skilled_light_energy, 0.2).set_ease(Tween.EASE_IN)
	
	
func skill_light_off():

	if not skill_light.enabled:
		return	
	var light_fade_out = get_tree().create_tween()
	light_fade_out.tween_property(skill_light, "energy", 0, 0.3).set_ease(Tween.EASE_IN)
	light_fade_out.tween_callback(skill_light, "set_enabled", [false])


func manage_heartbeat():
	
	if player_stats["player_energy"] == 1 and not got_hit: # just hit, je da heartbeat animacija ne povozi die animacije
		if not animation_player.get_current_animation() == "heartbeat": # prehod v harbit
			heartbeat_loop = 0
			animation_player.play("heartbeat")		
	elif player_stats["player_energy"] > 1: # revitalizacija
		if animation_player.get_current_animation() == "heartbeat":
			animation_player.stop()
			# resetiram problematično
			modulate.a = 1
			burst_light.enabled = false
			

# SOUNDS ------------------------------------------------------------------------------------------


func play_stepping_sound(current_player_energy_part: float):

	if Global.sound_manager.game_sfx_set_to_off:
		return		

	var random_step_index = randi() % $Sounds/Stepping.get_child_count()
	var selected_step_sound = $Sounds/Stepping.get_child(random_step_index)
	selected_step_sound.pitch_scale = clamp(current_player_energy_part, 0.6, 1)
	selected_step_sound.play()

	
func play_sound(effect_for: String):
	
	if Global.sound_manager.game_sfx_set_to_off:
		return	
		
	match effect_for:
		"blinking":
			var random_blink_index = randi() % $Sounds/Blinking.get_child_count()
			$Sounds/Blinking.get_child(random_blink_index).play() # nekateri so na mute, ker so drugače prepogosti soundi
			var random_static_index = randi() % $Sounds/BlinkingStatic.get_child_count()
			$Sounds/BlinkingStatic.get_child(random_static_index).play()
		"heartbeat":
			$Sounds/Heartbeat.play()
		# bursting
		"hit_stray":
			$Sounds/Burst/HitStray.play()
		"hit_wall":
			$Sounds/Burst/HitWall.play()
			$Sounds/Burst/HitDizzy.play()
		"burst":
			yield(get_tree().create_timer(0.1), "timeout")
			$Sounds/Burst/Burst.play()
			$Sounds/Burst/BurstLaser.play()
		"burst_cocking":
			if $Sounds/Burst/BurstCocking.is_playing():
				return
			$Sounds/Burst/BurstCocking.play()
		"burst_uncocking":
			if $Sounds/Burst/BurstUncocking.is_playing():
				return
			$Sounds/Burst/BurstUncocking.play()			
		"burst_stop":
			$Sounds/Burst/BurstStop.play()
		# skills
		"pushpull_start":
			$Sounds/Skills/PushPull.play()
		"pushpull_end":
			$Sounds/Skills/PushedPulled.play()
		"pulled":
			$Sounds/Skills/StoneSlide.play()
		"pushed":
			$Sounds/Skills/Cling.play()
			$Sounds/Skills/StoneSlide.play()
		"teleport":
			$Sounds/Skills/TeleportIn.play()


func stop_sound(stop_effect_for: String):
	
	match stop_effect_for:
		"teleport":
			if $Sounds/Skills/TeleportLoop.is_playing(): # konec teleportanja
				$Sounds/Skills/TeleportLoop.stop()
				$Sounds/Skills/TeleportOut.play()
			else: # zazih ob koncu igre
				$Sounds/Skills/TeleportLoop.stop()
		"burst_cocking":
			$Sounds/Burst/BurstCocking.stop()
		"burst_uncocking":
			$Sounds/Burst/BurstUncocking.stop()	
		"heartbeat":
			$Sounds/Heartbeat.stop()


# SIGNALI ------------------------------------------------------------------------------------------
	
		
func _on_ghost_target_reached(ghost_body: Area2D, ghost_position: Vector2):
	
	stop_sound("teleport")
	Input.stop_joy_vibration(0)
			
	var ghost_fade_time: float = 0.5
	global_position = ghost_position
	modulate.a = 1
	if player_camera:
		player_camera.camera_target = self
	glow_light.enabled = true
	collision_shape.set_deferred("disabled", false)
	collision_shape_ext.set_deferred("disabled", false)
	ghost_body.queue_free()
	end_move()
	
	change_stat("skill_used", 3) # zazih ni v tweenu	
	

func _on_ghost_detected_body(body: Node2D):
	
	if body != self:
		cocking_room = false
		

func _on_TeleportIn_finished() -> void:
	
	$Sounds/Skills/TeleportLoop.play()


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	
	match anim_name:
		"lose_white_on_start":
			# setam looknfeel playerja ob štartu FP
			color_poly.modulate = pixel_color
			var player_fade_in = get_tree().create_tween()
			player_fade_in.tween_property(self, "modulate:a", 1, 0.2)
			player_fade_in.parallel().tween_property(glow_light, "energy", 1.5, 0.5)
		"heartbeat":
			heartbeat_loop += 1
			if heartbeat_loop <= 5:
				animation_player.play("heartbeat")
			else:
				stop_heart()
				die()
		"die_player":
			if player_stats["player_life"] > 0:
				revive()
			else:
				Global.game_manager.game_over(Global.game_manager.GameoverReason.LIFE)
		"revive":
			set_physics_process(true)
			got_hit = false # reset ... da se heartbeat animacija lahko začne
			change_stat("revive", 1) # če energija = 0 (izguba lajfa), resetira energijo
		"become_white_again":
			yield(get_tree().create_timer(0.2), "timeout") # za dojet
			change_stat("all_cleaned", 1) # nagrada je določena v settingsih
			emit_signal("rewarded_on_game_over") # javi v GM

		
# STATS ----------------------------------------------------------------------------------------------


func change_stat(stat_event: String, stat_value):
	
	if not Global.game_manager.game_on and not stat_event == "all_cleaned": # statistika se ne beleži več, razen "all_cleaned"
		return
		
	match stat_event:
		# SKILL & BURST ---------------------------------------------------------------------------------------------------------------
		"cells_traveled": # štetje, točke in energija kot je določeno v settingsih
			player_stats["cells_traveled"] += 1
			player_stats["player_energy"] += game_settings["cell_traveled_energy"]
			player_stats["player_points"] += game_settings["cell_traveled_points"]
		"skill_used": # štetje, točke in energija kot je določeno v settingsih
			player_stats["skill_count"] += 1
			player_stats["player_energy"] += game_settings["skill_used_energy"]
			player_stats["player_points"] += game_settings["skill_used_points"]
			# tutorial
			if Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL:
				match stat_value:
					1: Global.tutorial_gui.skill_done("push")
					2: Global.tutorial_gui.skill_done("pull")
					3: Global.tutorial_gui.skill_done("teleport")
		"burst_released": # štetje, točke in energija kot je določeno v settingsih
			player_stats["burst_count"] += 1
			player_stats["player_energy"] += game_settings["burst_released_energy"]
			player_stats["player_points"] += game_settings["burst_released_points"]
		# HITS ------------------------------------------------------------------------------------------------------------------
		"hit_stray": # štetje, točke in energija glede na število uničenih straysov
			var stack_strays_celaned_count: int = stat_value
			var points_to_gain: int = 0
			var energy_to_gain: int = 0
			for stray_in_row in stack_strays_celaned_count:
				points_to_gain += game_settings["color_picked_points"] * (stray_in_row + 1) # + 1 je da se izognem nuli
				energy_to_gain += game_settings["color_picked_energy"] * (stray_in_row + 1)
			player_stats["colors_collected"] += stack_strays_celaned_count
			player_stats["player_points"] += points_to_gain
			player_stats["player_energy"] += energy_to_gain
			spawn_floating_tag(points_to_gain)
			Global.game_manager.strays_in_game_count = - stack_strays_celaned_count # GM strays sum
			if Global.game_manager.game_data["game"] == Profiles.Games.TUTORIAL: # tutorial
				Global.tutorial_gui.finish_bursting()
				if stack_strays_celaned_count >= 3:
					Global.tutorial_gui.finish_stacking()
		"hit_player": # točke glede na delež loserjevih točk, energija se resetira na 100%
			var hit_player_current_points: int = stat_value
			player_stats["player_energy"] = game_settings["player_max_energy"]
			var points_to_gain: int = round(hit_player_current_points / game_settings["on_hit_points_part"])
			player_stats["player_points"] += points_to_gain
			spawn_floating_tag(points_to_gain)
		"hit_wall": # točke in energija glede na delež v settingsih, energija na 0 in izguba lajfa, če je "lose_life_on_hit"
			if Global.game_manager.game_settings["lose_life_on_hit"]:
				player_stats["player_energy"] = 0
			else:
				player_stats["player_energy"] -= round(player_stats["player_energy"] / game_settings["on_hit_energy_part"])
			var points_to_lose = round(player_stats["player_points"] / game_settings["on_hit_points_part"])
			player_stats["player_points"] -= points_to_lose
			spawn_floating_tag(- points_to_lose) 
		"get_hit": # točke in energija glede na delež v settingsih, energija na 0 in izguba lajfa, če je "lose_life_on_hit"
			if Global.game_manager.game_settings["lose_life_on_hit"]:
				player_stats["player_energy"] = 0
			else:
				player_stats["player_energy"] -= round(player_stats["player_energy"] / game_settings["on_hit_energy_part"])
			var points_to_lose = round(player_stats["player_points"] / game_settings["on_hit_points_part"])
			player_stats["player_points"] -= points_to_lose
			spawn_floating_tag(- points_to_lose) 
		# LIFE LOOP ------------------------------------------------------------------------------------------------------------
		"die": # izguba lajfa, če je energija 0
			if player_stats["player_energy"] == 0: # energija = 0 samo zaradi srčka ali hita, če je "lose_life_on_hit"
				player_stats["player_life"] -= 1
		"stop_heart": # energija je 0
			player_stats["player_energy"] = 0
		"revive": # resetiranje energije, če je izgubil lajfa (energija = 0)
			if player_stats["player_energy"] == 0: # energija = 0 samo zaradi srčka ali hita, če je "lose_life_on_hit"
				player_stats["player_energy"] = game_settings["player_max_energy"]	
		# XTRA ---------------------------------------------------------------------------------------------------------------
		"touching_stray": # če se dotikaš
			player_stats["player_energy"] += game_settings["touching_stray_energy"]
#
#			player_stats["player_points"] += game_settings["all_cleaned_points"]
#			spawn_floating_tag(game_settings["all_cleaned_points"])
		"all_cleaned": # nagrada je določena v settingsih
			player_stats["player_points"] += game_settings["all_cleaned_points"]
			spawn_floating_tag(game_settings["all_cleaned_points"])
		"debug_player_energy":
			player_stats["player_energy"] += stat_value
			player_stats["player_energy"] = clamp(player_stats["player_energy"], 5, game_settings["player_start_energy"])
	
	# klempanje
	player_stats["player_energy"] = round(player_stats["player_energy"])
	player_stats["player_energy"] = clamp(player_stats["player_energy"], 0, game_settings["player_max_energy"])
	player_stats["player_points"] = clamp(player_stats["player_points"], 0, player_stats["player_points"])	
	
	# signal na hud
	emit_signal("stat_changed", self, player_stats) # javi v hud



