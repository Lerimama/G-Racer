extends Polygon2D


export var rand_color = false
export var shard_count: int = 2

export var shard_gravity_factor: float = 0
export var shard_speed_factor: float = 20.0
export var shard_rotation_factor: float = 0.1

var texture_width = texture.get_width()
var texture_height = texture.get_height()


var shard_direction_map = {} # slovar za shranjevanje pozicije sredine trikotnika glede na center spriteta
# ključ se polne s trikotnikom na katerem smo (v loopu)
# ključ je podatek o lokaciji sredinske točke trikotnika
# ključ izračunam s povprečjem vseh treh točk (vec2)
func _ready() -> void:
	
	randomize()
	
	pass

func _input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("space"):
		explode()
	if Input.is_action_just_pressed("pavza"):
		reset()

func _process(delta: float) -> void:
	
	for child in shard_direction_map.keys():
		child.position -= shard_direction_map[child] * delta * shard_speed_factor
		child.rotation -= shard_direction_map[child].y * delta * shard_rotation_factor
		# apply gravity 
		shard_direction_map[child].x -= delta * shard_gravity_factor 
		
		
func explode():
	
	# zabeležimo točke v trenutnem poligonu (vec2 pozicija)
	var points = polygon
	
	# dodamo xtra točke
	for i in range(shard_count):
		points.append(Vector2(randi()%texture_width, randi()%texture_height)) # random vrednost znotraj velikosti texture
		print(points)
		# randi()           # Returns random integer between 0 and 2^32 - 1
		# randi() % 20      # Returns random integer between 0 and 19
		# randi() % 100     # Returns random integer between 0 and 99
		# randi() % 100 + 1 # Returns random integer between 1 and 100

	var texture_center = Vector2(texture_width/2, texture_height/2)
	
	# trianguliraj
	var delaunay_points = Geometry.triangulate_delaunay_2d(points)
	
	if not delaunay_points:
		print ("error ... ni poligona") # ček for exsists
	
	# pull list of points in all triangles
	# za vsak prisoten trikotnik, gremo čez vse točke v trikotniku in jih dodamo v shard_pool
	# loop over each returned triangle
	for index in len(delaunay_points) / 3: 
		# Length is the character count of String, element count of Array, size of Dictionary, etc.
		# ker so v trikotniku 3 točke, vse točke delimo s 3, da dobimo št. trikotnikov
		
		var shard_pool = PoolVector2Array() # točke trikotnika
		var shard_center = Vector2.ZERO # treutno je še prazen
		
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
			shard.color =  Color (randf(), randf(), randf(), 1)
			shard.position.y += (index + 1) * - texture_width
		else:
			shard.texture = texture
		
		shard_direction_map[shard] = texture_center - shard_center # pozicijo trenutnega trikotnika odštejemo od poz centra teksture
		
		add_child(shard)
	
	# base sprite alfa 0
	color.a = 0 

	
func reset():
	color.a = 1
	for child in get_children():
		if child.name != "Camera2D":
			remove_child(child)
