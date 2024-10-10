extends Node2D

enum POSITION {LEFT, RIGHT, FRONT, REAR}
export (POSITION) var position_on_bolt: int = 0
#export var owner_node_path: String = 
onready var owner_node: Node2D = owner.owner

var thrust_active: bool = false
var bolt_trail_alpha = 0.05
var trail_pseudodecay_color = Color.white
var pseudo_stop_speed: = 15.0
var active_trail: Line2D

# particles
var thrust_particles_name: String = "ThrustParticles"
var thrust_over_particles_name: String = "ThrustOverParticles"
var smoke_particles_name: String = "SmokeParticles"

onready var disp: Node2D = self

func _ready() -> void:
	
	match position_on_bolt:
		POSITION.LEFT:
			scale.y = 1
		POSITION.RIGHT:
			scale.y = -1
			

func _process(delta: float) -> void:
	
	if owner_node:
		$Polygon2D.color = owner_node.bolt_color
		update_trail()
	
# particles
	
func start_fx(only_one_shot: bool = false, reverse_direction: bool = false):
	
	if not thrust_active:
		thrust_active = true
		#		disp.get_node(thrust_particles_name).one_shot = only_one_shot
		#		disp.get_node(thrust_over_particles_name).emitting = only_one_shot
		#		disp.get_node(smoke_particles_name).emitting = only_one_shot
		disp.get_node(thrust_particles_name).emitting = true
		disp.get_node(thrust_over_particles_name).emitting = true
		disp.get_node(smoke_particles_name).emitting = true


func stop_fx():
	
	if thrust_active:
		thrust_active = false
		disp.get_node(thrust_particles_name).emitting = false
		disp.get_node(thrust_over_particles_name).emitting = false
		disp.get_node(smoke_particles_name).emitting = false
		

# trail	
	
func spawn_new_trail():
	
	var BoltTrail: PackedScene = preload("res://game/bolt/fx/ThrustTrail.tscn")
	var new_trail: Line2D = BoltTrail.instance()
	# na poziciji partiklov na trenutno izbrani strani
	new_trail.global_position = disp.get_node(thrust_particles_name).global_position
	new_trail.modulate.a = bolt_trail_alpha
	new_trail.width = 5
	Ref.node_creation_parent.add_child(new_trail)
	
	# signal za deaktivacijo, če ni bila že prej
	new_trail.connect("trail_is_exiting", self, "_on_trail_exiting")
	
	return new_trail		
	
	
func update_trail():
	
	# spawn trail if not active
	if not active_trail and owner_node.bolt_velocity.length() > pseudo_stop_speed: # če ne dodam hitrosti, se mi v primeru trka ob steno začnejo noro množiti
		active_trail = spawn_new_trail() # aktivira se ob spawnu
	elif active_trail and owner_node.bolt_velocity.length() > pseudo_stop_speed:
		# start hiding trail + add trail points ... ob ponovnem premiku se ista spet pokaže
		active_trail.add_points(global_position)
		active_trail.gradient.colors[1] = trail_pseudodecay_color
		if owner_node.bolt_velocity.length() > pseudo_stop_speed and active_trail.modulate.a < bolt_trail_alpha:
			# če se premikam in se je tril že začel skrivat ga prikažem
			var trail_grad = get_tree().create_tween()
			trail_grad.tween_property(active_trail, "modulate:a", bolt_trail_alpha, 0.5)
		else:
			# če grem počasi ga skrijem
			var trail_grad = get_tree().create_tween()
			trail_grad.tween_property(active_trail, "modulate:a", 0, 0.5)
	# če sem pri mirua deaktiviram trail ... ob ponovnem premiku se kreira nova 
	elif active_trail and owner_node.bolt_velocity.length() <= pseudo_stop_speed:
		active_trail.start_decay() # trail decay tween start
		active_trail = null # postane neaktivna, a je še vedno prisotna ... queue_free je šele na koncu decay tweena


func _on_trail_exiting(exiting_trail: Line2D):
	
	if exiting_trail == active_trail:
		active_trail = null


func _exit_tree() -> void: # OPT v vse traile
	
	if active_trail and not active_trail.in_decay:
		active_trail.start_decay()
