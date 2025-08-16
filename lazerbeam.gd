extends Area2D

@export var speed: float = 1200.0
@export var length: float = 100.0
@export var height: float = 10.0
@export var color: Color = Color(1, 0, 0, 0.75)

func _ready():
    var img = Image.create(int(length), int(height), false, Image.FORMAT_RGBA8)
    img.fill(color)
    var tex = ImageTexture.create_from_image(img)
    $Sprite2D.texture = tex
    $Sprite2D.modulate = Color(1, 1, 1, 1) # No extra tint
    $CollisionShape2D.shape.extents = Vector2(length / 2, height / 2)
    $Sprite2D.scale = Vector2(1, 1) # No scaling needed

func _process(delta):
    position.x -= speed * delta
    if position.x < -length:
        queue_free()