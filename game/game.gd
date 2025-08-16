extends Node2D

var original_window_pos := Vector2.ZERO


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


func _on_window_shake(shake_vec: Vector2):
    if shake_vec != Vector2.ZERO:
        DisplayServer.window_set_position(original_window_pos + shake_vec)
    else:
        DisplayServer.window_set_position(original_window_pos)
