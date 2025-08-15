extends Node2D

var spectrum: AudioEffectSpectrumAnalyzerInstance
var line: Line2D
var viewport_size: Vector2
var player_character: Sprite2D

# waveform configs
var BAR_COUNT = 32
var FREQ_MAX = 11050.0
var HEIGHT = 200
var WIDTH = 0
var MIN_DB = 60
var SMOOTH_FACTOR = 0.7  # Higher value = smoother

func _ready():
    viewport_size = get_viewport().get_visible_rect().size
    WIDTH = viewport_size.x

    # select Line2D child
    line = $Line2D
    line.clear_points()
    line.default_color = Color(1, 1, 1)
    line.position = Vector2(0, viewport_size.y / 2)

    set_up_waveform()

    var song = load("res://sayitback-tvroom.wav")
    # select AudioStreamPlayer
    var player = $AudioStreamPlayer
    player.stream = song
    player.play()

    player_character = $Sprite2D

var smoothed_points := []

func _process(_delta: float) -> void:
    spectrum = AudioServer.get_bus_effect_instance(0, 0)
    if spectrum == null:
        return

    var points = []
    var prev_hz = 0.0
    for i in range(1, BAR_COUNT + 1):
        var hz = i * FREQ_MAX / BAR_COUNT
        var magnitude = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
        var energy = clampf((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
        var x = float(i - 1) * WIDTH / (BAR_COUNT - 1)
        var y = HEIGHT - (energy * HEIGHT)
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

    # adjust collision shapes
    for i in range(BAR_COUNT):
        var col_shape = line.get_node("Bar" + str(i)) as StaticBody2D
        if col_shape:
            col_shape.position.y = smoothed_points[i].y
            # col_shape.shape.y = (HEIGHT - smoothed_points[i].y) / 2.0
            col_shape.scale = Vector2(2, 1)

    # if Sprite2D is below line at the Sprite2D's x position, set its y position above the line
    if player_character.position.y > line.position.y:
        player_character.position.y = line.position.y - player_character.scale.y

func set_up_waveform():
    # create collision shapes for each bar with bar index appended
    for i in range(BAR_COUNT):
        var col_staticbody = StaticBody2D.new()
        col_staticbody.position = Vector2(float(i) * float(WIDTH) / float(BAR_COUNT), HEIGHT)
        col_staticbody.name = "Bar" + str(i)
        # add collision shape and rect shape as children of the staticbody
        var col_shape = CollisionShape2D.new()
        col_shape.shape = RectangleShape2D.new()
        col_shape.shape.extents = Vector2(2, 1)  # 4px wide, 2px tall (extents are half-size)
        col_shape.position = Vector2(float(i) * float(WIDTH) / float(BAR_COUNT), HEIGHT)
        col_staticbody.add_child(col_shape)
        line.add_child(col_staticbody)
