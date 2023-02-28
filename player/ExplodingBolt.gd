extends Polygon2D


export var rand_color = false
export var shard_count: int = 5

export var shard_gravity_factor: float = 0
#export var shard_speed_factor: float = 200.0
#export var shard_rotation_factor: float = 0.1

var shard_speed_random: Array = [20, 30] # če je eksplozija je hitro, če razpade je počasno
var shard_rotation_random: Array = [0.5, 1.0]


var texture_width: int = texture.get_width()
var texture_height: int = texture.get_height()

var shard_direction_map = {} # slovar za shranjevanje pozicije sredine trikotnika glede na center spriteta
				# ključ se polne s trikotnikom na katerem smo (v loopu)
				# ključ je podatek o lokaciji sredinske točke trikotnika
				# ključ izračunam s povprečjem vseh treh točk (vec2)

var shard_scale: Vector2 = Vector2(1, 1)
var shard_decay_random_time: Array = [1.0, 2.0] # najvišja vrednost je tudi za queue timer
var decay_time: float = 2.0

var velocity: Vector2

onready var decay_timer: Timer = $Timer
onready var debris_particles: CPUParticles2D = $DebrisParticles
onready var explosion_particles: Particles2D = $ExplosionParticles

var decay_done: bool = false # za preverjanje ali je stvar že končana (usklajeno med partilci in shardi


func _ready() -> void:
	
	randomize()
	debris_particles.set_emitting(true)
	explosion_particles.set_emitting(true)
	# "kulski zamik razpada rakete
	yield(get_tree().create_timer(0.2), "timeout")
	explode()


func _process(delta: float) -> void:
	
	global_position += velocity/2 * delta
	
	# pojemek
	velocity *= 0.9985 
	
	# dodaj hitrost vsakemu od trikotnikov (kolikor je ključev)
	for child in shard_direction_map.keys():
		
#		child.position -= shard_direction_map[child] * delta * shard_speed_factor
#		child.rotation -= shard_direction_map[child].y * delta * shard_rotation_factor
#		
		# gravity 
#		shard_direction_map[child].x -= delta * shard_gravity_factor # tukaj grejo vsi trikotniki istočasno dol
		
		# random
#		randomize()
		child.position -= shard_direction_map[child] * delta * 10#* rand_range(shard_speed_random[0], shard_speed_random[1])
#		child.rotation -= shard_direction_map[child].y * delta * rand_range(shard_rotation_random[0], shard_rotation_random[1])
		child.scale.x -= delta #* rand_range(shard_decay_random_time[0], shard_decay_random_time[1])
		child.scale.y -= delta #* rand_range(shard_decay_random_time[0], shard_decay_random_time[1])
		child.scale.x = clamp(child.scale.x, 0.0, 1.2)
		child.scale.y = clamp(child.scale.y, 0.0, 1.2)
		
		
func explode():

		
	# zabeležimo točke v trenutnem poligonu (vec2 pozicija)
	var points = polygon
	
	# dodamo xtra točke
	for i in range(shard_count):
		points.append(Vector2(randi()%texture_width, randi()%texture_height)) # random vrednost znotraj velikosti texture
		# randi()           # Returns random integer between 0 and 2^32 - 1
		# randi() % 20      # Returns random integer between 0 and 19
		# randi() % 100     # Returns random integer between 0 and 99
		# randi() % 100 + 1 # Returns random integer between 1 and 100
	
	var delaunay_points = Geometry.triangulate_delaunay_2d(points)
	

	var texture_center = Vector2(texture_width/2, texture_height/2)
	
	if not delaunay_points:
		print ("error ... ni poligona")# ček for exsists
	
	# pull list of points in all triangles
	
	# za vsak prisoten trikotnik, gremo čez vse točke v trikotniku in jih dodamo v shard_pool
	# loop over each returned triangle
	for index in len(delaunay_points) / 3: 
		# Length is the character count of String, element count of Array, size of Dictionary, etc.
		# ker so v trikotniku 3 točke, vse točke delimo s 3, da dobimo št. trikotnikov
		
		var shard_pool = PoolVector2Array() # točke trikotnika
		var shard_center = Vector2.ZERO # trenutno je še prazen
		
		# index je index trikotnika na katerem smo (0, 3, 6, ...)
		
		# branje točk trenutnega trikotnika
		for p in range(3): # p je index pik v trenutnem trikotniku (0,1,2) ,(3,4,5), ... 3 je št. točk v trikotniku
			shard_pool.append(points[delaunay_points[(index * 3) + p]]) # v pool dodamo vec 2točke trenutnega trikotnika (točko po točko)
			shard_center += points[delaunay_points[(index * 3) + p]] # z vsakim frejmom prištejemo vec2 lokacijo pike (točko po točko)
		
		shard_center /= 3  # za vsak trikotnik ... shard_center / 3
			
		# kopirajmo trikotnik (spawn)
		var shard = Polygon2D.new() # ustvarimo nov polygon ...
		
		shard.polygon = shard_pool # ... in mu dodamo točke trenutnega trikotnika (točko po točko)
		
		if rand_color == true: # za debuging
			shard.color = Color (randf(), randf(), randf(), 1)
			shard.position.y += (index + 1) * - texture_width
		else:
			shard.texture = texture
			shard.scale = shard_scale
					
		shard_direction_map[shard] = texture_center - shard_center # pozicijo trenutnega trikotnika odštejemo od poz centra teksture
		
		add_child(shard)
	 
		
	# fejk štoparica za queue free		
	decay_timer.wait_time = shard_decay_random_time[1] # uporabimo najvišjo možno vrednost
	decay_timer.start()
	
	
	# base sprite alfa 0
	color.a = 0 

	
func reset():
	color.a = 1
	for child in get_children():
		remove_child(child)


func _on_Timer_timeout() -> void:
	print ("KONEC------------------------	")
	
#	print ("KUFRI - Exploding Bolt")
	queue_free()
