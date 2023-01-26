extends KinematicBody2D


signal Got_bonus
signal Player_stat_changed # (player_index, changed_stat_name, changed_stat_new_value) ... zabrisano, ker niso zmeraj enaka imena variable

# pošiljanje statistike
var changed_stat_name : String # za prenašanje imena stata s signalom
var changed_stat_new_value : int # za prenašanje vrednosti stata s signalom (lahko int ali float)

# te akcije so v kodi za kontrole
var player_forward_action_name: String
var player_backward_action_name: String
var player_left_action_name: String
var player_right_action_name: String
var player_shoot_action_name: String

# per player properties ... se pošlje ob generaciji iz plejer managerja
var player_index : int
var player_name : String
var player_color : Color
var player_controller_profile : Dictionary
var player_game_stats : Dictionary

# motion
var collision : KinematicCollision2D
var input_power : Vector2
var velocity : Vector2
var rotation_dir : float
var slajdej = false

# in-house player properties
var motion_enabled : = true
var weapon_reloaded = true

var def_pogon_particle_speed = 2.22
var input_pressed_time : int # resnična moč pritiska

onready var weapon_relaod_time : float = GameProfiles.weapon_values["weapon_relaod_time"]
onready var input_pressed_goal : int = GameProfiles.weapon_values["misile_load_time"]
onready var disabled_player_color : Color = GameProfiles.default_game_theme["disabled_player_color"]

# motion iz game profiles
onready var def_friction : float = GameProfiles.player_motion_values["friction"]
onready var def_bounce_size : float = GameProfiles.player_motion_values["bounce_size"]
onready var accelaration = GameProfiles.player_motion_values["accelaration"]
onready var max_speed = GameProfiles.player_motion_values["max_speed"]
onready var rotation_speed = GameProfiles.player_motion_values["rotation_speed"]
onready var friction = GameProfiles.player_motion_values["friction"]
onready var bounce_size = GameProfiles.player_motion_values["bounce_size"]


# -----------------------------------------------------------------------------------------------------------------------------


func _ready() -> void:

	rotation_dir = 0
	modulate = player_color
#	add_to_group("players")

	# vsako akcijo v igralčevem kontroler profilu podaj v pripadajočo spremenljivko
	# ustvari akcije in jim določi kontrole
	for player_action_name in player_controller_profile.keys():
		if GameProfiles.forward_action_name in player_action_name:
			player_forward_action_name = player_action_name
		elif GameProfiles.backward_action_name in player_action_name:
			player_backward_action_name = player_action_name
		elif GameProfiles.left_action_name in player_action_name:
			player_left_action_name = player_action_name
		elif GameProfiles.right_action_name in player_action_name:
			player_right_action_name = player_action_name
		elif GameProfiles.shoot_action_name in player_action_name:
			player_shoot_action_name = player_action_name

		# za vsako akcijo v kontroler profilu naredimo akcijo in ji pripišemo gumb
		InputMap.add_action(player_action_name)
		var action_key = InputEventKey.new()
		action_key.scancode = player_controller_profile[player_action_name]
		InputMap.action_add_event(player_action_name, action_key)


func _physics_process(delta: float) -> void:

	# smer rotacije
	rotation_dir = Input.get_axis(player_left_action_name, player_right_action_name)

	# gibanje omogočeno?
	if motion_enabled == true:

		modulate = player_color

		# pospešek
		input_power.x = Input.get_action_strength(player_forward_action_name)

		# FX
		if Input.is_action_just_pressed(player_forward_action_name) == true:
		#	$Pogon_Fx.play()
			$Pogon_Part.set_emitting(true)
		elif Input.is_action_just_released(player_forward_action_name) == true:
			$Pogon_Fx.stop()
			$Pogon_Part.set_emitting(false)

		# bremza
		if Input.get_action_strength(player_backward_action_name) !=  0:
			friction += 0.001
		else:
			friction = def_friction
	else:
		modulate = disabled_player_color
		input_power.x = 0

	# hitrost
	velocity += Vector2(input_power.x * accelaration * delta, 0).rotated(rotation) # zadnja rotacija je dodana, da hitrost spreminja v smeri igralčeve osi

	# omejimo hitrost
	velocity.x = clamp(velocity.x, -max_speed, max_speed)
	velocity.y = clamp(velocity.y, -max_speed, max_speed)

	# vpliv trenja
	if input_power.x == 0 && velocity != Vector2.ZERO:
		velocity = lerp(velocity, Vector2.ZERO, friction)
		if abs(velocity.x) <= 0.1:	# zaokrožimo z 0.1 na 0, da ne bo računal v neskončnost
			velocity.x = 0
		if abs(velocity.y) <= 0.1:
			velocity.y = 0

	if Input.get_action_strength(player_shoot_action_name) and Global.node_creation_parent != null:
		shoot_weapon()

	else:
		# tukaj bi moral štartat timer, če bi želel, da je treb spusti tipko za reload
		input_pressed_time = 0


	# GIBANJE -------------------------------------------------------------------------------------

	rotate(rotation_dir * delta * rotation_speed)
	collision = move_and_collide(velocity * delta)

	if collision:
		on_collision()
	else:
#		move_and_slide(velocity)
		pass


func shoot_weapon():

	if input_pressed_time < input_pressed_goal:
		input_pressed_time += 1 # merimo dolžino stiska tipke
		if weapon_reloaded == true:
			if player_game_stats["bullet_no"] > 0:
				Global.weapon_manager.create_bullet(player_index, player_color, position, rotation)
				player_game_stats["bullet_no"] -= 1
				weapon_reloaded= false
				yield(get_tree().create_timer(weapon_relaod_time), "timeout")
				weapon_reloaded= true
				emit_signal ("Player_stat_changed", player_index, "bullet_no", player_game_stats["bullet_no"])
			else:
				print ("bullet KLIK, KLIK, KLIK ...")


	elif input_pressed_time >= input_pressed_goal:
		if weapon_reloaded == true:
#			emit_signal("Player_is_shooting", player_index, position, rotation, "misile")

			if player_game_stats["misile_no"] > 0:
				Global.weapon_manager.create_misile(player_index, player_color, position, rotation)
				player_game_stats["misile_no"] -= 1
				weapon_reloaded= false
				yield(get_tree().create_timer(weapon_relaod_time), "timeout")
				weapon_reloaded= true
				emit_signal ("Player_stat_changed", player_index, "misile_no", player_game_stats["misile_no"])
			else:
				print ("misile KLIK, KLIK, KLIK ...")

			input_pressed_time = 0 # za proti autošut


func on_collision(): # tukaj pride lahko še kar nekaj pogojevanja glede na sorto karambola

	velocity = velocity.bounce(collision.normal) * bounce_size # bounce karambol s kontrolerjem velikosti bounca

	if player_game_stats["energy"] > 1:

		if collision.collider.is_in_group("bullets"):
			player_game_stats["energy"] -= GameProfiles.weapon_values["bullet_pow"]
			emit_signal ("Player_stat_changed", player_index, "energy", player_game_stats["energy"])
			owner_get_score(collision.collider.name, GameProfiles.weapon_values["bullet_score"])
		elif collision.collider.is_in_group("misiles"):
			player_game_stats["energy"] -= GameProfiles.weapon_values["misile_pow"]
			owner_get_score(collision.collider.name, GameProfiles.weapon_values["misile_score"])
		elif collision.collider.is_in_group("mine"):
			player_game_stats["energy"] -= GameProfiles.weapon_values["mina_pow"]
			owner_get_score(collision.collider.name, GameProfiles.weapon_values["mina_score"])

	elif player_game_stats["energy"] <= 1:

		player_game_stats["life"] -= 1
		emit_signal ("Player_stat_changed", player_index, "life", player_game_stats["life"])

		if player_game_stats["life"] > 0: 	# s tem pogojevanjem naredim zamik, da lahko pošljem in sprejmem isti singal
			player_game_stats["energy"] = GameProfiles.default_player_game_stats["energy"]
			emit_signal ("Player_stat_changed", player_index, "energy", player_game_stats["energy"])
#			print("pm LAJF")
		
		# gejmover za plejerja		
		else: # player_game_stats["life"] <= 0:
			print("DEAD")
			print("DEAD")
			print("DEAD")
			print("DEAD")
			emit_signal ("Player_stat_changed", player_index, "energy", player_game_stats["energy"])


func owner_get_score(collider_orig_name, weapon_score):

	# če je nekdo lastnik objekta (igralec = "Owned_by_NAME", lahko je tudi opeka)
	if "owned" in collider_orig_name:

		# iz original imena kolajderja (je v obliki @p1_owned@2), dobimo pravo ime lastnika
		var clean_string = collider_orig_name.trim_prefix("@") # stripamo prefix afna
		
		var owner_index: int = int (clean_string.substr(1,1)) # poberemo index igralca za spreminjanje gamestats
		# var owner_name: String = clean_string.substr(0,3) # poberemo ime igralca

		# opredelim "in-game stats" v profilu lastnika
		var owner_profile: Dictionary = Global.game_manager.game_player_profiles[owner_index]
		var owner_game_stats: Dictionary = owner_profile["player_game_stats"]

		# pripiši skor in ga pošlji
		owner_game_stats["score"] += weapon_score

		emit_signal ("Player_stat_changed", owner_index, "score", owner_game_stats["score"])


func _on_PlayerArea_area_entered(area: Area2D) -> void:

	emit_signal ("Got_bonus", area) # ni še povezan

	print (str(name) + " je v stiku z Area: " + str(area.name))

	if area.name == "BonusM":

		player_game_stats["misile_no"] += area.misile_bonus

		changed_stat_name = "misile_no"
		changed_stat_new_value = player_game_stats["misile_no"]
		emit_signal ("Player_stat_changed", changed_stat_name, changed_stat_new_value, name)

	elif area.name == "BonusE":

		player_game_stats["energy"] = area.energy_bonus

		changed_stat_name = "energy"
		changed_stat_new_value = player_game_stats["energy"]
		emit_signal ("Player_stat_changed", changed_stat_name, changed_stat_new_value, name)

	elif area.name == "PointerForceField":

		player_game_stats["score"] += 50

		$Pogon_Fx.stop()
		$Pogon_Part.set_emitting(false)
#		yield(get_tree().create_timer(2), "timeout")
#		motion_enabled = true
		pass


func _on_PlayerArea_area_exited(area: Area2D) -> void:
#	if area.name == "ForceField":
#	slajdej = false
###		print("DOTIKKKKKKK")
#	friction = def_friction
	pass


func pause_me():
	set_physics_process(false)
	$PlayerTimer.set_paused(true)
	$Pogon_Part.speed_scale = 0


func unpause_me():
	set_physics_process(true)
	$PlayerTimer.set_paused(false)
	$Pogon_Part.speed_scale = def_pogon_particle_speed
