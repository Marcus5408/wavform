extends CharacterBody2D

# when space or arrow up or w press go up

var speed := 100.0


func _ready() -> void:
    speed = get_viewport_rect().size.y / 2.0
    add_to_group("player")


func _physics_process(delta: float) -> void:
    var move_vec = Vector2.ZERO
    if Input.is_action_pressed("move_up"):
        move_vec.y -= speed
    if Input.is_action_pressed("move_down"):
        move_vec.y += speed
    move_vec = move_vec * delta
    move_and_collide(move_vec)
