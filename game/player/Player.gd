extends Bolt
class_name Player


var player_name: String # za opredelitev statistike
var controller_profile: Dictionary

onready var player_profile: Dictionary = Pro.default_player_profiles[bolt_id]
onready var controller_profiles: Dictionary = Pro.default_controller_actions
onready var controller_profile_name: String = player_profile["controller_profile"]
onready var controller_actions: Dictionary = controller_profiles[controller_profile_name]

onready var fwd_action: String = controller_actions["fwd_action"]
onready var rev_action: String = controller_actions["rev_action"]
onready var left_action: String = controller_actions["left_action"]
onready var right_action: String = controller_actions["right_action"]
onready var shoot_bullet_action: String = controller_actions["shoot_bullet_action"]
onready var shoot_misile_action: String = controller_actions["shoot_misile_action"]
onready var shoot_shocker_action: String = controller_actions["shoot_shocker_action"]
onready var select_feat_action: String = controller_actions["select_feat_action"]
	
	
func _input(event: InputEvent) -> void:
	
	if not bolt_active:
		return
	
	if Input.is_action_just_pressed("f"):
		on_item_picked("BULLET")
	# move
	if Input.is_action_pressed(fwd_action):
		engine_power = fwd_engine_power
	elif Input.is_action_pressed(rev_action):
		engine_power = - rev_engine_power
	else:			
		engine_power = 0
	
	# rotation
	rotation_dir = Input.get_axis(left_action, right_action) # +1, -1 ali 0
	# rotation_angle se računa na inputu ... rotation_dir * deg2rad(turn_angle)
	
	# shooting
	if Input.is_action_just_pressed(select_feat_action):
		select_feature()
#		shooting("bullet")
	if Input.is_action_just_pressed(shoot_bullet_action):
		shooting("bullet")
	if Input.is_action_just_released(shoot_misile_action):	
		shooting("misile")
	if Input.is_action_just_released(shoot_shocker_action):	
		shooting("shocker")
	if Input.is_action_just_released("pavza"):	
		shield_loops_limit = Pro.bolt_profiles[bolt_type]["shield_loops_limit"] 
		activate_shield()


func _ready() -> void:
	
	add_to_group(Ref.group_players)
	
	# player setup
	player_name = player_profile["player_name"]
	bolt_color = player_profile["player_color"]
	bolt_sprite.modulate = bolt_color
	
	feat_selector.modulate.a = feat_selector_alpha

	
	

var feat_selector_alpha: float = 0.3			
onready var feat_selector: Node2D = $FeatSelector
onready var feat_selected: int = 0


func update_feature_selector():
	
	# postavitev
	feat_selector.rotation = -rotation # negiramo rotacijo bolta, da je pri miru
	feat_selector.global_position = global_position + Vector2(0, 8) # negiramo rotacijo bolta, da je pri miru
	
	# features na voljo?
	if bullet_count <= 0:
		available_features.erase(feat_selector.get_node("Icons/IconBullet"))
	elif not available_features.has(feat_selector.get_node("Icons/IconBullet")):
		available_features.append(feat_selector.get_node("Icons/IconBullet"))
		feat_selector.get_node("Icons/IconBullet").show()
	if misile_count <= 0:
		available_features.erase(feat_selector.get_node("Icons/IconMisile"))
		feat_selector.get_node("Icons/IconMisile").hide()
#		feat_selector.get_node("Icons/IconShocker").show()
	elif not available_features.has(feat_selector.get_node("Icons/IconMisile")):
		available_features.append(feat_selector.get_node("Icons/IconMisile"))
#		feat_selector.get_node("Icons/IconMisile").show()
	if shocker_count <= 0:
		available_features.erase(feat_selector.get_node("Icons/IconShocker"))
		feat_selector.get_node("Icons/IconBullet").hide()
	elif not available_features.has(feat_selector.get_node("Icons/IconShocker")):
		available_features.append(feat_selector.get_node("Icons/IconShocker"))
#		feat_selector.get_node("Icons/IconShocker").show()
	
	for feat in feat_selector.get_node("Icons").get_children():
		if not available_features.has(feat):
			feat.hide()
			if not available_features.empty():
				var feat_to_show = available_features[available_features.find(feat) + 1]
				feat_to_show.show()
#		else:	

#			feat.show()
		
		

	if available_features.empty():
		feat_selector.hide()
	else:
		feat_selector.show()
				
		
var available_features: Array

func select_feature():
	
	var selector_timer: Timer = $FeatSelector/SelectorTimer
	var selector_visibily_time: float = 1
	selector_timer.wait_time = selector_visibily_time
	selector_timer.start()

	# opredelim tiste, ki so na voljo
#	var available_features: Array = feat_selector.get_node("Icons").get_children()
#	available_features.erase(feat_selector.get_node("Empty"))
#	if bullet_count <= 0:
#		available_features.erase(feat_selector.get_node("Icons/IconBullet"))
#	if misile_count <= 0:
#		available_features.erase(feat_selector.get_node("Icons/IconMisile"))
#	if shocker_count <= 0:
#		available_features.erase(feat_selector.get_node("Icons/IconShocker"))
	
	if not available_features.empty():
#		if feat_selector.modulate.a == 1:
		if feat_selector.visible:
			feat_selected += 1
			if feat_selected > available_features.size() - 1:
				feat_selected = 0
			# setam vidnost ikon
			for feature in available_features:
				if not feature == available_features[feat_selected]:
					feature.hide()
				else:
					feature.show()		
		if feat_selector.modulate.a < 1:
			feat_selector.modulate.a = 1
#			feat_selector.show()

	

func _process(delta: float) -> void:
	
#	if camera_follow:
#		camera.position = position

		
#	if feat_selector.visible:
	update_feature_selector()
	pass
	
func _physics_process(delta: float) -> void:
	
	acceleration = transform.x * engine_power # pospešek je smer (transform.x) z močjo motorja
	if current_motion_state == MotionStates.IDLE: # aplikacija free rotacije
		rotate(delta * rotation_angle * free_rotation_multiplier)


func pull_bolt_on_screen(pull_position: Vector2):
	
	if not bolt_active:
		return
		
#	bolt_collision.disabled = true
#	shield_collision.disabled = true
	
	var pull_time: float = 0.2
	
	# spawn particles
	var pull_tween = get_tree().create_tween()
	pull_tween.tween_property(self, "global_position", pull_position, pull_time).set_ease(Tween.EASE_OUT)
	pull_tween.parallel().tween_property(self, "modulate:a", 0.2, pull_time/2).set_ease(Tween.EASE_OUT)
	pull_tween.parallel().tween_property(self, "modulate:a", 1, pull_time/2).set_delay(pull_time/2).set_ease(Tween.EASE_IN)
#	pull_tween.tween_callback(self.bolt_collision, "set_disabled", [false])
	
	update_gas(Ref.game_manager.game_settings["pull_penalty_gas"])
	
	# ugasnem trail
	if bolt_trail_active:
		current_active_trail.start_decay() # trail decay tween start
		bolt_trail_active = false


func _on_SelectorTimer_timeout() -> void:
	
	feat_selector.modulate.a = feat_selector_alpha
#	feat_selector.hide()
