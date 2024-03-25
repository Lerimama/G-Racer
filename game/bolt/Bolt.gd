extends KinematicBody2D
class_name Bolt, "res://assets/class_icons/bolt_icon.png"


signal stat_changed (stat_owner, stat, stat_change) # bolt in damage
signal bolt_activity_changed (bolt_is_active)

enum MotionStates {IDLE, FWD, REV, DIZZY, DISARRAY, DYING} # glede na moč motorja
var current_motion_state: int = MotionStates.IDLE
enum Modes {RACING, FOLLOWING, FIGHTING} # RACING ... kadar šiba proti cilju, FOLLOWING ... kadar sledi gibajoči se tarči, FIGHTING ... kadar želi tarčo zadeti
var current_mode: int = Modes.RACING

var bolt_active: bool = false setget _on_bolt_active_changed # predvsem za pošiljanje signala GMju

var bolt_id: int # ga seta spawner
var bolt_color: Color = Color.white
var input_power: float
var acceleration: Vector2
var velocity: Vector2 = Vector2.ZERO
var collision: KinematicCollision2D

var axis_distance: float # določen glede na širino sprajta
var rotation_angle: float
var rotation_dir: float
var stop_speed: float = 15 # hitrost pri kateri ga kar ustavim
var revive_time: float = 2

# weapons
var bullet_reloaded: bool = true
var misile_reloaded: bool = true
var mina_reloaded: bool = true
var mina_released: bool # če je že odvržen v trenutni ožini
var shocker_reloaded: bool = true
var shocker_released: bool # če je že odvržen v trenutni ožini
var shields_on = false
var shield_loops_counter: int = 0
var shield_loops_limit: int = 1 # poberem jo iz profilov, ali pa kot veleva pickable

# trail
var bolt_trail_active: bool = false # aktivna je ravno spawnana, neaktiva je "odklopljena"
var bolt_trail_alpha = 0.05
var trail_pseudodecay_color = Color.white
var current_active_trail: Line2D

# engine
var engine_power = 0 # ob štartu je noga z gasa
var engine_particles_rear : CPUParticles2D
var engine_particles_front_left : CPUParticles2D
var engine_particles_front_right : CPUParticles2D

# za level area efekte
var bolt_on_nitro_count: int = 0
var bolt_on_hole_count: int = 0
var bolt_on_gravel_count: int = 0
var bolt_on_tracking_count: int = 0

# racing
var laps_finished:  int # spreminja GM, ker preverja, če so bili izpolnjeni pogoji za krog
var checkpoints_reached: Array # spreminja ga element sam, desežene v trneutnem krogu
var current_lap_time: float # statistika
var fastest_lap_time: float # statistika
var current_race_ranking: int # 

# fighting
var tilt_speed_call: int = 0 
#var disarray_rotation_dir = 6
var selected_feat_index: int = 0
var available_features: Array = [] # feature icons

onready var dissaray_tween: SceneTreeTween # za ustavljanje na lose life

onready var bolt_hud: Node2D = $BoltHud
onready var bolt_sprite: Sprite = $Bolt
onready var bolt_collision: CollisionPolygon2D = $BoltCollision # zaradi shielda ga moram imet
onready var shield: Sprite = $Shield
onready var shield_collision: CollisionShape2D = $ShieldCollision
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var energy_bar_holder: Control = $BoltHud/VBoxContainer/EnergyBar
onready var energy_bar: Polygon2D = $BoltHud/VBoxContainer/EnergyBar/Bar
onready var feat_selector:  = $BoltHud/VBoxContainer/FeatSelector

# nodeti
onready var FloatingTag: PackedScene = preload("res://game/arena/FloatingTag.tscn")
onready var CollisionParticles: PackedScene = preload("res://game/bolt/BoltCollisionParticles.tscn")
onready var EngineParticles: PackedScene = preload("res://game/bolt/EngineParticles.tscn") 
onready var ExplodingBolt: PackedScene = preload("res://game/bolt/ExplodingBolt.tscn")
onready var BoltTrail: PackedScene = preload("res://game/bolt/BoltTrail.tscn")
onready var BulletScene: PackedScene = preload("res://game/weapons/Bullet.tscn")
onready var MisileScene: PackedScene = preload("res://game/weapons/Misile.tscn")
onready var MinaScene: PackedScene = preload("res://game/weapons/Mina.tscn")
onready var ShockerScene: PackedScene = preload("res://game/weapons/Shocker.tscn")
# stats
onready var points: int = Pro.default_player_stats["points"]
onready var wins: int = Pro.default_player_stats["wins"]
onready var life: int = Pro.default_bolt_stats["life"]
onready var energy: float = Pro.default_bolt_stats["energy"]
onready var max_energy: float = Pro.default_bolt_stats["energy"] # zato, da se lahko resetira
onready var gas_count: float = Pro.default_bolt_stats["gas_count"]
onready var bullet_count: float = Pro.default_bolt_stats["bullet_count"]
#onready var bullet_power: float = Pro.default_bolt_stats["bullet_power"]
onready var misile_count: float = Pro.default_bolt_stats["misile_count"]
onready var mina_count: float = Pro.default_bolt_stats["mina_count"]
onready var shocker_count: float = Pro.default_bolt_stats["shocker_count"]
# bolt profil ... default vrednosti, ki jih lahko med igro spreminjam
onready var bolt_type: int = Pro.BoltTypes.BASIC
onready var bolt_sprite_texture: Texture = Pro.bolt_profiles[bolt_type]["bolt_texture"] 
onready var fwd_engine_power: int = Pro.bolt_profiles[bolt_type]["fwd_engine_power"]
onready var rev_engine_power: int = Pro.bolt_profiles[bolt_type]["rev_engine_power"]
onready var turn_angle: int = Pro.bolt_profiles[bolt_type]["turn_angle"] # deg per frame
onready var free_rotation_multiplier: int = Pro.bolt_profiles[bolt_type]["free_rotation_multiplier"] # rotacija kadar miruje
onready var drag: float = Pro.bolt_profiles[bolt_type]["drag"] # raste kvadratno s hitrostjo
onready var side_traction: float = Pro.bolt_profiles[bolt_type]["side_traction"]
onready var bounce_size: float = Pro.bolt_profiles[bolt_type]["bounce_size"]
onready var mass: float = Pro.bolt_profiles[bolt_type]["mass"]
onready var reload_ability: float = Pro.bolt_profiles[bolt_type]["reload_ability"]  # reload def gre v weapons
onready var fwd_gas_usage: float = Pro.bolt_profiles[bolt_type]["fwd_gas_usage"] 
onready var rev_gas_usage: float = Pro.bolt_profiles[bolt_type]["rev_gas_usage"] 
onready var drag_force_div: float = Pro.bolt_profiles[bolt_type]["drag_force_div"] 


func _ready() -> void:

	printt("BOLT", bolt_id)
	
	# bolt 
	add_to_group(Ref.group_bolts)	
	bolt_sprite.texture = bolt_sprite_texture
	axis_distance = bolt_sprite_texture.get_width()

	set_engines() # postavi partikle za pogon
	
	# nodes
	shield.hide() 
	shield.modulate.a = 0 
	shield_collision.disabled = true 
	shield.self_modulate = bolt_color 
	bolt_hud.hide()
	
	# bolt wiggle šejder
	bolt_sprite.material.set_shader_param("noise_factor", 0)

	feat_selector.hide()
	
	# napolnem možne featurje (notri so tudi, ko je count = 0
	available_features.append(feat_selector.get_node("Icons/IconBullet"))
	available_features.append(feat_selector.get_node("Icons/IconMisile"))
	available_features.append(feat_selector.get_node("Icons/IconMina"))
	available_features.append(feat_selector.get_node("Icons/IconShocker"))

func _physics_process(delta: float) -> void:
	printt("gas_count", gas_count)
	# aktivacija pospeška je setana na vozniku
	# plejer ... acceleration = transform.x * engine_power # transform.x je (-1, 0)
	# enemi ... acceleration = position.direction_to(navigation_agent.get_next_location()) * engine_power
	
	# animiran bolt .. sprite se ne rotira z zavijanjem ... # bolt_sprite.rotation = - global_rotation
	
	if current_motion_state == MotionStates.DISARRAY:
		rotation_angle = rotation_dir * deg2rad(turn_angle)
	else:
		# sila upora raste s hitrostjo		
		var drag_force = drag * velocity * velocity.length() / drag_force_div # množenje z velocity nam da obliko vektorja
		# hitrost je pospešek s časom
		acceleration -= drag_force
		velocity += acceleration * delta
		rotation_angle = rotation_dir * deg2rad(turn_angle)
		rotate(delta * rotation_angle)
		steering(delta)

	collision = move_and_collide(velocity * delta, false)
	if collision:
		on_collision()	
	
	manage_motion_states(delta)
	manage_motion_fx()
	
	if Ref.game_manager.game_settings["race_mode"]:
		#		# poraba bencina
		#		if current_motion_state == MotionStates.FWD:
		#			manage_gas(fwd_gas_usage)
		#		elif current_motion_state == MotionStates.REV:
		#			manage_gas(rev_gas_usage)
		
		# setam feature index, da je izbran tisti, ki ima količino večjo od 0
		if bullet_count > 0:
			selected_feat_index = 1
		elif misile_count > 0:
			selected_feat_index = 2
		elif mina_count > 0:
			selected_feat_index = 3
		elif shocker_count > 0:
			selected_feat_index = 4
		else:
			selected_feat_index = 0
	else:
		update_feature_selector()
		manage_bolt_hud()
			
		
	
# IZ PROCESA ----------------------------------------------------------------------------


func update_feature_selector():
	
	$BoltHud/VBoxContainer/FeatSelector/Icons/IconBullet.get_node("Label").text = "%02d" % bullet_count
	$BoltHud/VBoxContainer/FeatSelector/Icons/IconMisile.get_node("Label").text = "%02d" % misile_count
	$BoltHud/VBoxContainer/FeatSelector/Icons/IconMina.get_node("Label").text = "%02d" % mina_count
	$BoltHud/VBoxContainer/FeatSelector/Icons/IconShocker.get_node("Label").text = "%02d" % shocker_count
	
	
func on_collision():
	
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


func tilt_bolt(tilt_direction):
	
	var tilt_speed: float = Pro.bolt_profiles[bolt_type]["tilt_speed"]
	
	# način, ko feature tipka drži funkcijo
	if Ref.game_manager.game_settings["race_mode"]:
		tilt_speed_call += 1 # resetira ga input na plejerju
		
		if tilt_speed_call == 1:
			tilt_speed = 150
		else:
			tilt_speed = 20
			
		var tilt_vector: Vector2 = tilt_direction.rotated(deg2rad(90)) * tilt_speed
		velocity = velocity + tilt_vector.rotated(global_rotation)

	# način na hitri klik v smeri
	else:

		tilt_speed = 100
		var tilt_time: float = 0.05
		var tilt_velocity: Vector2 = Vector2(1,-8) * tilt_speed
		var tilt_vector = tilt_direction.rotated(deg2rad(90)) * tilt_speed
		var tilt_tween = get_tree().create_tween()
		tilt_tween.tween_property(self, "velocity", velocity + tilt_vector.rotated(global_rotation), tilt_time).set_ease(Tween.EASE_IN_OUT)
		tilt_tween.tween_property(self, "tilt_speed", 0, 0)#.set_ease(Tween.EASE_IN_OUT)


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
#		engine_power = 0
#		print ("states")
		return
		
	if engine_power > 0:
		current_motion_state = MotionStates.FWD
	elif engine_power < 0:
		current_motion_state = MotionStates.REV
	else:
		current_motion_state = MotionStates.IDLE	
	

func manage_motion_fx():

	# position2D
	# var rear_engine_pos: Vector2 = bolt_sprite.get_node("RearEnginePosition").position
	# var front_engine_pos_L: Vector2 = bolt_sprite.get_node("FrontEnginePositionL").position
	# var front_engine_pos_R: Vector2 = bolt_sprite.get_node("FrontEnginePositionR").position
	# old
	# var rear_engine_pos: Vector2 = Vector2(-3.5, 0.5)
	# var front_engine_pos_L: Vector2 = Vector2( 2.5, -2.5)
	# var front_engine_pos_R: Vector2 = Vector2(2.5, 3.5)
	# new
	var rear_engine_pos: Vector2 = Vector2(-2.7, 0.5)
	var front_engine_pos_L: Vector2 = Vector2(3, -4)
	var front_engine_pos_R: Vector2 = Vector2(3, 4.5)	
	
	shield.rotation = -rotation # negiramo rotacijo bolta, da je pri miru
	
	# zadnji motor
	if current_motion_state == MotionStates.FWD:
		engine_particles_rear.modulate.a = velocity.length()/50
		engine_particles_rear.set_emitting(true)
	elif current_motion_state == MotionStates.REV:
		engine_particles_front_left.modulate.a = velocity.length()/10
		engine_particles_front_left.set_emitting(true)
		engine_particles_front_right.modulate.a = velocity.length()/10
		engine_particles_front_right.set_emitting(true)
	elif current_motion_state == MotionStates.IDLE:
		engine_particles_rear.modulate.a = 0
		engine_particles_front_left.modulate.a = 0
		engine_particles_front_right.modulate.a = 0
		
	# pozicije vseh motorjev
	engine_particles_front_left.global_position = to_global(front_engine_pos_L)
	engine_particles_front_left.global_rotation = bolt_sprite.global_rotation - deg2rad(180)
	engine_particles_rear.global_position = to_global(rear_engine_pos)
	engine_particles_rear.global_rotation = bolt_sprite.global_rotation
	engine_particles_front_right.global_position = to_global(front_engine_pos_R)
	engine_particles_front_right.global_rotation = bolt_sprite.global_rotation - deg2rad(180)	
		
	# spawn trail if not active
	if not bolt_trail_active and velocity.length() > 0: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
		current_active_trail = spawn_new_trail()
	# manage trail
	if bolt_trail_active:
		manage_trail()

	# engine transparency
	if velocity.length() < 100:
		engine_particles_rear.modulate.a = velocity.length()/100
		engine_particles_front_left.modulate.a = velocity.length()/100
		engine_particles_front_right.modulate.a = velocity.length()/100
	else:
		engine_particles_rear.modulate.a = 1
		engine_particles_front_left.modulate.a = 1
		engine_particles_front_right.modulate.a = 1


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
				
	gas_count += gas_usage
	gas_count = clamp(gas_count, 0, gas_count)
	
	if gas_count == 0: # če zmanjka bencina je deaktiviran
		self.bolt_active = false
	
	emit_signal("stat_changed", bolt_id, "gas_count", gas_count)	
	

func manage_bolt_hud():
	
	if not bolt_hud.visible:
		bolt_hud.show()
		
	# energy_bar
	bolt_hud.rotation = -rotation # negiramo rotacijo bolta, da je pri miru
	bolt_hud.global_position = global_position + Vector2(0, 8)

	if energy_bar_holder.visible:
		energy_bar.scale.x = energy / max_energy
		if energy_bar.scale.x <= 0.5:
			energy_bar.color = Set.color_red
		else:
			energy_bar.color = Set.color_green
			

# LIFE CYCLE ----------------------------------------------------------------------------


func on_hit(hit_by: Node):
	
	if shields_on:
		return

	if not Ref.game_manager.game_settings["race_mode"]:
		energy -= hit_by.hit_damage # če je nula se pedena zadeve urejajo na dnu funkcije
		emit_signal("stat_changed", bolt_id, "energy", energy) # do GMa 
				
	if hit_by.is_in_group(Ref.group_bullets):
		Ref.current_camera.shake_camera(Ref.current_camera.bullet_hit_shake)
		if velocity == Vector2.ZERO:
			velocity = hit_by.velocity / mass
		else:
			velocity += hit_by.velocity * hit_by.mass / mass
		in_disarray(hit_by.hit_damage)
		
	elif hit_by.is_in_group(Ref.group_misiles):
		Ref.current_camera.shake_camera(Ref.current_camera.misile_hit_shake)
		if velocity == Vector2.ZERO:
			velocity = hit_by.velocity
		else:
			velocity += hit_by.velocity * hit_by.mass / mass
		in_disarray(hit_by.hit_damage)
#
	elif hit_by.is_in_group(Ref.group_mine):
		Ref.current_camera.shake_camera(Ref.current_camera.misile_hit_shake)
		in_disarray(hit_by.hit_damage)
		
	elif hit_by.is_in_group(Ref.group_shockers):
		# damage
		energy -= hit_by.hit_damage # če je nula se pedena zadeve urejajo na dnu funkcije
		emit_signal("stat_changed", bolt_id, "energy", energy) # do GMa 
		# efekt
		set_process_input(false)
		var catch_tween = get_tree().create_tween()
		catch_tween.tween_property(self, "engine_power", 0, 0.1) # izklopim motorje, da se čist neha premikat
		catch_tween.parallel().tween_property(self, "velocity", Vector2.ZERO, 1.0) # tajmiram pojemek 
		catch_tween.parallel().tween_property(bolt_sprite, "modulate:a", 0.5, 0.5)
		bolt_sprite.material.set_shader_param("noise_factor", 2.0)
		bolt_sprite.material.set_shader_param("speed", 0.7)
		yield(get_tree().create_timer(hit_by.shock_time), "timeout") # controlls off time
		# release
		var relase_tween = get_tree().create_tween()
		relase_tween.tween_property(self, "engine_power", engine_power, 0.1)
		relase_tween.parallel().tween_property(bolt_sprite, "modulate:a", 1.0, 0.5)				
		yield(relase_tween, "finished")
		# reset shader
		bolt_sprite.material.set_shader_param("noise_factor", 0.0)
		bolt_sprite.material.set_shader_param("speed", 0.0)
		set_process_input(true)
		
	# energy management	
	energy = clamp(energy, 0, max_energy)
	energy_bar.scale.x = energy/10
	if energy == 0:
		lose_life()


func in_disarray(damage_amount: float): # 5 raketa, 1 metk
#	damage_amount = 5 # debug
	
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
	
	explode()
	bolt_collision.disabled = true
	visible = false
	set_process_input(false)		
	set_physics_process(false)
	life -= 1
	emit_signal("stat_changed", bolt_id, "life", life)
	if life > 0:
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
	energy = max_energy
	current_motion_state = MotionStates.IDLE
	dissaray_tween.kill()
	velocity = Vector2.ZERO
	rotation_dir = 0
	engine_power = 0
	set_process_input(true)		
	set_physics_process(true)
	visible = true
	bolt_active = true
	
	emit_signal("stat_changed", bolt_id, "energy", energy)


# RACE ----------------------------------------------------------------------------


func on_lap_finished(current_race_time: float, laps_limit: int):

	# čas kroga
	if laps_finished == 0: # če je prvi krog
		current_lap_time = current_race_time
		fastest_lap_time = current_lap_time	
		spawn_floating_tag(current_lap_time, true) # time, is fastest
	else: # če že ima vpisanega, ga odštejem od trenutnega časa
		current_lap_time = current_race_time - current_lap_time
		# je najhitrejši krog?
		if current_lap_time < fastest_lap_time:
			fastest_lap_time = current_lap_time
			spawn_floating_tag(current_lap_time, true) # time, is fastest
		else:
			spawn_floating_tag(current_lap_time, false) # time, not fastest
	
	# prištejem krog in mu zbrišem čekpointe
	laps_finished += 1
	checkpoints_reached.clear()
	
	emit_signal("stat_changed", bolt_id, "lap_finished", [laps_finished, fastest_lap_time]) 


func on_checkpoint_reached(checkpoint: Area2D):
	
	if not checkpoints_reached.has(checkpoint): # če še ni dodana
		checkpoints_reached.append(checkpoint)
	

func spawn_floating_tag(lap_time_seconds: float, best_lap: bool):
	
	if lap_time_seconds == 0:
		return
		
	var current_lap_time_on_clock: String = Met.get_clock_time(lap_time_seconds)
	
	var new_floating_tag = FloatingTag.instance()
	new_floating_tag.z_index = 4 # višje od straysa in playerja
	# če je zadnji krog njegov čas ostane na liniji
	new_floating_tag.global_position = global_position
	new_floating_tag.tag_owner = self
	Ref.node_creation_parent.add_child(new_floating_tag)
	
	printt("time3", current_lap_time_on_clock)
	new_floating_tag.label.text = current_lap_time_on_clock
	if best_lap == true:
		new_floating_tag.modulate = Set.color_green
	else:
		new_floating_tag.modulate = Set.color_red
	
	
		
# UTILITY ----------------------------------------------------------------------------


func spawn_new_trail():
	
	var new_bolt_trail: Object
	new_bolt_trail = BoltTrail.instance()
	new_bolt_trail.modulate.a = bolt_trail_alpha
	new_bolt_trail.z_index = z_index + Set.trail_z_index
	Ref.node_creation_parent.add_child(new_bolt_trail)
	
	bolt_trail_active = true	
	
	return new_bolt_trail
	
			
func set_engines():
	var rear_engine_pos: Vector2 = Vector2(-3.5, 0.5)
	var front_engine_pos_L: Vector2 = Vector2( 2.5, -2.5)
	var front_engine_pos_R: Vector2 = Vector2(2.5, 3.5)	
		
	engine_particles_rear = EngineParticles.instance()
	# rotacija in pozicija se morata apdejta vsak frejm ... FP
	engine_particles_rear.z_index = z_index + Set.engine_z_index
	Ref.node_creation_parent.add_child(engine_particles_rear)
	engine_particles_rear.modulate.a = 0
	
	engine_particles_front_left = EngineParticles.instance()
	# rotacija in pozicija se morata apdejta vsak frejm ... FP
	engine_particles_front_left.emission_rect_extents = Vector2.ZERO
	engine_particles_front_left.amount = 20
	engine_particles_front_left.initial_velocity = 50
	engine_particles_front_left.lifetime = 0.05
	engine_particles_front_left.modulate.a = 0
	engine_particles_front_left.z_index = z_index + Set.engine_z_index
	Ref.node_creation_parent.add_child(engine_particles_front_left)
	
	engine_particles_front_right = EngineParticles.instance()
	# rotacija in pozicija se morata apdejta vsak frejm ... FP
	engine_particles_front_right.emission_rect_extents = Vector2.ZERO
	engine_particles_front_right.amount = 20
	engine_particles_front_right.initial_velocity = 50
	engine_particles_front_right.lifetime = 0.05
	engine_particles_front_right.modulate.a = 0
	engine_particles_front_right.z_index = z_index + Set.engine_z_index
	Ref.node_creation_parent.add_child(engine_particles_front_right)

		
func shooting(weapon: String) -> void:
	
	var gun_pos: Vector2 = Vector2(6.5, 0.5)
	var shocker_pos: Vector2 = Vector2(-4.5, 0.5)	
	
	match weapon:
		"bullet":
				
			if bullet_reloaded:
				if bullet_count <= 0:
					return
				var new_bullet = BulletScene.instance()
				new_bullet.global_position = to_global(gun_pos)
				new_bullet.global_rotation = bolt_sprite.global_rotation
				new_bullet.spawned_by = self # ime avtorja izstrelka
				new_bullet.spawned_by_color = bolt_color
				new_bullet.z_index = z_index + Set.weapons_z_index
				Ref.node_creation_parent.add_child(new_bullet)
				bullet_count -= 1
				emit_signal("stat_changed", bolt_id, "bullet_count", bullet_count) # do GMa
				bullet_reloaded = false
				yield(get_tree().create_timer(new_bullet.reload_time / reload_ability), "timeout")
				bullet_reloaded= true
		"misile":
			if misile_reloaded and misile_count > 0:			
				var new_misile = MisileScene.instance()
				new_misile.global_position = to_global(gun_pos)
				new_misile.global_rotation = bolt_sprite.global_rotation
				new_misile.spawned_by = self # zato, da lahko dobiva "točke ali kazni nadaljavo
				new_misile.spawned_by_color = bolt_color
				new_misile.spawned_by_speed = velocity.length()
				new_misile.z_index = z_index + Set.weapons_z_index
				Ref.node_creation_parent.add_child(new_misile)
				misile_count -= 1
				emit_signal("stat_changed", bolt_id, "misile_count", misile_count) # do GMa
				misile_reloaded = false
				yield(get_tree().create_timer(new_misile.reload_time / reload_ability), "timeout")
				misile_reloaded= true
		"mina":
			print("š mina")
			if mina_reloaded and mina_count > 0:			
				var new_mina = MinaScene.instance()
				new_mina.global_position = to_global(shocker_pos)
				new_mina.global_rotation = bolt_sprite.global_rotation
				new_mina.spawned_by = self # ime avtorja izstrelka
				new_mina.spawned_by_color = bolt_color
				new_mina.z_index = z_index + Set.weapons_z_index
				Ref.node_creation_parent.add_child(new_mina)
				mina_count -= 1
				emit_signal("stat_changed", bolt_id, "mina_count", mina_count) # do GMa
				mina_reloaded = false
				yield(get_tree().create_timer(new_mina.reload_time / reload_ability), "timeout")
				mina_reloaded = true
		"shocker":
			print("š shocker")
			
			if shocker_reloaded and shocker_count > 0:			
				var new_shocker = ShockerScene.instance()
				new_shocker.global_position = to_global(shocker_pos)
				new_shocker.global_rotation = bolt_sprite.global_rotation
				new_shocker.spawned_by = self # ime avtorja izstrelka
				new_shocker.spawned_by_color = bolt_color
				new_shocker.z_index = z_index + Set.weapons_z_index
				Ref.node_creation_parent.add_child(new_shocker)
				shocker_count -= 1
				emit_signal("stat_changed", bolt_id, "shocker_count", shocker_count) # do GMa
				shocker_reloaded = false
				yield(get_tree().create_timer(new_shocker.reload_time / reload_ability), "timeout")
				shocker_reloaded= true

			
func activate_shield():
	
	if shields_on == false:
#		shield.show()
		shield.modulate.a = 1
		animation_player.play("shield_on")
		shields_on = true
		bolt_collision.disabled = true
		shield_collision.disabled = false
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
		drag_force_div = Ref.game_manager.game_settings["area_nitro_drag_force_div"]
		yield(get_tree().create_timer(nitro_time), "timeout")
		drag_force_div = Pro.bolt_profiles[bolt_type]["drag_force_div"]	


func get_points(points_added: int): # kličem od zunaj ob dodajanju točk ... ni samo na "item picked"
	
	points += points_added
	points = clamp(points, 0, points)
	emit_signal("stat_changed", bolt_id, "points", points) # do GMa
	
	
func on_item_picked(pickable_type_key: String):
	
	var pickable_value: float = Pro.pickable_profiles[pickable_type_key]["pickable_value"]
	var pickable_time: float = Pro.pickable_profiles[pickable_type_key]["pickable_time"]
	
	match pickable_type_key:
		"BULLET":
			bullet_count += pickable_value
			emit_signal("stat_changed", bolt_id, "bullet_count", bullet_count) 
			selected_feat_index = 1
			
			if Ref.game_manager.game_settings["race_mode"]:
				misile_count = 0
				emit_signal("stat_changed", bolt_id, "misile_count", misile_count) 
				mina_count = 0
				emit_signal("stat_changed", bolt_id, "mina_count", mina_count) 
				shocker_count = 0
				emit_signal("stat_changed", bolt_id, "shocker_count", shocker_count) 
		"MISILE":
			misile_count += pickable_value
			emit_signal("stat_changed", bolt_id, "misile_count", misile_count) 
			selected_feat_index = 2
			
			if Ref.game_manager.game_settings["race_mode"]:
				bullet_count = 0
				emit_signal("stat_changed", bolt_id, "bullet_count", bullet_count) 
				mina_count = 0
				emit_signal("stat_changed", bolt_id, "mina_count", mina_count) 
				shocker_count = 0
				emit_signal("stat_changed", bolt_id, "shocker_count", shocker_count) 
		"MINA":
			mina_count += pickable_value
			emit_signal("stat_changed", bolt_id, "mina_count", mina_count) 
			selected_feat_index = 3
			
			if Ref.game_manager.game_settings["race_mode"]:
				bullet_count = 0
				emit_signal("stat_changed", bolt_id, "bullet_count", bullet_count) 
				misile_count = 0
				emit_signal("stat_changed", bolt_id, "misile_count", misile_count) 
				shocker_count = 0
				emit_signal("stat_changed", bolt_id, "shocker_count", shocker_count) 
		"SHOCKER":
			shocker_count += pickable_value
			emit_signal("stat_changed", bolt_id, "shocker_count", shocker_count) 
			selected_feat_index = 4
			
			if Ref.game_manager.game_settings["race_mode"]:
				bullet_count = 0
				emit_signal("stat_changed", bolt_id, "bullet_count", bullet_count) 
				mina_count = 0
				emit_signal("stat_changed", bolt_id, "mina_count", mina_count) 
				misile_count = 0
				emit_signal("stat_changed", bolt_id, "misile_count", misile_count) 
		"SHIELD":
			shield_loops_limit = pickable_value
			activate_shield()
		"ENERGY":
			energy = max_energy
		"GAS":
			gas_count += pickable_value
			emit_signal("stat_changed", bolt_id, "gas_count", gas_count)
		"LIFE":
			life += pickable_value
			emit_signal("stat_changed", bolt_id, "life", life)
		"NITRO":
			activate_nitro(pickable_value, pickable_time)
		"TRACKING":
			var default_traction = side_traction
			side_traction = pickable_value
			yield(get_tree().create_timer(pickable_time), "timeout")
			side_traction = default_traction
		"POINTS":
			points += pickable_value
			emit_signal("stat_changed", bolt_id, "points", points)
		"RANDOM":
			var random_range: int = Pro.pickable_profiles.keys().size()
			var random_pickable_index = randi() % random_range
			var random_pickable_key = Pro.pickable_profiles.keys()[random_pickable_index]
			on_item_picked(random_pickable_key) # pick selected
			
			
# PRIVAT ------------------------------------------------------------------------------------------------


func _on_bolt_active_changed(bolt_is_active: bool):
	
	# če je aktiven ga upočacnim v trenutni smeri
	bolt_active = bolt_is_active
	if not bolt_active:
		rotation_dir = 0
		var dissable_tween = get_tree().create_tween()
		dissable_tween.tween_property(self, "velocity", Vector2.ZERO, 2) # tajmiram pojemek 
#		dissable_tween.parallel().tween_property(self, "rotation_dir", 0, on_hit_disabled_time)#.set_ease(Tween.EASE_IN) # tajmiram pojemek 
#		yield(dissaray_tween, "finished")
#		set_process_input(true)				
	emit_signal("bolt_activity_changed", self)


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
				bolt_collision.disabled = false
				shield_collision.disabled = true
		"shielding":
			# dokler je loop manjši od limita ... replayamo animacijo
			if shield_loops_counter < shield_loops_limit:
				animation_player.play("shielding") # animacija ni naštimana na loop, ker se potem ne kliče po vsakem loopu
			# konec loopa, ko je limit dosežen
			elif shield_loops_counter >= shield_loops_limit:
				animation_player.play_backwards("shield_on")
