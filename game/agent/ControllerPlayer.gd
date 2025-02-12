extends Node


signal weapon_triggered
signal next_weapon_selected

var controlled_agent: Node2D # temp ... Vechile class
var controller_type: int
var agent_manager: Node

onready var controller_actions: Dictionary = Pfs.controller_profiles[controller_type]
onready var fwd_action: String = controller_actions["fwd_action"]
onready var rev_action: String = controller_actions["rev_action"]
onready var left_action: String = controller_actions["left_action"]
onready var right_action: String = controller_actions["right_action"]
onready var shoot_action: String = controller_actions["shoot_action"]
onready var selector_action: String = controller_actions["selector_action"]

# neu
var pressed_driving_actions: Array = []
var goals_to_reach: Array = [] # lahko v agenta, ker ma tud AI
var selected_item_index = 0
var game_is_on: bool = false
var fast_start_window_is_open: bool = false


func _input(event: InputEvent) -> void:
	# ta del inputa je kar razdelan, ampak ko enkrat registrira vse možnosti ga lahko "pozabim"
	# ga lahko "pozabim" in pedenam _react_to_driving_input()

	if controlled_agent.is_active:

		# select weapon
		if Input.is_action_just_pressed(selector_action):
			selected_item_index += 1
			if selected_item_index > controlled_agent.triggering_weapons.size() - 1: # poskrbi tudi za primer, da je samo en item
				selected_item_index = 0
			elif selected_item_index < 0:
				selected_item_index = controlled_agent.triggering_weapons.size() - 1
			emit_signal("next_weapon_selected", selected_item_index)

		# shoot
		if Input.is_action_pressed(shoot_action):
			var selected_weapon: Node2D = controlled_agent.triggering_weapons[selected_item_index]
			if selected_weapon.has_method("_on_weapon_triggered"):
				selected_weapon._on_weapon_triggered()
			# še vsa orožja istega tipa
			if controlled_agent.group_weapons_by_type:
				for weapon in controlled_agent.weapons.get_children():
					if weapon.weapon_type == selected_weapon.weapon_type:
						weapon._on_weapon_triggered()


		var motion_input_changed: bool = false

		# premikanje
		if Input.is_action_pressed(fwd_action):
			if not fwd_action in pressed_driving_actions:
				pressed_driving_actions.append(fwd_action)
			motion_input_changed = true
		elif Input.is_action_pressed(rev_action):
			if not rev_action in pressed_driving_actions:
				pressed_driving_actions.append(rev_action)
			motion_input_changed = true
		else:
			if fwd_action in pressed_driving_actions:
				pressed_driving_actions.erase(fwd_action)
			if rev_action in pressed_driving_actions:
				pressed_driving_actions.erase(rev_action)
			motion_input_changed = true

		# rotacija
		if Input.get_axis(left_action, right_action) == 1:
			if not right_action in pressed_driving_actions:
				pressed_driving_actions.append(right_action)
			motion_input_changed = true
		elif Input.get_axis(left_action, right_action) == -1:
			if not left_action in pressed_driving_actions:
				pressed_driving_actions.append(left_action)
			motion_input_changed = true
		else:
			if right_action in pressed_driving_actions:
				pressed_driving_actions.erase(right_action)
			if left_action in pressed_driving_actions:
				pressed_driving_actions.erase(left_action)
			motion_input_changed = true


		if motion_input_changed:
			_react_to_driving_input(pressed_driving_actions)


func _ready() -> void:

	controlled_agent.add_to_group(Rfs.group_players)
	# player coližn lejer
	controlled_agent.set_collision_layer_bit(4, true)


func _react_to_driving_input(pressed_actions: Array):

	if not game_is_on and pressed_actions.has(fwd_action):
		controlled_agent.revup()

	if game_is_on:
		if not agent_manager.motion == agent_manager.MOTION.DISSARAY:

			# FWD
			if pressed_actions.has(fwd_action):
				if fast_start_window_is_open:
					if Input.is_action_just_pressed(fwd_action):
						controlled_agent.revup()
						agent_manager.boost_agent(agent_manager.fast_start_power_addon, Sts.fast_start_time)
				agent_manager.motion = agent_manager.MOTION.FWD
			# REV
			elif pressed_actions.has(rev_action):
				agent_manager.motion = agent_manager.MOTION.REV
			# IDLE
			else:
				agent_manager.motion = agent_manager.MOTION.IDLE

			# ROTATION
			if pressed_actions.has(left_action):
				agent_manager.rotation_dir = -1
			elif pressed_actions.has(right_action):
				agent_manager.rotation_dir = 1
			else:
				agent_manager.rotation_dir = 0


func goal_reached(goal_reached: Node2D, extra_target: Node2D = null): # next_target je za ai zaenkrat

	goals_to_reach.erase(goal_reached)


func _on_game_state_change(game_manager: Game): # od GMja

	game_is_on = game_manager.game_on
	fast_start_window_is_open = game_manager.fast_start_window_on

	if game_is_on and fast_start_window_is_open: # na štartu
		print ("fast start open")
		controlled_agent.agent_camera.follow_target = controlled_agent
	elif game_is_on:
		print ("fast start closed")
	else:
		print ("game if off")
		if controlled_agent.is_active: # zazih
			controlled_agent.is_active = false
#			set_physics_process(false)

	# ne vem če hočem vedno ... ponavadi naj bo kar na boltu
	#	elif not game_is_on:
	#		controlled_agent.agent_camera.follow_target = controlled_agent
