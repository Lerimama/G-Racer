extends ViewportContainer


### koda resiza kamero glede na št igralcev ... se mi zdi
### trenutno ne delas nič ... bomo videli ko bo več igralcev

var player_id:int setget update_camera # vsakič ko se plejer id zamenja apdejta kamero


#onready var view_port: = preload("res://Viewport.tscn")
var img
onready var tex : ImageTexture = ImageTexture.new()

func _ready() -> void:
	
#	var img = get_viewport().get_texture().get_data()
	# Wait until the frame has finished before getting the texture.
#	yield(VisualServer, "frame_post_draw")

	# This gives us the ViewportTexture.
#	var rtt = get_viewport().get_texture()



##	# Retrieve the captured Image using get_data().
#	img = get_viewport().get_texture().get_data()
##	# Flip on the Y axis.
##	# You can also set "V Flip" to true if not on the root Viewport.
##	img.flip_y()
##	# Convert Image to ImageTexture.
##	tex = ImageTexture.new()
#	tex.create_from_image(img)
#
##	# Set Sprite Texture.
#	$ViewCanvas.texture = tex

	
#	# This gives us the ViewportTexture.
#	var rtt = viewport.get_texture()
##	sprite.texture = rtt
#	$Sprite.texture = rtt
	pass
	
	
func _process(delta: float) -> void:
	
	
	# This gives us the ViewportTexture.
#	var rtt = get_viewport().get_texture()
#	$ViewCanvas.texture = rtt
#
	
#	# Retrieve the captured Image using get_data().
#	img = get_viewport().get_texture().get_data()
#	# Flip on the Y axis.
#	# You can also set "V Flip" to true if not on the root Viewport.
#	img.flip_y()
#	# Convert Image to ImageTexture.
#	var tex = ImageTexture.new()
#	tex.create_from_image(img)
#	# Set Sprite Texture.
#	$ViewCanvas.texture = tex
#	$Sprite.texture = tex.draw(img, Vector2.ZERO, Color.red)
	
	pass
	
func update_camera(id):
	
	
	var target_id
	
	match id:
		1:
			$Viewport/Camera2D.target = $Viewport/Arena.Player_1
		2:
			$Viewport/Camera2D.target = $Viewport/Arena.Player_2
	
