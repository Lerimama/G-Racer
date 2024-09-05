extends Node2D

	
var bolt_trail_alpha = 0.05
var trail_pseudodecay_color = Color.white
var active_trail: Line2D

onready var thrust_particles: Particles2D = $ThrustParticles
var pseudo_stop_speed: = 15.0
#var bolt_velocity: Vector2



func _ready() -> void:
	
	thrust_particles.emitting = false


func _process(delta: float) -> void:
	
	update_trail()
	
	
func start_fx(reverse_direction: bool = false):
	
	thrust_particles.emitting = true
	
	if reverse_direction:
		thrust_particles.get_process_material().direction.x = 1
	else:
		thrust_particles.get_process_material().direction.x = -1


func stop_fx():
	
	thrust_particles.emitting = false

		
func spawn_new_trail():
	
	var BoltTrail: PackedScene = preload("res://game/bolt/fx/ThrustTrail.tscn")
	var new_trail: Line2D = BoltTrail.instance()
	new_trail.modulate.a = bolt_trail_alpha
	new_trail.z_index = z_index + Set.trail_z_index
	new_trail.width = 5
	Ref.node_creation_parent.add_child(new_trail)
	
	# signal za deaktivacijo, če ni bila že prej
	new_trail.connect("trail_is_exiting", self, "_on_trail_exiting")
	
	return new_trail		
	
	
func update_trail():
	
	# spawn trail if not active
	if not active_trail and owner.bolt_velocity.length() > pseudo_stop_speed: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
		active_trail = spawn_new_trail() # aktivira se ob spawnu
	elif active_trail and owner.bolt_velocity.length() > pseudo_stop_speed:
		# start hiding trail + add trail points ... ob ponovnem premiku se ista spet pokaže
		active_trail.add_points(global_position)
		active_trail.gradient.colors[1] = trail_pseudodecay_color
		if owner.bolt_velocity.length() > pseudo_stop_speed and active_trail.modulate.a < bolt_trail_alpha:
			# če se premikam in se je tril že začel skrivat ga prikažem
			var trail_grad = get_tree().create_tween()
			trail_grad.tween_property(active_trail, "modulate:a", bolt_trail_alpha, 0.5)
		else:
			# če grem počasi ga skrijem
			var trail_grad = get_tree().create_tween()
			trail_grad.tween_property(active_trail, "modulate:a", 0, 0.5)
	# če sem pri mirua deaktiviram trail ... ob ponovnem premiku se kreira nova 
	elif active_trail and owner.bolt_velocity.length() <= pseudo_stop_speed:
		active_trail.start_decay() # trail decay tween start
		active_trail = null # postane neaktivna, a je še vedno prisotna ... queue_free je šele na koncu decay tweena


func _on_trail_exiting(exiting_trail: Line2D):
	
	if exiting_trail == active_trail:
		active_trail = null
