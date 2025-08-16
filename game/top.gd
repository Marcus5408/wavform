extends Node2D

var spectrum: AudioEffectSpectrumAnalyzerInstance
var line: Line2D


func _ready():
    # select Line2D child
    line = $Line2D
    line.clear_points()
    line.default_color = Color.RED
    line.position = Vector2(0, 0)

var smoothed_points := []

func _process(_delta: float) -> void:
    spectrum = AudioServer.get_bus_effect_instance(0, 0)
    if spectrum == null:
        return

    var VU_COUNT = 32
    var FREQ_MAX = 11050.0
    var HEIGHT = 500
    var WIDTH = get_viewport().get_visible_rect().size.x
    var MIN_DB = 90
    var SMOOTH_FACTOR = 0.15  # Higher value = smoother

    var points = []
    var prev_hz = 0.0
    for i in range(1, VU_COUNT + 1):
        var hz = i * FREQ_MAX / VU_COUNT
        var magnitude = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
        var energy = clampf((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
        var x = float(i - 1) * WIDTH / (VU_COUNT - 1)
        var y = (energy * HEIGHT)
        points.append(Vector2(x, y))
        prev_hz = hz

    # Smoothing
    if smoothed_points.size() != points.size():
        smoothed_points = points.duplicate()
    else:
        for i in range(points.size()):
            smoothed_points[i].y = lerp(smoothed_points[i].y, points[i].y, 1.0 - SMOOTH_FACTOR)
            smoothed_points[i].x = points[i].x

    line.points = smoothed_points
