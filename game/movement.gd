extends Sprite2D

# when space or arrow up or w press go up

var speed := 100.0

func _ready() -> void:
    speed = get_viewport_rect().size.y / 2.0

func _process(delta: float) -> void:
    if Input.is_action_pressed("move_up"):
        position.y -= speed * delta
        if rotation_degrees > -15:
            rotation_degrees -= speed * delta
    if Input.is_action_pressed("move_down"):
        position.y += speed * delta
        if rotation_degrees < 15:
            rotation_degrees += speed * delta
