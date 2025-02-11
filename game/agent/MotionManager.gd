extends Node
class_name MotionManager


var managed_agent: Node2D  # = get_parent()

enum MOTION {IDLE, FWD, REV, DISSARAY}
var motion: int = MOTION.IDLE # setget _change_motion

enum ROTATION_MOTION {
	DEFAULT,
	DRIFT,
	SPIN,
	SLIDE,
#	AGILE,
#	TRACKING,
	}
var rotation_motion: int = ROTATION_MOTION.DEFAULT

const AKA_ZERO_MASS: float = 1.0 # malo vpliva vseeno more met vsaka od mas

# debug ...
# lahko zamštraš indexe, kasneje to seta igra
export (int) var selected_rotation_motion: int = ROTATION_MOTION.DEFAULT
export (int) var selected_idle_rotation: int = ROTATION_MOTION.SPIN
var is_ai: bool = false

var force_on_agent: Vector2 = Vector2.ZERO
var torque_on_agent: float = 0
var is_boosting: bool = false

# engine
var current_engine_power: float = 0
var engine_power_addon: float = 0
var accelarate_speed = 0.1
var max_engine_power: float

# rotation
var rotation_dir = 0 setget _change_rotation_direction
var force_rotation: float = 0 # rotacija smeri kamor je usmerjen skupen pogon
var engine_rotation_speed: float
var max_engine_rotation_deg: float
var driving_gear: int = 0
var engine_power_percentage: float # neu namesto engine power


func _input(event: InputEvent) -> void:#input(event: InputEvent) -> void:

	if Input.is_action_just_pressed("no0"): # idle
		motion = MOTION.DISSARAY


func _ready() -> void:
	#	yield(get_tree(),"idle_frame")
	#	self.rotation_dir = 0
	pass


func _process(delta: float) -> void:

	if not managed_agent.is_active: # tole seta tudi na startu
		current_engine_power = 0 # cela sila je pade na 0
		#		force_on_agent = Vector2.ZERO
		#		force_rotation = 0
		self.rotation_dir = 0
	else:
		# PLAYER ima drugače kot AI ...
		_motion_machine()
		managed_agent.engines.manage_engines(self)

	# debug
	var vector_to_target = force_on_agent.normalized() * 0.5 * current_engine_power
	vector_to_target = vector_to_target.rotated(- managed_agent.global_rotation)
	managed_agent.direction_line.set_point_position(1, vector_to_target)
	managed_agent.direction_line.default_color = Color.green


func _motion_machine():
	match motion:
		MOTION.FWD:
			if is_ai:
				force_on_agent = Vector2.RIGHT.rotated(force_rotation) * _accelarate_to_engine_power()
				# force_rotation = proti tarči AI ... določa AI
			else:
				force_rotation = lerp_angle(force_rotation, rotation_dir * deg2rad(max_engine_rotation_deg), engine_rotation_speed)
				force_on_agent = Vector2.RIGHT.rotated(force_rotation + managed_agent.global_rotation) * _accelarate_to_engine_power()
		MOTION.REV:
			if is_ai:
				force_on_agent = Vector2.LEFT.rotated(force_rotation) * _accelarate_to_engine_power()
				# force_rotation = proti tarči AI ... določa AI
			else:
				force_rotation = lerp_angle(force_rotation, - rotation_dir * deg2rad(max_engine_rotation_deg), engine_rotation_speed)
				force_on_agent = Vector2.LEFT.rotated(force_rotation + managed_agent.global_rotation) * _accelarate_to_engine_power()
		MOTION.IDLE:
			force_rotation = 0
			force_on_agent = Vector2.ZERO
		MOTION.DISSARAY: # luzes all control ... prekine ga lahko samo zunanji elementa ali reštart
			force_rotation = 0
			force_on_agent = Vector2.ZERO


func _accelarate_to_engine_power():

	# če je dodatek k moči klempam na max power + dodatek
	if engine_power_addon == 0:
		current_engine_power = lerp(current_engine_power, max_engine_power, accelarate_speed)
	else:
		current_engine_power = lerp(current_engine_power, max_engine_power + engine_power_addon, accelarate_speed)

	current_engine_power = clamp(current_engine_power, 0, current_engine_power)

	engine_power_percentage = current_engine_power / max_engine_power

	return current_engine_power * Sts.world_hsp_power_factor


func boost_agent(added_power: float = 0, boosting_time: float = 0):
	# nitro vpliva na trenutno moč, ker ga lahko uporabiš tudi ko greš počasi ... povečaš pa tudi max power, če ima že max hitrost

	if not is_boosting:
		is_boosting = true
		Rfs.sound_manager.play_sfx("pickable_nitro")
		if added_power == 0:
			added_power = Pfs.equipment_profiles[Pfs.EQUIPMENT.NITRO]["nitro_power_addon"]
		engine_power_addon += added_power
		if boosting_time == 0:
			boosting_time = Pfs.equipment_profiles[Pfs.EQUIPMENT.NITRO]["time"]
		yield(get_tree().create_timer(boosting_time),"timeout")

		engine_power_addon -= added_power
		is_boosting = false


func _print_agent_data():

	printt("engine", max_engine_power, max_engine_rotation_deg, engine_rotation_speed)
	printt("_agent", managed_agent.mass, managed_agent.linear_damp, managed_agent.angular_damp)
	printt("_front", managed_agent.front_mass.mass, managed_agent.front_mass.linear_damp, managed_agent.front_mass.angular_damp)
	printt("_rear", managed_agent.rear_mass.mass, managed_agent.rear_mass.linear_damp, managed_agent.rear_mass.angular_damp)
	printt("_torq", torque_on_agent)


# imajo otroci ------------------------------------------------------------------------------------


func _change_rotation_direction(new_rotation_direction: float):
	pass
	# za zavijanje lahko vplivam na karkoli, ker se ob vožnji naravnost vse reseta
	# če ne zavija je fizika celega agenta
	# če zavija se porazdeli glede na stil


func _set_default_parameters():
	pass


