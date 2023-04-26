
-> error remover line

# IMPLEMENTACIJA KONTROL V PLEJERJA ----------------------------------------------------------

# ready

# za vsako ime akcije v profilu
for action_name in controller_profile.keys():
	# ustvarim akcijo s ključem iz slovarja
	InputMap.add_action(action_name)
	# ustvarim prazno tipko, ki ji bomo pripisali skenkodo tipke
	var action_key = InputEventKey.new()
	# tipki dodam skenkodo
	action_key.scancode = controller_profile[action_name]
	InputMap.action_add_event(action_name, action_key)

# input
if control_enabled:
	input_power = Input.get_action_strength(Profiles.fwd_action) - Input.get_action_strength(Profiles.rev_action) # +1, -1 ali 0
	rotation_dir = Input.get_axis(Profiles.left_action, Profiles.right_action) # +1, -1 ali 0	

	if Input.is_action_just_pressed(Profiles.shoot_bullet_action):
		shooting("Bullet")
	if Input.is_action_just_released(Profiles.shoot_misile_action):	
		shooting("Misile")
	if Input.is_action_just_released(Profiles.shoot_shocker_action):	
		shooting("Shocker")
	if Input.is_action_just_pressed("x"):
		explode_and_reset()
	if Input.is_action_just_pressed("shift"):
		shooting("Shield")

# BOUNCE ---------------------------------------------------------------------------------------

velocity = velocity.bounce(collision.normal) * bounce_size # gibanje pomnožimo z bounce vektorjem normale od objekta kolizije
bounce_angle = collision.normal.angle_to(velocity)	


# RIGID BODY KOZIJA -------------------------------------------------------------------------------------

if collision.collider.is_class("RigidBody2D"):

	# vztrajnost telesa
	var collider_mass: float = collision.collider.get("mass")
	var collider_velocity: Vector2 = collision.collider.get("linear_velocity")
	var collider_inertia: Vector2 = collider_velocity * collider_mass

	# vztrajnost plejerja
	var player_inertia: Vector2 = velocity * mass
	collision.collider.apply_central_impulse(-collision.normal * player_inertia) # odboj telesa glede na inercijo
	velocity = velocity + collider_inertia # odboj plejerja



# DROP SHADOW -------------------------------------------------------------------------------------


#func _draw():

	var shadow_position: Vector2 = Vector2(-1,2)
	shadow_position = global_position - light_position

	draw_set_transform(shadow_position, deg2rad(90), Vector2.ONE)
	draw_texture(sprite_texture, sprite_center, Color( 0, 0, 0, 0.2 ))
	print (global_rotation)
	
	
verzija s kopiranjem nodetove maskel-----

onready var main_sprite : Sprite = get_parent()
var shadow_dir : Vector2
export var num_shadow_sprites = 2
var shadow_sprite = preload("res://ShadowSprite.tscn")

export var shadow_start_color = Color.black
export var shadow_end_color = Color(0, 0, 0, 0)

func _ready():
	for i in range(num_shadow_sprites):
		var sprite : Sprite = shadow_sprite.instance()
		sprite.texture = main_sprite.texture
		sprite.hframes = main_sprite.hframes
		sprite.vframes = main_sprite.vframes
		add_child(sprite)

func _process(_delta):
	shadow_dir = get_viewport().size / 2.0 - get_global_mouse_position()
	
	for i in range(num_shadow_sprites):
		var sprite : Sprite = get_child(i)
		var t = (i + 1.0) / num_shadow_sprites
		sprite.modulate = shadow_start_color.linear_interpolate(shadow_end_color, t)
		sprite.position = shadow_dir * t
		sprite.frame = main_sprite.frame
		

	
# TRAIL -------------------------------------------------------------------------------------	

func new_trail():

	var bolt_trail = Bolt_trail.instance()
	bolt_trail.position = global_position
	bolt_trail.rotation = global_rotation
	add_child(bolt_trail)
	bolt_trail.add_point(global_position, -1)

	print(bolt_trail.get_point_count() )

		if Input.is_action_just_pressed("ui_up"):
			var bolt_trail = Bolt_trail.instance()
			bolt_trail.position = Vector2(100,100)
			bolt_trail.rotation = global_rotation
			add_child(bolt_trail)

			bolt_trail.add_points(global_position)
			bolt_trail.add_point(global_position, -1)
			print("get_point_count()" )
		print(bolt_trail.get_point_count() )

			var bolt_trail = Bolt_trail.instance()
			bolt_trail.position = global_position
			bolt_trail.rotation = global_rotation
			add_child(bolt_trail)

			bolt_trail.add_point(global_position, -1)
			print("get_point_count()" )
			print(bolt_trail.get_point_count() )

	
# SCREEN WRAP NODE -------------------------------------------------------------------------	

func wrap():
	if position.x < 0:
		position.x = velikost_ekrana.x
	if position.x > velikost_ekrana.x:
		position.x = 0
	if position.y < 0:
		position.y = velikost_ekrana.y
	if position.y > velikost_ekrana.y:
		position.y = 0
