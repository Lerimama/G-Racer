extends KinematicBody2D

enum AiStates {IDLE, RACE, SEEK, FOLLOW, HUNT}
enum AiAttackingMode {NONE, BULLET, MISILE, MINA, TIME_BOMB, MALE}

var current_ai_state: int = AiStates.IDLE
var current_attacking_mode: int = AiAttackingMode.NONE

onready var navigation_agent = $NavigationAgent2D
onready var detect_ray = $DetectRay
onready var vision_ray = $VisionRay
onready var target_ray: RayCast2D = $TargetRay
onready var detect_area: Area2D = $DetectArea

var ai_target: Node2D = null
var level_navigation_positions: Array # poda GM ob spawnu
var ai_navigation_line: Line2D # debug

onready var max_engine_power = Pro.ai_profile["max_engine_power"] # 80
onready var searching_engine_power = max_engine_power * 0.8 

# neu
# ai settings .. v Profile
var ai_brake_distance_factor: float = 0.5 # delež dolžine vektorja hitrosti ... vision ray je na tej dolžini
var ai_brake_factor: float = 0.8 # množenje s hitrostjo
var ai_closeup_distance: float = 70
var ai_urgent_stop_distance: float = 20
var ai_target_min_distance: float = 70
var ai_target_max_distance: float = 120
onready var edge_navigation_tilemap: TileMap = Ref.current_level.tilemap_edge
var valid_target_group: String = "valid_target_group"	
var last_follow_target_position: Vector2
var target_ray_angle_limit: float = 30
var target_ray_seek_length: float = 320
var target_ray_rotation_speed: float = 1

onready var freee: bool = true


func _ready() -> void:
	
	add_to_group(Ref.group_ai)
	#	bolt_hud.hide()
	
	# debug ... spawn navigation line
	ai_navigation_line = Line2D.new()
	Ref.node_creation_parent.add_child(ai_navigation_line)
	ai_navigation_line.width = 2
	ai_navigation_line.default_color = bolt_color
	ai_navigation_line.z_index = 10
#	ai_navigation_line.hide()
	randomize()
	

func _physics_process(delta: float) -> void:


	
	if not bolt_active:
		return

	manage_ai_states(delta)
	
	if current_motion_state == MotionStates.DISARRAY:
		# inherited ----------------------------
		rotation_angle = rotation_dir * deg2rad(turn_angle)
		# ----------------------------
		ai_target = null
	else:
		if ai_target == null and not current_ai_state == AiStates.IDLE: # setanje tarče za konec dissaraya
			set_ai_target(edge_navigation_tilemap)
		# inherited ----------------------------
		var min_drag: float = 0.5 # testirano, da je ne odnese
		var max_power_drag_loss: float = 0.0023 # da ni prehitro
		# max power reached ... drag se konstanto niža, da hitrost raste v neskončnost
		if current_motion_state == MotionStates.FWD:
			if drag_div == Pro.bolt_profiles[bolt_type]["drag_div"]:
				current_drag -= max_power_drag_loss
				current_drag = clamp(current_drag, min_drag, current_drag)
			else:
				current_drag = bolt_drag
		else:
			current_drag = bolt_drag
		# sila upora raste s hitrostjo		
		var drag_force = current_drag * velocity * velocity.length() / drag_div # množenje z velocity nam da obliko vektorja
		# hitrost je pospešek s časom
		velocity += acceleration * delta
		rotation_angle = rotation_dir * deg2rad(turn_angle)
		rotate(delta * rotation_angle)
		# ----------------------------
		var next_position: Vector2 = navigation_agent.get_next_location()
		acceleration = position.direction_to(next_position) * engine_power
		steering(delta) # more bi pred rotacijo, da se upošteva ... ne vem če kaj vpliva
		rotation = velocity.angle()
		# vision
		vision_ray.cast_to.x = velocity.length() * ai_brake_distance_factor # zmeraj dolg kot je dolga hitrost
		if vision_ray.is_colliding():
			velocity *= ai_brake_factor
	
	# inherited ----------------------------
	collision = move_and_collide(velocity * delta, false)
	if collision:
		on_collision()	
	
	manage_motion_states(delta)
#	manage_motion_fx()
	
	
	
func manage_ai_states(delta: float):
	
	# če node tarče še obstaja, ga pošlje v SEEK mode
	if not get_tree().get_nodes_in_group(valid_target_group).has(ai_target): # preverjam s strani grupe
		set_ai_target(edge_navigation_tilemap)	
		return
			
	match current_ai_state:
		
		AiStates.IDLE: 
			# miruje s prižganim motorjem
			# target = null	
			engine_power = 0
		
		AiStates.RACE: 
			# šiba po najbližji poti do tarče
			# target = position tracker
			navigation_agent.set_target_location(get_racing_position(ai_target))
			engine_power = max_engine_power	
		
		AiStates.SEEK: 
			# išče novo tarčo, dokler je ne najde
			# target = edge_navigation_tilemap
			var possible_targets: Array = get_possible_targets()
			if not possible_targets.empty():
				if "ai_target_rank" in ai_target:
					var best_target_rank: int = possible_targets[0].ai_target_rank 
					if best_target_rank > ai_target.ai_target_rank:
						set_ai_target(possible_targets[0]) # postane HUNT
				else:
					set_ai_target(possible_targets[0]) # postane HUNT
			engine_power = max_engine_power
	
		AiStates.FOLLOW: 
			# sledi tarči, dokler se ji ne približa ... če je ne vidi ima problem
			# target = bolt
			# apdejt pozicije tarče, če se premika
			if not navigation_agent.get_target_location() == ai_target.global_position: 
				navigation_agent.set_target_location(ai_target.global_position)
				# sharanjujem zadnjo pozicijo, da lažje sledim
				last_follow_target_position = ai_target.global_position
			# regulacija hitrosti
			target_ray.look_at(ai_target.global_position)
			var ray_velocity_length: float = global_position.distance_to(ai_target.global_position)
			target_ray.cast_to.x = ray_velocity_length
			if ray_velocity_length < ai_urgent_stop_distance:
				velocity *= ai_brake_factor
				engine_power = 0.1 # če je čista 0 se noče vrtet 
			elif ray_velocity_length < ai_closeup_distance:
				var brake_factor: float = 0.95
				velocity *= ai_brake_factor
				engine_power = max_engine_power
			else:
				engine_power = max_engine_power	
			# loose target on vision breaker, gre v SEEK mode
			if (target_ray.is_colliding() and target_ray.get_collider() == edge_navigation_tilemap) or ai_target == null:
				set_ai_target(edge_navigation_tilemap)
		
		AiStates.HUNT: 
			# pobere tarčo, ki jo je videl ... ne izgubi pogleda
			# tarča = level object
			# apdejt pozicije tarče, če se premika
			if not navigation_agent.get_target_location() == ai_target.global_position: 
				navigation_agent.set_target_location(ai_target.global_position)			
			# regulacija hitrosti
			target_ray.look_at(ai_target.global_position)
			var ray_velocity_length: float = global_position.distance_to(ai_target.global_position)
			target_ray.cast_to.x = ray_velocity_length
			if ray_velocity_length < ai_urgent_stop_distance:
				var brake_factor: float = 0.95
				velocity *= ai_brake_factor			
			engine_power = max_engine_power
			# gleda za boljšo tarčo
			#			var possible_targets: Array = get_possible_targets()
			#			if not possible_targets.empty():
			#				if possible_targets[0].ai_target_rank > ai_target.ai_target_rank:
			#					set_ai_target(possible_targets[0]) # postane HUNT ali follow		
			if ai_target == null:
				set_ai_target(edge_navigation_tilemap)
	
	# printt("Current state: %s" % AiStates.keys()[current_ai_state], ai_target)
	
	# če tarča ni več d
	if ai_target and not navigation_agent.is_target_reachable(): # sanira tudi bug, ker je lahko izbran kakšen za steno
		set_ai_target(edge_navigation_tilemap)	
	
		
func set_ai_target(new_ai_target: Node2D):
	
	detect_ray.enabled = false
	target_ray.enabled = false
	
	# reset "valid target" grupe
	if get_tree().get_nodes_in_group(valid_target_group).has(ai_target): # preverjam s strani grupe in ne tarče, ki je lahko že ne obstaja več
		ai_target.remove_from_group(valid_target_group)
	
	if new_ai_target is Bolt or new_ai_target is TheBolt: # debug
		# printt("start FOLLOW from %s" % AiStates.keys()[current_ai_state], "new_target: %s" % new_ai_target)
		target_ray.enabled = true
		current_ai_state = AiStates.FOLLOW
	
	elif new_ai_target is Pickable:		
		# printt("start HUNT from %s" % AiStates.keys()[current_ai_state], "new_target: %s" % new_ai_target)
		target_ray.enabled = true
		navigation_agent.set_target_location(new_ai_target.global_position)
		current_ai_state = AiStates.HUNT
	
	elif new_ai_target is PathFollow2D:
		# printt("start RACE from %s" % AiStates.keys()[current_ai_state], "new_target: %s" % new_ai_target)
		current_ai_state = AiStates.RACE	
	
	elif new_ai_target == edge_navigation_tilemap:
		# printt("start SEEK from %s" % AiStates.keys()[current_ai_state], "new_target: %s" % new_ai_target)
		detect_ray.enabled = true
		target_ray.enabled = true
		var target_navigation_cell_position: Vector2 = Vector2.ZERO
		# če je bil FOLLOW je nova tarča na zadnji vidni lokaciji stare tarče, drugače je random nav cell
		if freee:
			target_navigation_cell_position = get_nav_cell_on_distance(global_position,150, 1000)
			navigation_agent.set_target_location(target_navigation_cell_position)
		else:
			if current_ai_state == AiStates.FOLLOW:
				target_navigation_cell_position = get_nav_cell_on_distance(last_follow_target_position)
			else:
				target_navigation_cell_position = get_nav_cell_on_distance(global_position, ai_target_min_distance, ai_target_max_distance)
			navigation_agent.set_target_location(target_navigation_cell_position)
		current_ai_state = AiStates.SEEK
	
	elif new_ai_target == null:
		
		printt("start IDLE from %s" % AiStates.keys()[current_ai_state], "new_target: %s" % new_ai_target)
		current_ai_state = AiStates.IDLE
	
	# apliciram target in ga dam v "valid target" grupo
	ai_target = new_ai_target	
	if ai_target:
		ai_target.add_to_group(valid_target_group)
	

# PER STATE ----------------------------------------------------------------------------------------------


func get_possible_targets():
	
	# detect area nabira
	var all_possible_targets: Array = detect_area.get_overlapping_bodies()
	all_possible_targets.append_array(detect_area.get_overlapping_areas())
	
	# izločim sebe in rank = 0
	all_possible_targets.erase(self)
	for target in all_possible_targets:
		if target.ai_target_rank == 0:
			all_possible_targets.erase(target)
	
	# target ray rotira in nabira
	target_ray.cast_to.x = target_ray_seek_length
	target_ray.rotation_degrees += target_ray_rotation_speed
	if target_ray.rotation_degrees > target_ray_angle_limit:
		target_ray.rotation_degrees = -target_ray_angle_limit	
	if target_ray.is_colliding() and not target_ray.get_collider() == edge_navigation_tilemap:
		all_possible_targets.append(target_ray.get_collider())
	
	# če ni tarče 
	if all_possible_targets.empty():
		return all_possible_targets
	
	# rangiram po ranku
	all_possible_targets.sort_custom(self, "sort_objects_by_ai_rank")
	# rangiram po potrebi
	#	if player_stats["bullet_count"] == 0 and player_stats["misile_count"] == 0:
	#		for target in all_possible_targets:
	#			if "pickable_key" in target:
	#				if target.pickable_key == Pro.Weapons.BULLET or target.pickable_key == Pro.Weapons.MISILE:
	#					all_possible_targets.push_front(target)
	# rangiram po distanci
	
	# detect ray preveri, če so tarče za steno
	var targets_behind_wall: Array = []
	for possible_target in all_possible_targets:
		detect_ray.force_raycast_update()
		detect_ray.look_at(possible_target.global_position)
		var detect_ray_length: float = global_position.distance_to(possible_target.global_position)
		detect_ray.cast_to.x = detect_ray_length
		if detect_ray.is_colliding() and detect_ray.get_collider() == edge_navigation_tilemap:
			targets_behind_wall.append(possible_target)
			# printt("walled", Pro.Pickables.keys()[possible_target.pickable_key])
	for target_behind_wall in targets_behind_wall:
		all_possible_targets.erase(target_behind_wall)
	
	# if not all_possible_targets.empty():
	#	printt("all targets %s" % all_possible_targets.size(), "walled targets %s" % targets_behind_wall.size(), "selected target %s" % Pro.Pickables.keys()[all_possible_targets[0].pickable_key])
	
	return all_possible_targets


func sort_objects_by_ai_rank(stuff_1, stuff_2): # ascending ... večji index je boljši
	
	if stuff_1.ai_target_rank > stuff_1.ai_target_rank:
	    return true
	return false

	
func get_nav_cell_on_distance(from_position: Vector2, min_distance: float = 0, max_distance: float = 50, in_front: bool = true):
	
#	var selected_nav_position: Vector2
#	if freee:
#		var all_cells_for_random_selection: Array = []
#		pass
#
#	else:
		var selected_nav_position: Vector2
		var all_cells_for_random_selection: Array = []
		var front_cells_for_random_selection: Array = []
		var side_cells_for_random_selection: Array = []
		
		# random select, če ne iščem do 0
		var random_select: bool = true
		if min_distance == 0:
			in_front = false
			random_select = false
			
		var current_min_cell_distance: float = 0
		var current_min_cell_angle: float = 0
		
		# debug
		if not Met.all_indikators_spawned.empty():
			for n in Met.all_indikators_spawned:
				n.queue_free()
			Met.all_indikators_spawned.clear()
		
		for nav_position in level_navigation_positions:
			var current_cell_distance: float = nav_position.distance_to(from_position)
			# najprej izbere vse po razponu
			if current_cell_distance > min_distance and current_cell_distance < max_distance:
				if in_front:
					var vector_to_position: Vector2 = nav_position - global_position
					var current_angle_to_bolt_deg: float = rad2deg(get_angle_to(nav_position))
					# če je najbolj spredaj
					#				var indi = Met.spawn_indikator(nav_position, global_rotation, Ref.node_creation_parent, false)
					if current_angle_to_bolt_deg < 30  and current_angle_to_bolt_deg > - 30 :
						front_cells_for_random_selection.append(nav_position)
					# če je na straneh
					elif current_angle_to_bolt_deg < 90  and current_angle_to_bolt_deg > -90 :
						side_cells_for_random_selection.append(nav_position)
					#					indi.modulate = Color.black
					# če ni v razponu kota
					else:
						all_cells_for_random_selection.append(nav_position)
					#					indi.modulate = Color.green
				else:
					# random select, samo nabiram za žrebanje, 
					if random_select:
						all_cells_for_random_selection.append(nav_position)
					# izberem najbližjo
					else:
						if current_cell_distance < current_min_cell_distance or current_min_cell_distance == 0:
							current_min_cell_distance = current_cell_distance
							selected_nav_position = nav_position
		
		# žrebam iz sprednjih ali vseh na voljo
		if front_cells_for_random_selection.empty() and side_cells_for_random_selection.empty():
			in_front = false
		if in_front:
			if front_cells_for_random_selection.empty():
				selected_nav_position = Met.get_random_member(side_cells_for_random_selection)
			else:
				selected_nav_position = Met.get_random_member(front_cells_for_random_selection)
		elif random_select:
			selected_nav_position = Met.get_random_member(all_cells_for_random_selection)
			
		return selected_nav_position

	
func get_navigation_position_on_distance(from_position: Vector2, min_distance: float = 0, max_distance: float = 50, in_front: bool = true):
	
	var selected_nav_position: Vector2
	var all_cells_for_random_selection: Array = []
	var front_cells_for_random_selection: Array = []
	var side_cells_for_random_selection: Array = []
	
	# random select, če ne iščem do 0
	var random_select: bool = true
	if min_distance == 0:
		in_front = false
		random_select = false
		
	var current_min_cell_distance: float = 0
	var current_min_cell_angle: float = 0
	
	# debug
	if not Met.all_indikators_spawned.empty():
		for n in Met.all_indikators_spawned:
			n.queue_free()
		Met.all_indikators_spawned.clear()
	
	for nav_position in level_navigation_positions:
		var current_cell_distance: float = nav_position.distance_to(from_position)
		# najprej izbere vse po razponu
		if current_cell_distance > min_distance and current_cell_distance < max_distance:
			if in_front:
				var vector_to_position: Vector2 = nav_position - global_position
				var current_angle_to_bolt_deg: float = rad2deg(get_angle_to(nav_position))
				# če je najbolj spredaj
				#				var indi = Met.spawn_indikator(nav_position, global_rotation, Ref.node_creation_parent, false)
				if current_angle_to_bolt_deg < 30  and current_angle_to_bolt_deg > - 30 :
					front_cells_for_random_selection.append(nav_position)
				# če je na straneh
				elif current_angle_to_bolt_deg < 90  and current_angle_to_bolt_deg > -90 :
					side_cells_for_random_selection.append(nav_position)
				#					indi.modulate = Color.black
				# če ni v razponu kota
				else:
					all_cells_for_random_selection.append(nav_position)
				#					indi.modulate = Color.green
			else:
				# random select, samo nabiram za žrebanje, 
				if random_select:
					all_cells_for_random_selection.append(nav_position)
				# izberem najbližjo
				else:
					if current_cell_distance < current_min_cell_distance or current_min_cell_distance == 0:
						current_min_cell_distance = current_cell_distance
						selected_nav_position = nav_position
	
	# žrebam iz sprednjih ali vseh na voljo
	if front_cells_for_random_selection.empty() and side_cells_for_random_selection.empty():
		in_front = false
	if in_front:
		if front_cells_for_random_selection.empty():
			selected_nav_position = Met.get_random_member(side_cells_for_random_selection)
		else:
			selected_nav_position = Met.get_random_member(front_cells_for_random_selection)
	elif random_select:
		selected_nav_position = Met.get_random_member(all_cells_for_random_selection)
		
	return selected_nav_position


func get_racing_position(position_tracker: PathFollow2D):
	
	var ai_target_point_on_curve: Vector2
	var ai_target_prediction: float = 50
	var ai_target_total_offset: float = position_tracker.offset + ai_target_prediction
	var bolt_tracker_curve: Curve2D = position_tracker.get_parent().get_curve()
	ai_target_point_on_curve = bolt_tracker_curve.interpolate_baked(ai_target_total_offset)
	
	return ai_target_point_on_curve
		

# SIGNALI ------------------------------------------------------------------------------------------------


func _on_NavigationAgent2D_path_changed() -> void: # debug
	
	ai_navigation_line.clear_points()
	for point in navigation_agent.get_nav_path():
		ai_navigation_line.add_point(point)


func _on_NavigationAgent2D_navigation_finished() -> void:
	
	print("nav reached")
	
	if current_ai_state == AiStates.SEEK:
#		if freee:
#			set_ai_target(edge_navigation_tilemap)	
#		else:
			set_ai_target(edge_navigation_tilemap)	
	
	
func _on_NavigationAgent2D_target_reached() -> void:
	
	print("target reached")
	#	if current_ai_state == AiStates.HUNT:
	#		set_ai_target(edge_navigation_tilemap)	
	pass



# INHERITED -------------------------------------------------------------------------------------------------------------------------------------------------


signal stats_changed (stats_owner_id, player_stats) # bolt in damage

enum MotionStates {IDLE, FWD, REV, DISARRAY} # DIZZY, DYING glede na moč motorja
var current_motion_state: int = MotionStates.IDLE

var bolt_active: bool = false setget _on_bolt_active_changed # predvsem za pošiljanje signala GMju
var bolt_id: int # ga seta spawner

var player_name: String # za opredelitev statistike
var bolt_color: Color = Color.red
var acceleration: Vector2
var velocity: Vector2 = Vector2.ZERO
var collision: KinematicCollision2D
var axis_distance: float # določen glede na širino sprajta
var rotation_angle: float
var rotation_dir: float

var stop_speed: float = 15 # hitrost pri kateri ga kar ustavim
var revive_time: float = 2
var current_drag: float # = bolt_drag
var race_time_on_previous_lap: float = 0
var bolt_position_tracker: PathFollow2D # napolni se, ko se bolt pripiše trackerju  

# weapons
var bullet_reloaded: bool = true
var misile_reloaded: bool = true
var mina_reloaded: bool = true
var mina_released: bool # če je že odvržen v trenutni ožini
var shields_on = false
var shield_loops_counter: int = 0
var shield_loops_limit: int = 1 # poberem jo iz profilov, ali pa kot veleva pickable

# bolt shadow
var bolt_altitude: float = 3
var bolt_max_altitude: float = 5
var shadow_direction: Vector2 = Vector2(1,0).rotated(deg2rad(-90)) # 0 levo, 180 desno, 90 gor, -90 dol  

# trail
var bolt_trail_active: bool = false # aktivna je ravno spawnana, neaktiva je "odklopljena"
var bolt_trail_alpha = 0.05
var trail_pseudodecay_color = Color.white
var current_active_trail: Line2D

# engine
var engines_on: bool = false
var engine_power = 0 # ob štartu je noga z gasa
var max_power_reached: bool = false
var engine_particles_rear: CPUParticles2D
var engine_particles_front_left: CPUParticles2D
var engine_particles_front_right: CPUParticles2D

onready var bolt_hud: Node2D = $BoltHud
onready var dissaray_tween: SceneTreeTween # za ustavljanje na lose life
onready var bolt_sprite: Sprite = $Bolt
onready var bolt_collision: CollisionPolygon2D = $BoltCollision # zaradi shielda ga moram imet
onready var shield: Sprite = $Shield
onready var shield_collision: CollisionShape2D = $ShieldCollision
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var sounds: Node = $Sounds
onready var bolt_shadow: Sprite = $BoltShadow
onready var rear_engine_position: Position2D = $Bolt/RearEnginePosition
onready var front_engine_position_L: Position2D = $Bolt/FrontEnginePositionL
onready var front_engine_position_R: Position2D = $Bolt/FrontEnginePositionR
onready var trail_position: Position2D = $Bolt/TrailPosition
onready var gun_position: Position2D = $Bolt/GunPosition

onready var CollisionParticles: PackedScene = preload("res://game/bolt/BoltCollisionParticles.tscn")
onready var EngineParticlesRear: PackedScene = preload("res://game/bolt/EngineParticlesRear.tscn") 
onready var EngineParticlesFront: PackedScene = preload("res://game/bolt/EngineParticlesFront.tscn") 
onready var ExplodingBolt: PackedScene = preload("res://game/bolt/ExplodingBolt.tscn")
onready var BoltTrail: PackedScene = preload("res://game/bolt/BoltTrail.tscn")
onready var BulletScene: PackedScene = preload("res://game/weapons/Bullet.tscn")
onready var MisileScene: PackedScene = preload("res://game/weapons/Misile.tscn")
onready var MinaScene: PackedScene = preload("res://game/weapons/Mina.tscn")

# bolt stats
onready var player_stats: Dictionary = Pro.default_player_stats.duplicate()
onready var max_energy: float = player_stats["energy"] # zato, da se lahko resetira

# player profil
onready var player_profile: Dictionary = Pro.player_profiles[bolt_id].duplicate()
onready var bolt_type: int = player_profile["bolt_type"]

# bolt type profil
onready var bolt_profile: Dictionary = Pro.bolt_profiles[bolt_type].duplicate()
onready var ai_target_rank: int = bolt_profile["ai_target_rank"]
onready var bolt_sprite_texture: Texture # = Pro.bolt_profiles[bolt_type]["bolt_texture"] 
onready var fwd_engine_power: int = bolt_profile["fwd_engine_power"]
onready var rev_engine_power: int = bolt_profile["rev_engine_power"]
onready var turn_angle: int = bolt_profile["turn_angle"] # deg per frame
onready var free_rotation_multiplier: int = bolt_profile["free_rotation_multiplier"] # rotacija kadar miruje
onready var bolt_drag: float = bolt_profile["drag"] # raste kvadratno s hitrostjo
onready var side_traction: float = bolt_profile["side_traction"]
onready var bounce_size: float = bolt_profile["bounce_size"]
onready var mass: float = bolt_profile["mass"]
onready var reload_ability: float = bolt_profile["reload_ability"]  # reload def gre v weapons
onready var fwd_gas_usage: float = bolt_profile["fwd_gas_usage"] 
onready var rev_gas_usage: float = bolt_profile["rev_gas_usage"] 
onready var drag_div: float = bolt_profile["drag_div"] 


#func _ready() -> void:
#
#	add_to_group(Ref.group_bolts)	
#
#	player_name = player_profile["player_name"]
#
#	# bolt
#	if bolt_sprite_texture:
#		bolt_sprite.texture = bolt_sprite_texture
#	axis_distance = bolt_sprite.texture.get_width()
#	current_drag = bolt_drag
#	bolt_color = player_profile["player_color"] # bolt se obarva ... 	
#	bolt_sprite.modulate = bolt_color	
#	bolt_shadow.shadow_distance = bolt_max_altitude
#
#	set_engines() # postavi partikle za pogon
#
#	# nodes
#	shield.hide() 
#	shield.modulate.a = 0 
#	shield_collision.set_deferred("disabled", true)
#	shield.self_modulate = bolt_color 
#
#	# bolt wiggle šejder
#	bolt_sprite.material.set_shader_param("noise_factor", 0)


#func _physics_process(delta: float) -> void:
#
#	# aktivacija pospeška je setana na vozniku
#	# plejer ... acceleration = transform.x * engine_power # transform.x je (-1, 0)
#	# enemi ... acceleration = position.direction_to(navigation_agent.get_next_location()) * engine_power
#	# animiran bolt .. sprite se ne rotira z zavijanjem ... # bolt_sprite.rotation = - global_rotation
#
#	if current_motion_state == MotionStates.DISARRAY:
#		rotation_angle = rotation_dir * deg2rad(turn_angle)
#	else:
#		var min_drag: float = 0.5 # testirano, da je ne odnese
#		var max_power_drag_loss: float = 0.0023 # da ni prehitro
#		# max power reached ... drag se konstanto niža, da hitrost raste v neskončnost
#		if current_motion_state == MotionStates.FWD:
#			if drag_div == Pro.bolt_profiles[bolt_type]["drag_div"]:
#				current_drag -= max_power_drag_loss
#				current_drag = clamp(current_drag, min_drag, current_drag)
#			else:
#				current_drag = bolt_drag
#		else:
#			current_drag = bolt_drag
#		# printt ("max power", engine_power, current_drag, bolt_drag, velocity.length())
#		# sila upora raste s hitrostjo		
#		var drag_force = current_drag * velocity * velocity.length() / drag_div # množenje z velocity nam da obliko vektorja
#		acceleration -= drag_force
#		# hitrost je pospešek s časom
#		velocity += acceleration * delta
#		rotation_angle = rotation_dir * deg2rad(turn_angle)
#		rotate(delta * rotation_angle)
#		steering(delta)
#
#	collision = move_and_collide(velocity * delta, false)
#	if collision:
#		on_collision()	
#
#	manage_motion_states(delta)
#	manage_motion_fx()
	
			
func _exit_tree() -> void:
	for sound in sounds.get_children():
		sound.stop()
	if engine_particles_rear:
		engine_particles_rear.queue_free()
	if engine_particles_front_left:
		engine_particles_front_left.queue_free()
	if engine_particles_front_right:
		engine_particles_front_right.queue_free()
#	current_active_trail.start_decay() # trail decay tween start
	bolt_trail_active = false
	if Ref.current_camera.follow_target == self:
		Ref.current_camera.follow_target = null
		
	
# IZ PROCESA ----------------------------------------------------------------------------

	
func on_collision():
	
	if not $Sounds/HitWall2.is_playing():
		$Sounds/HitWall.play()
		$Sounds/HitWall2.play()
	
	velocity = velocity.bounce(collision.normal) * bounce_size # gibanje pomnožimo z bounce vektorjem normale od objekta kolizije
	# odbojni partikli
	if velocity.length() > stop_speed: # ta omenitev je zato, da ne prši, ko si fiksiran v steno
		var new_collision_particles = CollisionParticles.instance()
		new_collision_particles.position = collision.position
		new_collision_particles.rotation = collision.normal.angle() # rotacija partiklov glede na normalo površine 
		new_collision_particles.amount = (velocity.length() + 15)/15 # količnik je korektor ... 15 dodam zato da amount ni nikoli nič	
		new_collision_particles.color = bolt_color
		new_collision_particles.set_emitting(true)
		Ref.node_creation_parent.add_child(new_collision_particles)
	
	if bolt_trail_active:
		current_active_trail.start_decay() # trail decay tween start
		bolt_trail_active = false


func steering(delta: float) -> void:
	
	
	var rear_axis_position = position - transform.x * axis_distance / 2.0 # sredinska pozicija vozila minus polovica medosne razdalje
	var front_axis_position = position + transform.x * axis_distance / 2.0 # sredinska pozicija vozila plus polovica medosne razdalje
	
	# sprememba lokacije osi ob gibanju (per frame)
	rear_axis_position += velocity * delta	
	front_axis_position += velocity.rotated(rotation_angle) * delta
	
	var new_heading = (front_axis_position - rear_axis_position).normalized()
	
	velocity = velocity.linear_interpolate(new_heading * velocity.length(), side_traction / 10) # željeno smer gibanja doseže z zamikom "side-traction" ... 10 je za adaptacijo inputa	
	# if current_motion_state == MotionStates.FWD:
	# if fwd_motion:
	#	velocity = velocity.linear_interpolate(new_heading * velocity.length(), side_traction / 10) # željeno smer gibanja doseže z zamikom "side-traction"	
	# elif current_motion_state == MotionStates.REV:
	# elif rev_motion:
	#	velocity = velocity.linear_interpolate(-new_heading * min(velocity.length(), max_speed_reverse), 0.5) # željeno smer gibanja doseže z zamikom "side-traction"	
	
	rotation = new_heading.angle() # sprite se obrne v smeri	

	
func manage_motion_states(delta):
	
	# če je dissaray ne more bit nič drugega, če ga nekdo ne izklopi (timer)
	if current_motion_state == MotionStates.DISARRAY:
		rotate(delta * rotation_angle * free_rotation_multiplier)
		return
		
	if engine_power > 0:
		current_motion_state = MotionStates.FWD
	elif engine_power < 0:
		current_motion_state = MotionStates.REV
	else:
		current_motion_state = MotionStates.IDLE	
	

func manage_motion_fx():

	shield.rotation = -rotation # negiramo rotacijo bolta, da je pri miru
	engine_particles_rear.global_position = rear_engine_position.global_position
	engine_particles_rear.global_rotation = rear_engine_position.global_rotation
	engine_particles_front_left.global_position = front_engine_position_L.global_position
	engine_particles_front_left.global_rotation = front_engine_position_L.global_rotation - deg2rad(180)
	engine_particles_front_right.global_position = front_engine_position_R.global_position
	engine_particles_front_right.global_rotation = front_engine_position_R.global_rotation - deg2rad(180)
	
	var engine_pitch_tween = get_tree().create_tween()
	if current_motion_state == MotionStates.FWD:
		engine_pitch_tween.kill() # more bit
		$Sounds/Engine.pitch_scale = 1 + velocity.length()/180
		engine_particles_rear.set_emitting(true)
	elif current_motion_state == MotionStates.REV:
		engine_pitch_tween.kill() # more bit
		$Sounds/Engine.pitch_scale = 1 + velocity.length()/180
		engine_particles_front_left.set_emitting(true)
		engine_particles_front_right.set_emitting(true)
	elif current_motion_state == MotionStates.IDLE:
		if $Sounds/Engine.pitch_scale > 1:
			engine_pitch_tween.tween_property($Sounds/Engine, "pitch_scale", 1, 0.2)
		else:
			engine_pitch_tween.kill()
			$Sounds/Engine.pitch_scale = 1
		
	# spawn trail if not active
	if not bolt_trail_active and velocity.length() > 0: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
		current_active_trail = spawn_new_trail()
	
	# manage trail
	if bolt_trail_active:
		manage_trail()

	
func manage_trail():
	# start hiding trail + add trail points ... ob ponovnem premiku se ista spet pokaže
	
	if velocity.length() > 0:
		
		current_active_trail.add_points(global_position)
		current_active_trail.gradient.colors[1] = trail_pseudodecay_color
		
		if velocity.length() > stop_speed and current_active_trail.modulate.a < bolt_trail_alpha:
			# če se premikam in se je tril že začel skrivat ga prikažem
			var trail_grad = get_tree().create_tween()
			trail_grad.tween_property(current_active_trail, "modulate:a", bolt_trail_alpha, 0.5)
		else:
			# če grem počasi ga skrijem
			var trail_grad = get_tree().create_tween()
			trail_grad.tween_property(current_active_trail, "modulate:a", 0, 0.5)
	# če sem pri mirua deaktiviram trail ... ob ponovnem premiku se kreira nova 
	else:
		current_active_trail.start_decay() # trail decay tween start
		bolt_trail_active = false # postane neaktivna, a je še vedno prisotna ... queue_free je šele na koncu decay tweena


func manage_gas(gas_usage: float):
	
	if not bolt_active: 
		return
		
	update_stat("gas_count", gas_usage)
	
	if player_stats["gas_count"] <= 0: # če zmanjka bencina je deaktiviran
		player_stats["gas_count"] = 0
		self.bolt_active = false


# LIFE LOOP ----------------------------------------------------------------------------


func on_hit(hit_by: Node):
	
	if shields_on:
		return

	if Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
		update_stat("energy", - hit_by.hit_damage)
				
	if hit_by.is_in_group(Ref.group_bullets):
		Ref.current_camera.shake_camera(Ref.current_camera.bullet_hit_shake)
		if velocity == Vector2.ZERO:
			velocity = hit_by.velocity / mass
		else:
			velocity += hit_by.velocity * hit_by.mass / mass
		in_disarray(hit_by.hit_damage)
		
	elif hit_by.is_in_group(Ref.group_misiles):
		
		Ref.sound_manager.play_sfx("bolt_explode")
		Ref.current_camera.shake_camera(Ref.current_camera.misile_hit_shake)
		if velocity == Vector2.ZERO:
			velocity = hit_by.velocity
		else:
			velocity += hit_by.velocity * hit_by.mass / mass
		if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE: 
			explode() # race ima vsak zadetek misile eksplozijo, drugače je samo na izgubi lajfa
		in_disarray(hit_by.hit_damage)
		
	elif hit_by.is_in_group(Ref.group_mine):
		Ref.current_camera.shake_camera(Ref.current_camera.misile_hit_shake)
		in_disarray(hit_by.hit_damage)
		
	# energy management	
	if player_stats["energy"] <= 0:
		lose_life()


func in_disarray(damage_amount: float): # 5 raketa, 1 metk
	
	current_motion_state = MotionStates.DISARRAY
	set_process_input(false)		
	var dissaray_time_factor: float = 0.6 # uravnano, da naredi pol kroga na 1 damage
	var disarray_rotation_dir: float = damage_amount # vedno je -1, 0, ali +1, samo tukaj jo povečam, da dobim hitro rotacijo
	var on_hit_disabled_time: float = dissaray_time_factor * damage_amount
	# random disarray direction
	var dissaray_random_direction = randi() % 2
	if dissaray_random_direction == 0:
		rotation_dir = - disarray_rotation_dir
	else:
		rotation_dir = disarray_rotation_dir
	dissaray_tween = get_tree().create_tween()
	dissaray_tween.tween_property(self, "velocity", Vector2.ZERO, on_hit_disabled_time) # tajmiram pojemek 
	dissaray_tween.parallel().tween_property(self, "rotation_dir", 0, on_hit_disabled_time)#.set_ease(Tween.EASE_IN) # tajmiram pojemek 
	yield(dissaray_tween, "finished")
	set_process_input(true)		
	current_motion_state = MotionStates.IDLE

	
func explode():
	
	# efekti in posledice
	Ref.current_camera.shake_camera(Ref.current_camera.bolt_explosion_shake)
	if bolt_trail_active: # ugasni tejl
		current_active_trail.start_decay() # trail decay tween start
		bolt_trail_active = false
	# engine_particles_rear.visible = false
	# engine_particles_front_left.visible = false
	# engine_particles_front_right.visible = false
	# spawn eksplozije
	var new_exploding_bolt = ExplodingBolt.instance()
	new_exploding_bolt.global_position = global_position
	new_exploding_bolt.global_rotation = bolt_sprite.global_rotation
	new_exploding_bolt.modulate.a = 1
	new_exploding_bolt.velocity = velocity # podamo hitrost, da se premika s hitrostjo bolta
	new_exploding_bolt.spawned_by_color = bolt_color
	new_exploding_bolt.z_index = z_index + Set.explosion_z_index
	Ref.node_creation_parent.add_child(new_exploding_bolt)	


func lose_life():
	
	stop_engines()
	explode()
	bolt_collision.disabled = true
	visible = false
	set_process_input(false)		
	set_physics_process(false)
	
	update_stat("life", - 1)
	
	if player_stats["life"] > 0:
		revive_bolt()
	else:
		self.bolt_active = false
		queue_free()
	

func revive_bolt():
	
	print("revieve")
	yield(get_tree().create_timer(revive_time), "timeout")
	# on new life
	bolt_collision.disabled = false
	# reset pred prikazom
	current_motion_state = MotionStates.IDLE
	if dissaray_tween:
		dissaray_tween.kill()
	velocity = Vector2.ZERO
	rotation_dir = 0
	engine_power = 0
	set_process_input(true)		
	set_physics_process(true)
	visible = true
	self.bolt_active = true
	
	var difference_to_max_energy: float = max_energy - player_stats["energy"]
	update_stat("energy", difference_to_max_energy)


# UTILITY ----------------------------------------------------------------------------


func drive_in(drive_in_time: float):
	
	# da ugotovim, kdaj so vsi zapeljani# bolt.bolt_collision.set_disabled(true) # da ga ne moti morebitna stena
	var drive_in_finished_position: Vector2 = global_position
	var drive_in_distance: float = 50
	global_position -= drive_in_distance * transform.x
	
	modulate.a = 1
	current_motion_state = MotionStates.FWD # za fx
	start_engines()
	
	var intro_drive_tween = get_tree().create_tween()
	intro_drive_tween.tween_property(self, "global_position", drive_in_finished_position, drive_in_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	
func drive_out():
	
	var drive_out_rotation = Ref.current_level.race_start_node.get_rotation_degrees() - 90
	var drive_out_vector: Vector2 = Ref.current_level.race_start_node.global_position - Ref.current_level.finish_out_position
	var drive_out_position: Vector2 = global_position - drive_out_vector

	var drive_out_time: float = 2
	var drive_out_tween = get_tree().create_tween()
	drive_out_tween.tween_callback(bolt_collision, "set_disabled", [true])
	drive_out_tween.tween_property(self, "rotation_degrees", drive_out_rotation, drive_out_time/5)
	drive_out_tween.parallel().tween_property(self, "global_position", drive_out_position, drive_out_time).set_ease(Tween.EASE_IN)
	drive_out_tween.tween_property(self, "modulate:a", 0, drive_out_time) # če je krožna dirka in ne gre iz ekrana


func on_lap_finished(level_lap_limit: int):
	
	# lap time
	var current_race_time: float = Ref.hud.game_timer.game_time_hunds
	var current_lap_time: float = current_race_time - race_time_on_previous_lap # če je slednja 0, je prvi krog
	
	var best_lap_time: float = player_stats["best_lap_time"]
	
	if current_lap_time < best_lap_time or best_lap_time == 0:
		update_stat("best_lap_time", current_lap_time)
		Ref.hud.spawn_bolt_floating_tag(self, current_lap_time, true)
	else:
		Ref.hud.spawn_bolt_floating_tag(self, current_lap_time, false)

	update_stat("laps_count", 1)
	
	race_time_on_previous_lap = current_race_time # za naslednji krog
	
	if player_stats["laps_count"] >= level_lap_limit: # trenutno končan krog je že dodan
		Ref.game_manager.bolts_finished.append(self)
		update_stat("level_time", current_race_time)
		self.bolt_active = false # more bit za spremembo statistike
		drive_out()
	
	#	printt ("STAT", player_stats)


func spawn_new_trail():
	
	var new_bolt_trail: Object
	new_bolt_trail = BoltTrail.instance()
	new_bolt_trail.modulate.a = bolt_trail_alpha
	new_bolt_trail.z_index = z_index + Set.trail_z_index
	Ref.node_creation_parent.add_child(new_bolt_trail)
	
	bolt_trail_active = true	
	
	return new_bolt_trail
	
			
func set_engines():
	
	engine_particles_rear = EngineParticlesRear.instance()
	engine_particles_rear.global_position = rear_engine_position.global_position
	engine_particles_rear.z_index = z_index + Set.engine_z_index
	#	engine_particles_rear.modulate.a = 0
	Ref.node_creation_parent.add_child(engine_particles_rear)
	
	engine_particles_front_left = EngineParticlesFront.instance()
	engine_particles_front_left.global_position = front_engine_position_L.global_position
	#	engine_particles_front_left.modulate.a = 0
	engine_particles_front_left.z_index = z_index + Set.engine_z_index
	Ref.node_creation_parent.add_child(engine_particles_front_left)
	
	engine_particles_front_right = EngineParticlesFront.instance()
	engine_particles_front_right.global_position = front_engine_position_R.global_position
	#	engine_particles_front_right.modulate.a = 0
	engine_particles_front_right.z_index = z_index + Set.engine_z_index
	Ref.node_creation_parent.add_child(engine_particles_front_right)


func stop_engines():

	engines_on = false
	
	if $Sounds/Engine.is_playing():
		var current_engine_volume: float = $Sounds/Engine.get_volume_db()
		var engine_stop_tween = get_tree().create_tween()
		engine_stop_tween.tween_property($Sounds/Engine, "pitch_scale", 0.5, 2)
		engine_stop_tween.tween_property($Sounds/Engine, "volume_db", -80, 2)
		yield(engine_stop_tween, "finished")
		$Sounds/Engine.stop()
		$Sounds/Engine.volume_db = current_engine_volume
	$Sounds/EngineRevup.stop()
	$Sounds/EngineStart.stop()
	
	
func start_engines():
	
	engines_on = true
	$Sounds/EngineStart.play()
	
			
func shoot(weapon_index: int) -> void:
	
	match weapon_index:
		0: # "bullet":
			if bullet_reloaded:
				if player_stats["bullet_count"] <= 0:
					return
				var new_bullet = BulletScene.instance()
				new_bullet.global_position = gun_position.global_position
				new_bullet.global_rotation = bolt_sprite.global_rotation
				new_bullet.spawned_by = self # ime avtorja izstrelka
				new_bullet.spawned_by_color = bolt_color
				new_bullet.z_index = z_index + Set.weapons_z_index
				Ref.node_creation_parent.add_child(new_bullet)
				update_stat("bullet_count", - 1)
				bullet_reloaded = false
				yield(get_tree().create_timer(new_bullet.reload_time / reload_ability), "timeout")
				bullet_reloaded= true
		1: # "misile":
			if misile_reloaded and player_stats["misile_count"] > 0:			
				var new_misile = MisileScene.instance()
				new_misile.global_position = gun_position.global_position
				new_misile.global_rotation = bolt_sprite.global_rotation
				new_misile.spawned_by = self # zato, da lahko dobiva "točke ali kazni nadaljavo
				new_misile.spawned_by_color = bolt_color
				new_misile.spawned_by_speed = velocity.length()
				new_misile.z_index = z_index + Set.weapons_z_index
				Ref.node_creation_parent.add_child(new_misile)
				update_stat("misile_count", - 1)
				misile_reloaded = false
				yield(get_tree().create_timer(new_misile.reload_time / reload_ability), "timeout")
				misile_reloaded= true
		2: # "mina":
			if mina_reloaded and player_stats["mina_count"] > 0:			
				var new_mina = MinaScene.instance()
				new_mina.global_position = rear_engine_position.global_position
				new_mina.global_rotation = bolt_sprite.global_rotation
				new_mina.spawned_by = self # ime avtorja izstrelka
				new_mina.spawned_by_color = bolt_color
				new_mina.z_index = z_index + Set.weapons_z_index
				Ref.node_creation_parent.add_child(new_mina)
				update_stat("mina_count", - 1)
				mina_reloaded = false
				yield(get_tree().create_timer(new_mina.reload_time / reload_ability), "timeout")
				mina_reloaded = true

			
func activate_shield():
	
	if shields_on == false:
		#		shield.show()
		shield.modulate.a = 1
		animation_player.play("shield_on")
		shields_on = true
		bolt_collision.set_deferred("disabled", true)
		shield_collision.set_deferred("disabled", false)
	else:
		animation_player.play_backwards("shield_on")
		# shields_on in collisions_setup premaknjena dol na konec animacije
		shield_loops_counter = shield_loops_limit # imitiram zaključek loop tajmerja


func activate_nitro(nitro_power: float, nitro_time: float):

	if bolt_active: # če ni aktiven se sam od sebe ustavi
		#		fwd_engine_power = nitro_power # vhodni fwd_engine_power spremenim, ker se ne seta na vsak frame (reset na po timerju)
		#		# pospešek
		#		var nitro_tween = get_tree().create_tween()
		#		nitro_tween.tween_property(self, "engine_power", nitro_power, 1) # pospešek spreminja engine_power, na katereg input ne vpliva
		#		nitro_tween.tween_property(self, "nitro_active", true, 0)
		#		# trajanje
		#		yield(get_tree().create_timer(nitro_time), "timeout")
		#		fwd_engine_power = Pro.bolt_profiles[bolt_type]["fwd_engine_power"]
		var current_drag_div = drag_div
		drag_div = Pro.level_areas_profiles[Pro.LevelAreas.AREA_NITRO]["drag_div"]
		yield(get_tree().create_timer(nitro_time), "timeout")
		drag_div = current_drag_div
	
	
func on_item_picked(pickable_key: int):
	
	var pickable_value: float = Pro.pickable_profiles[pickable_key]["value"]
	
	match pickable_key:
		Pro.Pickables.PICKABLE_BULLET:
			if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
				player_stats["misile_count"] = 0
				player_stats["mina_count"] = 0
			update_stat("bullet_count", pickable_value)
		Pro.Pickables.PICKABLE_MISILE:
			if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
				player_stats["bullet_count"] = 0
				player_stats["mina_count"] = 0
			update_stat("misile_count", pickable_value)
		Pro.Pickables.PICKABLE_MINA:
			if not Ref.current_level.level_type == Ref.current_level.LevelTypes.BATTLE:
				player_stats["bullet_count"] = 0
				player_stats["misile_count"] = 0
			update_stat("mina_count", pickable_value)
		Pro.Pickables.PICKABLE_SHIELD:
			shield_loops_limit = pickable_value
			activate_shield()
		Pro.Pickables.PICKABLE_ENERGY:
			player_stats["energy"] = max_energy
		Pro.Pickables.PICKABLE_GAS:
			update_stat("gas_count", pickable_value)
		Pro.Pickables.PICKABLE_LIFE:
			update_stat("life", pickable_value)
		Pro.Pickables.PICKABLE_NITRO:
			activate_nitro(pickable_value, Pro.pickable_profiles[pickable_key]["duration"])
		Pro.Pickables.PICKABLE_TRACKING:
			var default_traction = side_traction
			side_traction = pickable_value
			yield(get_tree().create_timer(Pro.pickable_profiles[pickable_key]["duration"]), "timeout")
			side_traction = default_traction
		Pro.Pickables.PICKABLE_POINTS:
			update_bolt_points(pickable_value)
		Pro.Pickables.PICKABLE_RANDOM:
			var random_range: int = Pro.pickable_profiles.keys().size()
			var random_pickable_index = randi() % random_range
			var random_pickable_key = Pro.pickable_profiles.keys()[random_pickable_index]
			on_item_picked(random_pickable_key) # pick selected
		
			
# PRIVAT ------------------------------------------------------------------------------------------------


func _on_bolt_active_changed(bolt_is_active: bool):
	
	bolt_active = bolt_is_active
	# če je aktiven ga upočasnim v trenutni smeri
	var deactivate_time: float = 1.5
	if bolt_active == false:
		rotation_dir = 0
		var deactivate_tween = get_tree().create_tween()
		deactivate_tween.tween_property(self, "velocity", Vector2.ZERO, deactivate_time) # tajmiram pojemek 
		deactivate_tween.parallel().tween_property(self, "engine_power", 0, deactivate_time)
		stop_engines()
		Ref.game_manager.check_for_level_finished()
		
	printt("bolt_active", bolt_is_active, self)


func _on_shield_animation_finished(anim_name: String) -> void:
	
	shield_loops_counter += 1
	
	match anim_name:
		"shield_on":	
			# končan intro ... zaženi prvi loop
			if shield_loops_counter <= shield_loops_limit:
				animation_player.play("shielding")
			# končan outro ... resetiramo lupe in ustavimo animacijo
			else:
				animation_player.stop(false) # včasih sem rabil, da se ne cikla, zdaj pa je okej, ker ob
				shield_loops_counter = 0
				shields_on = false
				bolt_collision.set_deferred("disabled", false)
				shield_collision.set_deferred("disabled", true)
		"shielding":
			# dokler je loop manjši od limita ... replayamo animacijo
			if shield_loops_counter < shield_loops_limit:
				animation_player.play("shielding") # animacija ni naštimana na loop, ker se potem ne kliče po vsakem loopu
			# konec loopa, ko je limit dosežen
			elif shield_loops_counter >= shield_loops_limit:
				animation_player.play_backwards("shield_on")


func _on_EngineStart_finished() -> void:
	
	$Sounds/Engine.play()


# STATS ------------------------------------------------------------------------------------------------


func update_bolt_points(points_change: int):
	
	update_stat("points", points_change)
	

func update_bolt_rank(new_bolt_rank: int):
	
	update_stat("level_rank", new_bolt_rank)


func update_stat(stat_name: String, change_value: float):
	 
	if not Ref.game_manager.game_on:
		return
			
	if stat_name == "best_lap_time": 
		player_stats[stat_name] = change_value
	elif stat_name == "level_time": 
		player_stats[stat_name] = change_value
	elif stat_name == "level_rank": 
		player_stats[stat_name] = change_value
	else:
		player_stats[stat_name] += change_value # change_value je + ali -
		
	emit_signal("stats_changed", bolt_id, player_stats)