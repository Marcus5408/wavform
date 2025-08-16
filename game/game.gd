extends Node2D

var original_window_pos := Vector2.ZERO

var tilt_tween: Tween = null
var tilt_animating := false


func _ready():
    # Connect window shake signal from Camera2D
    var cam = get_node_or_null("Camera2D")
    if cam and cam.has_signal("window_shake"):
        cam.connect("window_shake", Callable(self, "_on_window_shake"))
    # Store original window position
    original_window_pos = DisplayServer.window_get_position()

    # Connect window shake signal from Camera2D
    var camera = get_node_or_null("Camera2D")
    if camera and camera.has_signal("window_shake"):
        camera.connect("window_shake", Callable(self, "_on_window_shake"))
    # Store original window position
    original_window_pos = DisplayServer.window_get_position()

    # Ensure modulate is reset
    modulate = Color(1, 1, 1, 1)
    rotation = 0
    position = Vector2.ZERO


func _on_window_shake(shake_vec: Vector2):
    if shake_vec != Vector2.ZERO:
        DisplayServer.window_set_position(original_window_pos + shake_vec)
    else:
        DisplayServer.window_set_position(original_window_pos)


func tilt_and_fall_and_fade():
    if tilt_animating:
        return
    tilt_animating = true
    tilt_tween = create_tween()
    tilt_tween.tween_property(self, "rotation", deg_to_rad(20), 2.0)
    tilt_tween.tween_property(self, "position", Vector2(150, 600), 2.0)
    tilt_tween.tween_property(self, "modulate:a", 0.3, 2.0)
    tilt_tween.tween_callback(Callable(self, "_on_tilt_anim_done"))
    tilt_tween.play()

func _on_tilt_anim_done():
    tilt_animating = false
