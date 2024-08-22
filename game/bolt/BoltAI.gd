extends Bolt

enum AiStates {IDLE, RACE, SEARCH, FOLLOW}
enum AiAttackingMode {NONE, BULLET, MISILE, MINA, TIME_BOMB, MALE}

var current_ai_state: int = AiStates.IDLE
var current_attacking_mode: int = AiAttackingMode.NONE

var ai_navigation_target: Node2D
var navigation_cells: Array # sek
onready var navigation_agent = $NavigationAgent2D
onready var seek_ray = $SeekRay
onready var vision_ray_front = $VisionFront

# ai profil
onready var max_engine_power = Pro.ai_profile["max_engine_power"] # 80
onready var searching_engine_power = max_engine_power * 0.8 

# neu
var not_searcing: bool = true # _temp
var ai_closeup_distance: float = 70
var ai_urgent_stop_distance: float = 20
var current_object_in_vision_field: Array
var ai_brake_distance_factor: float = 0.32 # delež dolžine vektorja hitrosti ... vision ray je na tej dolžini
onready var detect_area: Area2D = $DetectArea


func _ready() -> void:
	
	add_to_group(Ref.group_ai)
	bolt_hud.hide()
		 
	randomize()
	
			
func _physics_process(delta: float) -> void:
	
	if not bolt_active:
		return

	manage_ai_states()
	
	if current_motion_state == MotionStates.DISARRAY:
		acceleration = position.direction_to(Vector2.ZERO) * engine_power # OPT dissaray na novo ...
	else:
		var next_position: Vector2 = navigation_agent.get_next_location()
		acceleration = position.direction_to(next_position) * engine_power
		# navigation_agent.set_velocity(velocity) .. to je za avoidance? # vedno za kustom velocity izračunom
		steering(delta) # more bi pred rotacijo, da se upošteva ... ne vem če kaj vpliva
		rotation = velocity.angle()

	vision(delta)


func manage_ai_states():
	
	if ai_navigation_target == null:
		current_ai_state = AiStates.IDLE
	
	match current_ai_state:
		AiStates.IDLE: # miruje s prižganim motorjem
			engine_power = 0
#			seek_ray.enabled = false
		AiStates.RACE: # šiba po najbližji poti do tarče
			navigation_agent.set_target_location(get_racing_position(ai_navigation_target))
			engine_power = max_engine_power	
			seek_ray.enabled = false
		AiStates.SEARCH: # išče novo tarčo
			if not_searcing:
				var random_position: Vector2 = Met.get_random_member(Ref.current_level.navigation_cells_positions)
				navigation_agent.set_target_location(random_position)
				not_searcing = false
				var indi = Met.spawn_indikator(random_position, ai_navigation_target.global_rotation, Ref.node_creation_parent)
				indi.scale = Vector2.ONE *4
			engine_power = searching_engine_power
#			seek_ray.enabled = false
			# naberem možne tarče in jih potem razporejam
			var best_ranked_target: Node2D = get_detected_stuff()
			# če ma kakšna višjo prioriteto kot trenutna, jo določim
			if best_ranked_target:
				not_searcing = true
				if ai_navigation_target == null:
					set_ai_target(best_ranked_target)
				elif ai_navigation_target is TileMap:
					set_ai_target(best_ranked_target)
					
				else:
					if best_ranked_target.ai_target_rank < ai_navigation_target.ai_target_rank:
						set_ai_target(best_ranked_target)
		AiStates.FOLLOW: # približa se tarči in vzdržuje distanco do nje
			# če je pozicija ista ne spremenim
			if not navigation_agent.get_target_location() == ai_navigation_target.global_position:
				navigation_agent.set_target_location(ai_navigation_target.global_position)
			# seek ray je usmerjen na tarčo in na določeni distanci prilagodi hitrost
			seek_ray.enabled = true
			var ai_brake_factor: float = 0.95 # množenje s hitrostjo
			var ai_shoot_distance: float = 100 # najbližja pri kateri še strelja 		
			seek_ray.look_at(ai_navigation_target.global_position)
			var seek_ray_length: float = global_position.distance_to(ai_navigation_target.global_position)
			seek_ray.cast_to.x = seek_ray_length
			var current_collider = seek_ray.get_collider()
			if seek_ray_length < ai_urgent_stop_distance:
				velocity *= ai_brake_factor
				engine_power = 0.1 # če je čista 0 se noče vrtet 
			elif seek_ray_length < ai_closeup_distance:
				engine_power = max_engine_power
				velocity *= ai_brake_factor
			else:
				engine_power = max_engine_power
			


func select_target_on_priority(possible_target: Node2D):
	
	# plan
	# naberem vse element v vidnem polju, ki imajo ai_rank
	# dam jih v array in razporedim po prioriti ranku
	# potem vključim še razporejanje glede na razdaljo do tarče in smer proti glavnemu cilju
	
	# če dirkam
	match AiStates:
		AiStates.RACE:
			if possible_target.is_in_group(Ref.group_players):
				set_ai_target(possible_target)
		AiStates.SEARCH:
			if possible_target.is_in_group(Ref.group_players):
				set_ai_target(possible_target)
			

func vision(delta: float):

	var ai_brake_factor: float = 0.8 # množenje s hitrostjo
	vision_ray_front.cast_to.x = velocity.length() * ai_brake_distance_factor # zmeraj dolg kot je dolga hitrost
	if vision_ray_front.is_colliding():
		velocity *= ai_brake_factor
		select_target_on_priority(vision_ray_front.get_collider())
		
		
func set_ai_target(new_ai_target: Node2D):
	
	ai_navigation_target = new_ai_target
	
	if ai_navigation_target is Bolt: # is_in_group(Ref.group_bolts):
		current_ai_state = AiStates.FOLLOW	
	elif ai_navigation_target is PathFollow2D:
		current_ai_state = AiStates.RACE	
	elif ai_navigation_target == Ref.current_level.tilemap_edge:
		current_ai_state = AiStates.SEARCH
	else:
		current_ai_state = AiStates.IDLE
						
#	var indi = Met.spawn_indikator(ai_navigation_target.global_position, ai_navigation_target.global_rotation, Ref.node_creation_parent)
#	indi.scale = Vector2.ONE *4
					
		
func get_racing_position(position_tracker: PathFollow2D):
	
	var ai_target_point_on_curve: Vector2
	var ai_target_prediction: float = 50
	var ai_target_total_offset: float = position_tracker.offset + ai_target_prediction
	var bolt_tracker_curve: Curve2D = position_tracker.get_parent().get_curve()
	ai_target_point_on_curve = bolt_tracker_curve.interpolate_baked(ai_target_total_offset)
	
	return ai_target_point_on_curve
			

func get_detected_stuff():
	
	# naberi vse
	var all_detected_stuff: Array = detect_area.get_overlapping_bodies()
	if all_detected_stuff.empty():
		return
	
	# rangiraj po ai ranku
	var stuff_ranked: Array
	for stuff in all_detected_stuff:
		if "ai_target_rank" in stuff and not stuff == self:
			stuff_ranked.append(stuff)
	stuff_ranked.sort_custom(self, "sort_stuff_by_ai_rank")
	printt("STAFF", stuff_ranked)
	
	# rangiraj po razdalji
	# ...
	if stuff_ranked:
		return stuff_ranked[0]
	else:
		return null
	
	
func sort_stuff_by_ai_rank(stuff_1, stuff_2): # ascending ... večji index je boljši
	
	if stuff_1.ai_target_rank > stuff_1.ai_target_rank:
	    return true
	return false
	
	
# SIGNALI ------------------------------------------------------------------------------------------------


func _on_NavigationAgent2D_path_changed() -> void:
	
#	emit_signal("path_changed", navigation_agent.get_nav_path()) # levelu preko arene pošljemo točke poti do cilja	
	pass


func _on_NavigationAgent2D_navigation_finished() -> void:
#	print("_on_NavigationAgent2D_navigation_finished")
	pass
	
	
func _on_NavigationAgent2D_target_reached() -> void:
#	print("_on_NavigationAgent2D_target_reached")
	pass
