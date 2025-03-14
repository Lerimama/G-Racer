extends RigidBody2D


var ball_is_active: bool = true
enum MOTION {LEFT, RIGHT, UP, DOWN}

var side_power: float = 0
var fwd_power: float = 0
var power_limit: float = 5000
var power_add: float = 1000

var controlling_force: Vector2
var velocity: Vector2
var velocity_multiplier: float = 0.1
var body_state: Physics2DDirectBodyState
onready var collision_shape: CollisionShape2D = $CollisionShape2D
onready var polygon_circo_2d: Polygon2D = $PolygonCirco2D
onready var influence_area: Area2D = $InfluenceArea

# neu
var direction: Vector2
enum TYPE {KNIFE, HAMMER, PAINT, EXPLODING} # enako kot breaker
var damage_type = TYPE.HAMMER


func _input(event: InputEvent) -> void:

	if ball_is_active:
		if Input.is_action_pressed("p1_fwd"):
			fwd_power += power_add
		elif Input.is_action_pressed("p1_rev"):
			fwd_power -= power_add
		else:
			fwd_power = 0

		if Input.is_action_pressed("p1_left"):
			side_power -= power_add
		elif Input.is_action_pressed("p1_right"):
			side_power += power_add
		else:
			side_power = 0
		side_power = clamp(side_power, - power_limit, power_limit)
		fwd_power = clamp(fwd_power, - power_limit, power_limit)

func _ready() -> void:
	pass

func _process(delta: float) -> void:

	direction = velocity.normalized()

func _integrate_forces(state: Physics2DDirectBodyState) -> void:

	body_state = state
	controlling_force = Vector2.RIGHT * side_power + Vector2.UP * fwd_power
	set_applied_force(controlling_force)
	velocity = state.get_linear_velocity()

func _on_Ball_body_entered(body: Node) -> void:

	if body.has_method("on_hit"):
		var collision_position: Vector2 = body_state.get_contact_collider_position(0)
		collision_position = position # OPT ... bolj natančen vektor
		var force_position: Vector2 = collision_position - velocity * velocity_multiplier
#		Mets.spawn_indikator(collision_position, Color.blue)
#		Mets.spawn_indikator(force_position, Color.red)
		modulate = Color.red
		body.modulate = Color.red
		var blend_tween = get_tree().create_tween()
		blend_tween.tween_property(self, "modulate", Color.white, 0.3)
		blend_tween.parallel().tween_property(body, "modulate", Color.white, 0.2)

		body.on_hit(self, position)


