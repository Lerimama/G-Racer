
extends ViewportContainer


### koda resiza kamero glede na št igralcev ... se mi zdi
### trenutno ne delas nič ... bomo videli ko bo več igralcev

var player_id:int setget update_camera # vsakič ko se plejer id zamenja apdejta kamero
var viewport_id


onready var tex : ImageTexture = ImageTexture.new()

func _ready() -> void:
	
	add_to_group("VP")
	pass




func get_viewport_as_texture():
# trenutno ne uporabljam

	# This gives us the ViewportTexture.
	var rtt = get_viewport().get_texture()
	var img = get_viewport().get_texture().get_data()
	$ViewCanvasSprite.texture = rtt
	# Wait until the frame has finished before getting the texture.
	yield(VisualServer, "frame_post_draw")
	# You can also set "V Flip" to true if not on the root Viewport.
	img.flip_y()
	# Set Sprite Texture.
	tex = ImageTexture.new()
	# Convert Image to ImageTexture.
	tex.create_from_image(img)
	# Set Sprite Texture.
	$ViewCanvasSprite.texture = tex
#	$Sprite.texture = tex.draw(img, Vector2.ZERO, Color.red)


func _process(delta: float) -> void:

#	get_viewport_as_texture()

	pass
	
func update_camera(id):
	
	
	var target_id
	
	match id:
		1:
			$Viewport/Camera2D.target = $Viewport/Arena.Player_1
		2:
			$Viewport/Camera2D.target = $Viewport/Arena.Player_2
	
