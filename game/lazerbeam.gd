extends Node2D
signal player_touched_lazerbeam

@export var speed: float = 600.0
@export var length: float = 100.0
@export var height: float = 10.0
@export var color: Color = Color(1, 0, 0, 0.75)

@onready var sprite = $Area2D/Sprite2D
@onready var area2d = $Area2D


func _ready():
    var img = Image.create(int(length), int(height), false, Image.FORMAT_RGBA8)
    img.fill(color)
    var tex = ImageTexture.create_from_image(img)
    sprite.texture = tex
    sprite.modulate = Color(1, 1, 1, 1)  # No extra tint
    var collision_shape = get_node("Area2D/CollisionShape2D")
    if collision_shape and collision_shape.shape:
        collision_shape.shape.extents = Vector2(length / 2, height / 2)
    sprite.scale = Vector2(1, 1)  # No scaling needed
    area2d.connect("body_entered", Callable(self, "_on_body_entered"))


func _on_body_entered(body):
    if body.is_in_group("player"):
        print("Player touched lazerbeam!")
        emit_signal("player_touched_lazerbeam", body)


func _process(delta):
    position.x -= speed * delta
    if position.x < -length:
        queue_free()
