extends Sprite2D

var raycast: RayCast2D
var gravity: Vector2 = Vector2(0, 1000)  # Gravity vector


func _ready():
    raycast = $RayCast2D


func _physics_process(delta: float) -> void:
    raycast.force_raycast_update()
    # print if colliding with any other node (even those without colliders)
    if raycast.is_colliding():
        var collider = raycast.get_collider()
        if collider:
            print("Colliding with: ", collider.get_path())
    else:
        position += gravity * delta
