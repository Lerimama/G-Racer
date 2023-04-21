extends KinematicBody2D


# premaknjeno v Signals
# signal path_changed (path) # pošlje array pozicij
# signal target_reached # trenutno ni v uporabi

var player_name: String = "Enemy"
var player_color: Color = Color.white

var engine_power: float	
var acceleration: Vector2
var velocity: Vector2 = Vector2.ZERO
var misile_reloaded: bool = true
var shocker_reloaded: bool = true
var shocker_released: bool # če je že odvržen v trneutni ožini

# states
var control_enabled: bool = true

# fx
var stop_velocity = 5 # pri kateri hitrosti se tretira kot, da je pri miru
var bolt_trail_active: bool = false # če je je aktivna, je ravno spawnana, če ni , potem je "odklopljena"
var new_bolt_trail: Object
var engine_particles_rear : CPUParticles2D
var engine_particles_front_left : CPUParticles2D
var engine_particles_front_right : CPUParticles2D

# idle
onready var navigation_cells: Array # sek
export var idle_brake_force: float = 0.95
var idle_vision_angle: float = 45  # plus in minus
var idle_target_max_distance = 300
var idle_target_set: bool #  =  false

# battle
var locked_on_target: bool
var target_reached: bool
var target_location: Vector2
var target_slow_speed = 10

# shooting logic
export var min_attacking_distance: float = 70 # največja bližina do tarče ... engine_power = 0, rotira se okrog svoje osi (bolj nevaren za streljat)
export var max_attacking_distance: float = 400 # najdaljša bližina do tarče ... misile
export var mid_attacking_distance: float = 300 # najbližje ko še strelja misile
var shocker_delay_time: float = 1.5

# ---------------------------------------------------------------------------------------

onready var navigation_agent = $NavigationAgent2D
onready var seek_ray = $SeekRay
onready var vision_ray_front = $VisionFront
onready var vision_ray_rear = $VisionRear
onready var vision_ray_left = $VisionLeft # poz kot
onready var vision_ray_right = $VisionRight # neg kot

onready var rear_engine_position = $Bolt/RearEnginePosition
onready var front_engine_position_L = $Bolt/FrontEnginePositionL
onready var front_engine_position_R = $Bolt/FrontEnginePositionR
onready var BoltTrail: PackedScene = preload("res://scenes/bolt/BoltTrail.tscn")

# enemy profil
onready var enemy_profile = Profiles.enemy_profiles
onready var aim_time = enemy_profile["aim_time"]
onready var seek_rotation_range = enemy_profile["seek_rotation_range"]
onready var seek_rotation_speed = enemy_profile["seek_rotation_speed"]
onready var seek_distance = enemy_profile["seek_distance"]
onready var engine_power_idle = enemy_profile["engine_power_idle"]
onready var engine_power_battle = enemy_profile["engine_power_battle"]
onready var shooting_ability = enemy_profile["shooting_ability"]


onready var seek_rays_group: Array = [$SeekRayL1, $SeekRayL2, $SeekRayR1, $SeekRayR2]
onready var indikator: PackedScene = preload("res://indikator.tscn")


func indikator_spawn(pos): # za test pozicije
	
	var new_indikator = indikator.instance()
	new_indikator.global_position = pos
#	new_indikator.global_rotation = bolt_sprite.global_rotation
	new_indikator.modulate = Color.red
	add_child(new_indikator)


func _ready() -> void:
	
	randomize()
	
	add_to_group(Config.group_enemies)
	add_to_group(Config.group_bolts)
#	name = player_name # lahko da mora bit ugasnjeno zaradi nekega erorja
#	bolt_sprite.modulate = player_color
	
	# features setup
#	bolt_collision.disabled = false
#	engines_setup() # postavi partikle za pogon
#	shield.modulate.a = 0 
#	shield.self_modulate = player_color 
#	shield_collision.disabled = true 
#	bolt_sprite.material.set_shader_param("noise_factor", 0)

	seek_ray.cast_to.x = seek_distance
	
	
func _physics_process(delta: float) -> void:
	
	set_target_location(target_location) # tukaj setamo target reached na false
	
	acceleration = position.direction_to(navigation_agent.get_next_location()) * engine_power # * 0
	
#	var drag_force = drag * velocity * velocity.length() / 100 # množenje z velocity nam da obliko vektorja
#	acceleration -= drag_force
#
#	if control_enabled: 
#		velocity += acceleration * delta
#		navigation_agent.set_velocity(velocity) # vedno za kustom velocity izračunom
#
#		# tole je načeloma nepomembno
#		rotation_angle = rotation_dir * deg2rad(turn_angle)
#		rotate(delta * rotation_angle)
#		steering(delta)
#
#		# smooth turning
#		rotation = velocity.angle()
#
#	collision = move_and_collide(velocity * delta, false)
#
#	if collision:
#		on_collision()
#
#	vision(delta)
#	shield.rotation = -rotation # negiramo rotacijo bolta, da je pri miru

	motion_fx()
	
	# health and damage
#	health_bar.rotation = -(rotation) # negiramo rotacijo bolta, da je pri miru
#	health_bar.global_position = global_position + Vector2(-3.5, 8) # negiramo rotacijo bolta, da je pri miru
#	health_bar.scale.x = health / health_max
#	if health_bar.scale.x < 0.5:
#		health_bar.color = Color.indianred
#	else:
#		health_bar.color = Color.aquamarine
	
	pass
	

func vision(delta):
	
	if control_enabled: 
		
		# čekiraj ovire pred sabo
		vision_ray_front.cast_to = Vector2(velocity.length(), 0) # zmeraj dolg kot je dolga hitrost
		if vision_ray_front.is_colliding():
			velocity *= idle_brake_force
#			engine_particles_rear.modulate.a = 0
#		else:
#			engine_particles_rear.modulate.a = 1
		
		# večno iskanje tarče
		if seek_ray.is_colliding() and seek_ray.get_collider().is_in_group(Config.group_bolts):
			var collider = seek_ray.get_collider()
			target_location = collider.global_position
			if collider.velocity.length() < target_slow_speed:
				rotation = (target_location - global_position).angle() # kot vektorja AB = B - A 
#				look_at(target_location)
			seek_ray.look_at(target_location)
			battle(collider)
			modulate = Color.red
			
		else:
			idle() # vklopi idle režim
			modulate = player_color
			seek_ray.rotation += seek_rotation_speed * delta
			if seek_ray.get_rotation_degrees() > seek_rotation_range or seek_ray.get_rotation_degrees() < - seek_rotation_range: 
				seek_rotation_speed *= -1
				
	# reset vision ray
	elif not control_enabled:
		seek_ray.rotation = 0

	
func idle():
#	print("IDLE")

	engine_power = engine_power_idle
	
#	var idle_target_cell: Vector2 = global_position # določena pozicija prve random celice
	var idle_target_cell: Vector2 = Vector2.ZERO # določena pozicija prve random celice
	var idle_area: Array = []
	
	if not idle_target_set: # ta pogoj moram met, če ne vsak frejm išče novo tarčo (ne morem preverit, ker ne vidim linije) 
		if not navigation_cells.empty(): # v prvem poskus je area prazen ... napolne se ob nalaganju enemija
			for cell_position in navigation_cells:
				# če je polju dosega
				var distance_to_cell: float = global_position.distance_to(cell_position)
				var angle_to_cell: float = rad2deg(get_angle_to(cell_position))
				if angle_to_cell > - idle_vision_angle and angle_to_cell < idle_vision_angle:
					if distance_to_cell < idle_target_max_distance: #and distance_to_cell > 150:
						idle_area.append(cell_position)
			# random celica je target 
			if idle_area.size() > 0: # je nek error, če gre iz ekrana ... samo ko mam miško za target
				idle_target_cell = idle_area[randi() % idle_area.size() - 1]

			target_location = idle_target_cell # boltova tarča je random tarča
	else:	
		# ko se pot izteče, gremo še enkrat iskat tarčo
		var current_path_size = navigation_agent.get_nav_path().size()
		if current_path_size < 5:
			idle_target_set = false
			print(navigation_agent.get_nav_path().size())
		
	shocker_check() # a postavlja mine v idle modetu?
	

func battle(target_body):
#	print("BATTLE")
	
	var distance_to_target: float = navigation_agent.distance_to_target()
	var target_speed: float = target_body.velocity.length()
	
	# razdalja večja od dosega rakete
	if distance_to_target >= max_attacking_distance:
##		shooting("bullet")
#		shooting("misile")
		pass
	# razdalja manjša od dosega rakete in večja od minimalne bližine
	elif distance_to_target > min_attacking_distance:
#		modulate = Color.red
		# bremzaj, če je tarča počasna
		if target_speed < target_slow_speed:
			velocity = lerp(velocity, Vector2.ZERO, 0.1)
		# streljaj raketo, če je v coni za raketo in raketo ima
		if distance_to_target > mid_attacking_distance: # and misile_count > 0:
#			yield(get_tree().create_timer(aim_time), "timeout")
#			shooting("misile")
			yield(get_tree().create_timer(2*aim_time), "timeout")
		# streljaj metk, če ni v coni za raketo in raketo ima
		else:
			# da ni istočasno z raketo ... se na pozna na hitrosti streljanja
			# na vsakem metku je aim_time zamik, med sabo pa so zamaknjeni za reload time
			yield(get_tree().create_timer(aim_time), "timeout") 
#			shooting("bullet")
	# razdalja manjša od minimalne bližine
	elif distance_to_target <= min_attacking_distance:
		velocity = lerp(velocity, Vector2.ZERO, 0.1)
		engine_power = 0 # majhen vpliv na vse skupaj ... prepreči pa kakšen čuden karambol
#		modulate = Color.turquoise
#		shooting("bullet")
	
	engine_power = engine_power_battle
	
	shocker_check() # čekiraj razmere za mino	


func motion_fx() -> void:

	if velocity.length() > stop_velocity:
		if control_enabled:
			engine_particles_rear.set_emitting(true)
			engine_particles_rear.position = rear_engine_position.global_position
			engine_particles_rear.rotation = rear_engine_position.global_rotation
		# če trail obstaja, dodajaj pike
		if bolt_trail_active: 		
			new_bolt_trail.gradient.colors[1] = player_color
			new_bolt_trail.add_points(global_position)
		# če je bil trail neaktiven, začni novega
		else:
			new_bolt_trail = BoltTrail.instance()
			Global.effects_creation_parent.add_child(new_bolt_trail)
			bolt_trail_active = true 
	
	elif velocity.length() < - stop_velocity:
		if control_enabled:
			engine_particles_front_left.set_emitting(true) # so one_shot ... zato ne rabim pogojev za ugašanje
			engine_particles_front_left.position = front_engine_position_L.global_position
			engine_particles_front_left.rotation = front_engine_position_L.global_rotation - deg2rad(180)
			engine_particles_front_right.set_emitting(true)
			engine_particles_front_right.position = front_engine_position_R.global_position
			engine_particles_front_right.rotation = front_engine_position_R.global_rotation - deg2rad(180)	
		# če trail obstaja, dodajaj pike
		if bolt_trail_active: 		
			new_bolt_trail.gradient.colors[1] = player_color
			new_bolt_trail.add_points(global_position)
		# če je bil trail neaktiven, začni novega
		else:
			new_bolt_trail = BoltTrail.instance()
			Global.effects_creation_parent.add_child(new_bolt_trail)
			bolt_trail_active = true 
	
	# če je pri miru, začni trail decay
	else:
		# egine partikli so one_shot, zato ne rabim pogojev za ugašanje
		if bolt_trail_active:	
			new_bolt_trail.start_decay() # trail decay tween start
			bolt_trail_active = false # postane neaktivna, a je še vedno prisotna ... queue_free je šele na koncu decay tweena	


func shocker_check():
	
	if vision_ray_left.is_colliding() and vision_ray_right.is_colliding():
		var collider_left = vision_ray_left.get_collider()
		var collider_right = vision_ray_right.get_collider()
		# če je v prišel v ožino in še ni odvrgel mine v trenutni ožini
		if collider_left.is_in_group(Config.group_arena) and collider_right.is_in_group(Config.group_arena):
			if not shocker_released:
				shocker_released = true # pomembno, da je pred tajmerjem
				yield(get_tree().create_timer(shocker_delay_time), "timeout") # tajming da ne dropne čist na začetku ožine
#				shooting("shocker")
	# če je šel iz ožine ... ta del bi bil lahko bolj specifičen kaj je ožina
	else:
		shocker_released = false
		
	# če ma plejerja na riti
	if vision_ray_rear.is_colliding() and vision_ray_rear.get_collider().is_in_group(Config.group_bolts):
#		shooting("shocker")
		shocker_released = true
	

func set_target_location (target: Vector2):
	target_reached = false
	navigation_agent.set_target_location(target)


func on_misile_destroyed(): # iz signala
	misile_reloaded = true	
	

func _on_NavigationAgent2D_path_changed() -> void:
	
#	emit_signal("path_changed", navigation_agent.get_nav_path()) # pošljemo točke poti do cilja
	Signals.emit_signal("path_changed", navigation_agent.get_nav_path()) # pošljemo točke poti do cilja
	
	
#func steering(delta: float) -> void:
#
#	var rear_axis_position = position - transform.x * axis_distance / 2.0 # sredinska pozicija vozila minus polovica medosne razdalje
#	var front_axis_position = position + transform.x * axis_distance / 2.0 # sredinska pozicija vozila plus polovica medosne razdalje
#
#	# sprememba lokacije osi ob gibanju (per frame)
#	rear_axis_position += velocity * delta	
#	front_axis_position += velocity.rotated(rotation_angle) * delta
#
#	var new_heading = (front_axis_position - rear_axis_position).normalized()
#
#	if velocity.length() > 0:
#		velocity = velocity.linear_interpolate(new_heading * velocity.length(), side_traction / 10) # željeno smer gibanja doseže z zamikom "side-traction"	
#	elif velocity.length() < 0:
#		velocity = velocity.linear_interpolate(-new_heading * min(velocity.length(), top_speed_reverse), 0.5) # željeno smer gibanja doseže z zamikom "side-traction"	
#
#	rotation = new_heading.angle() # sprite se obrne v smeri


	
#func on_collision():
#
#	velocity = velocity.bounce(collision.normal) * bounce_size # gibanje pomnožimo z bounce vektorjem normale od objekta kolizije
#
#	# odbojni partikli
#	if velocity.length() > 10: # ta omenitev je zato, da ne prši, ko si fiksiran v steno
#		var new_collision_particles = CollisionParticles.instance()
#		new_collision_particles.position = collision.position
#		new_collision_particles.rotation = collision.normal.angle() # rotacija partiklov glede na normalo površine 
#		new_collision_particles.amount = velocity.length()/15 # količnik je korektor	
#		new_collision_particles.color = player_color
#		new_collision_particles.set_emitting(true)
#		Global.effects_creation_parent.add_child(new_collision_particles)


			
#func engines_setup():
#
#	engine_power = engine_power_idle
#
#	engine_particles_rear = EngineParticles.instance()
#	engine_particles_rear.position = rear_engine_position.global_position
#	engine_particles_rear.rotation = rear_engine_position.global_rotation
#	Global.effects_creation_parent.add_child(engine_particles_rear)
#
#	engine_particles_front_left = EngineParticles.instance()
#	engine_particles_front_left.emission_rect_extents = Vector2.ZERO
#	engine_particles_front_left.amount = 20
#	engine_particles_front_left.initial_velocity = 50
#	engine_particles_front_left.lifetime = 0.05
#	engine_particles_front_left.position = front_engine_position_L.global_position
#	engine_particles_front_left.rotation = front_engine_position_L.global_rotation - deg2rad(180)
#	Global.effects_creation_parent.add_child(engine_particles_front_left)
#
#	engine_particles_front_right = EngineParticles.instance()
#	engine_particles_front_right.emission_rect_extents = Vector2.ZERO
#	engine_particles_front_right.amount = 20
#	engine_particles_front_right.initial_velocity = 50
#	engine_particles_front_right.lifetime = 0.05
#	engine_particles_front_right.position = front_engine_position_R.global_position
#	engine_particles_front_right.rotation = front_engine_position_R.global_rotation - deg2rad(180)	
#	Global.effects_creation_parent.add_child(engine_particles_front_right)
	
#func shooting(weapon) -> void:
#
#	if control_enabled:
#		match weapon:
#			"bullet": 
#				if bullet_reloaded:
#					var new_bullet = Bullet.instance()
#					new_bullet.position = gun_position.global_position
#					new_bullet.rotation = gun_position.global_rotation
#					new_bullet.spawned_by = name # ime avtorja izstrelka
#					new_bullet.spawned_by_color = player_color
#					Global.node_creation_parent.add_child(new_bullet)
#
#					bullet_reloaded = false
#					yield(get_tree().create_timer(new_bullet.reload_time / shooting_ability), "timeout")
#					bullet_reloaded= true	
#
#			"misile": 
#				print ("not")
#				if misile_reloaded and misile_count > 0:	
#					var new_misile = Misile.instance()
#					new_misile.position = gun_position.global_position
#					new_misile.rotation = gun_position.global_rotation
#					new_misile.spawned_by = name # ime avtorja izstrelka
#					new_misile.spawned_by_color = player_color
#					new_misile.spawned_by_speed = velocity.length()
#					Global.node_creation_parent.add_child(new_misile)
#
#					Signals.connect("misile_destroyed", self, "on_misile_destroyed")		
#					misile_reloaded = false
#					misile_count -= 1
#
#			"shocker": 
#				if shocker_reloaded and shocker_count > 0:	
#					var new_shocker = Shocker.instance()
#					new_shocker.rotation = rear_engine_position.global_rotation
#					new_shocker.global_position = rear_engine_position.global_position
#					new_shocker.spawned_by = name # ime avtorja izstrelka
#					new_shocker.spawned_by_color = player_color
#					Global.node_creation_parent.add_child(new_shocker)
#
#					shocker_reloaded = false
#					yield(get_tree().create_timer(new_shocker.reload_time / shooting_ability), "timeout")
#					shocker_reloaded= true	

			
#func activate_shield():	
#
#	if shields_on == false:
#		shield.modulate.a = 1
#		animation_player.play("shield_on")
#		shields_on = true
#		bolt_collision.disabled = true
#		shield_collision.disabled = false
#	else:
#		animation_player.play_backwards("shield_on")
#		# shields_on = false # premaknjeno dol na konec animacije
#		# collisions setup premaknjeno dol na konec animacije
#		shield_loops_counter = shield_loops_limit # imitiram zaključek loop tajmerja


#func on_hit(hit_by: Node):
#
#
#	if not shields_on:
#
#		idle_target_set = false
#
#		# bullet
#		if hit_by.is_in_group(Config.group_bullets):
#
#			# shake camera
#			camera.add_trauma(camera.bullet_hit_shake)
#			# take damage
#			health -= hit_by.hit_damage
#			if health <= 0:
#				die()
##				explode_and_reset()
#				pass
#			# push
##			velocity = hit_by.velocity * bullet_push_factor
#			velocity = velocity.normalized() * inertia + hit_by.velocity.normalized() * hit_by.inertia
##			print("hit velocity")
##			print(velocity.length())
#			# utripne	
#			modulate = Color.red
#			yield(get_tree().create_timer(0.05), "timeout")
#			modulate = Color.white 
#			# disabled
#			var disabled_tween = get_tree().create_tween()
#			disabled_tween.tween_property(self, "velocity", Vector2.ZERO, on_hit_disabled_time) # tajmiram pojemek 
#			yield(disabled_tween, "finished")
#
#			# enable controls
#			control_enabled = true # najprej se uporabi setan target in gre do njega, potem poišče idle target
#			idle_target_set = false
#
#		# misile	
#		elif hit_by.is_in_group(Config.group_misiles):
#			control_enabled = false
#			# shake camera
#			camera.add_trauma(camera.misile_hit_shake)
#			# take damage
#			health -= hit_by.hit_damage
#			if health <= 0:
#				die()
##				explode_and_reset()
#				pass
#			# push
##			velocity = hit_by.velocity * misile_push_factor
#			velocity = velocity.normalized() * inertia + hit_by.velocity.normalized() * hit_by.inertia
##			print("hit velocity")
##			print(velocity.length())
#			# utripne	
#			modulate = Color.red
#			yield(get_tree().create_timer(0.05), "timeout")
#			modulate = Color.white 
#			# disabled
#			var disabled_tween = get_tree().create_tween()
#			disabled_tween.tween_property(self, "velocity", Vector2.ZERO, on_hit_disabled_time) # tajmiram pojemek 
#			yield(disabled_tween, "finished")
#
#			# enable controls
#			control_enabled = true # najprej se uporabi setan target potem poišče idle target
#			idle_target_set = false
#
#		# shocker
#		elif hit_by.is_in_group(Config.group_shockers):
#			control_enabled = false
#
#			var catch_tween = get_tree().create_tween()
#			catch_tween.tween_property(self, "engine_power", 0, 0.1) # izklopim motorje, da se čist neha premikat
#			catch_tween.parallel().tween_property(self, "velocity", Vector2.ZERO, 1.0) # tajmiram pojemek 
#			catch_tween.parallel().tween_property(bolt_sprite, "modulate:a", 0.5, 0.5)
#			bolt_sprite.material.set_shader_param("noise_factor", 2.0)
#			bolt_sprite.material.set_shader_param("speed", 0.7)
#
#			yield(get_tree().create_timer(hit_by.shock_time), "timeout")
#
#			var relase_tween = get_tree().create_tween()
#			relase_tween.tween_property(self, "engine_power", engine_power_idle, 0.1)
#			relase_tween.parallel().tween_property(bolt_sprite, "modulate:a", 1.0, 0.5)				
#			yield(relase_tween, "finished")
#
#			bolt_sprite.material.set_shader_param("noise_factor", 0.0)
#			bolt_sprite.material.set_shader_param("speed", 0.0)
#
#			# enable controls
#			control_enabled = true # najprej se uporabi setan target potem poišče idle target


#func die():
#
#	# shake camera
#	camera.add_trauma(camera.bolt_explosion_shake)
#
#	# najprej explodiraj 
#	# potem ugasni sprite in coll 
#	# potem ugasni motor in štartaj trail decay
#	# explozijo izključi ko grejo partikli ven
#	var new_exploding_bolt = ExplodingBolt.instance()
#	new_exploding_bolt.global_position = global_position
#	new_exploding_bolt.global_rotation = bolt_sprite.global_rotation
#	new_exploding_bolt.modulate = modulate
#	new_exploding_bolt.modulate.a = 1
#	new_exploding_bolt.velocity = velocity # podamo hitrost, da se premika s hitrostjo bolta
#	Global.node_creation_parent.add_child(new_exploding_bolt)
#
#	queue_free()		


#
#func _on_shield_animation_finished(anim_name: String) -> void:
#
#	shield_loops_counter += 1
#
#	match anim_name:
#		"shield_on":	
#			# končan outro ... resetiramo lupe in ustavimo animacijo
#			if shield_loops_counter > shield_loops_limit:
#				animation_player.stop(false) # včasih sem rabil, da se ne cikla, zdaj pa je okej, ker ob
#				shield_loops_counter = 0
#				shields_on = false
#				bolt_collision.disabled = false
#				shield_collision.disabled = true
#			# končan intro ... zaženi prvi loop
#			else:
#				animation_player.play("shielding")
#		"shielding":
#			# dokler je loop manjši od limita ... replayamo animacijo
#			if shield_loops_counter < shield_loops_limit:
#				animation_player.play("shielding") # animacija ni naštimana na loop, ker se potem ne kliče po vsakem loopu
#			# konec loopa, ko je limit dosežen
#			elif shield_loops_counter >= shield_loops_limit:
#				animation_player.play_backwards("shield_on")


# _temp --------------------------------------------------------------

#
#func explode_and_reset(): 
#
#	# shake camera
#	camera.add_trauma(camera.bolt_explosion_shake)
#
#	if visible == true:
#		var new_exploding_bolt = ExplodingBolt.instance()
#		new_exploding_bolt.global_position = global_position
#		new_exploding_bolt.global_rotation = bolt_sprite.global_rotation
#		new_exploding_bolt.spawned_by_color = player_color
#		new_exploding_bolt.velocity = velocity # podamo hitrost, da se premika s hitrostjo bolta
#		Global.node_creation_parent.add_child(new_exploding_bolt)
#		visible = false
#	else:
#		visible = true
#
#
