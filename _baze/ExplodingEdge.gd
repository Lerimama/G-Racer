extends Polygon2D


export var add_points_count: int = 14 # 0 = poligon ima samo vogale ... dva fragmenta
export var fragment_speed: Array = [12, 15]
export var fragment_rotation: float = 0.5 # negativno je v smeri urinega kazalca
export var fragment_decay_speed: float = 0.5 # večja je, hitreje je
export var fragment_scale: float = 1.0

var explode_center = Vector2(0.5, 0.5)
var per_fragment_points = 3 # trikotnik pač
var fragment_direction_map = {} # slovar  za shranjevanje pozicije sredine trikotnika glede na center spriteta

var texture_width = texture.get_width()
var texture_height = texture.get_height()


func _ready() -> void:
	randomize()
	triangulate_polygon()
	
		
func _process(delta: float) -> void:
	
	if polygon: 
		# explode
		for frag in fragment_direction_map.keys():
			
			frag.position -= fragment_direction_map[frag] * delta * rand_range(fragment_speed[0], fragment_speed[1])
			frag.rotation -= fragment_direction_map[frag].y * delta * fragment_rotation  # y je za variacijo rotacije glede na fragment
			frag.scale -= Vector2.ONE * delta * fragment_decay_speed
			
			if frag.scale <= Vector2.ZERO:
				queue_free()
				
				
func triangulate_polygon():
	
	# definicija poligona
	var polygon_points = polygon # array s točkami v trenutnem poligonu (vec2 pozicija)
	
	# fragmentiranje ... dodajanje točk znotraj poligona
	for point in range(add_points_count):
		var random_x = randi() % texture_width
		var random_y = randi() % texture_height
		var random_point: Vector2 = Vector2(random_x, random_y)
		polygon_points.append(random_point)
		
	# triangulacija ... vlečenje robov med točkami
	var texture_center = Vector2(texture_width * explode_center.x, texture_height * explode_center.y) # center explozije preračunan v pixle
	var triangulate_points = Geometry.triangulate_delaunay_2d(polygon_points) # array s točkami triangulacije
	
	# število trikotnikov
	var triangulate_points_count: int = len(triangulate_points)
	var fragment_count: int = triangulate_points_count / per_fragment_points
	
	# fragment
	for fragment in fragment_count: # triangl dobi index trikotnika na katerem smo
		
		# koordinate točk trenutnega trikotnika
		var fragment_points = PoolVector2Array() # vec2 array ... je še prazen
		var fragment_center = Vector2.ZERO # je še default vrednosti
		for point in range(per_fragment_points):
			var current_point: Vector2 = polygon_points[triangulate_points[(fragment * per_fragment_points) + point]] # predelimo trenutno točko trenutnega trikotnika
			fragment_points.append(current_point) # točko dodamo v array točk trenutnega trikotnika
			fragment_center += current_point # vec2 centru prištejemo vec2 lokacijo pike ... potem delim s št. točk
		
		# center trenutnega trikotnika
		fragment_center = fragment_center / per_fragment_points
		
		# vizualizacija trenutnega trikotnika		
		var fragment_polygon = Polygon2D.new()
		fragment_polygon.polygon = fragment_points # točke fragmenta so točke trikotnika
		fragment_polygon.texture = texture # tekstura fragmenta je tekstura original poligona 
		fragment_polygon.scale = Vector2(fragment_scale, fragment_scale)
		fragment_direction_map[fragment_polygon] = texture_center - fragment_center # smer gibanja trikotnika od centra teksture proti centru trikotnika
		
		add_child(fragment_polygon)
	
	color.a = 0 
