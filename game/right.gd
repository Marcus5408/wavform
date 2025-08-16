extends Node2D

var spectrum: AudioEffectSpectrumAnalyzerInstance
const VU_COUNT := 32
const FREQ_MIN := 400
const FREQ_MAX := 4000.0  # End at 4000 Hz (mids)
const HEIGHT := 250
const BAR_WIDTH := 10
const BAR_SPACING := 10  # Increased gap between bars
const MIN_DB := 90
const SMOOTH_FACTOR := 0.15
var smoothed_energies := []
const ENEMY_TRIGGER_THRESHOLD := 0.725  # Lowered threshold for more frequent spawning
var bar_enemies := []  # Store lazerbeam nodes
var lazerbeam_scene: PackedScene


func _ready() -> void:
    smoothed_energies.resize(VU_COUNT)
    for i in range(VU_COUNT):
        smoothed_energies[i] = 0.0
    bar_enemies.resize(VU_COUNT)
    for i in range(VU_COUNT):
        bar_enemies[i] = null
    set_process(true)
    # Cache lazerbeam scene
    lazerbeam_scene = load("res://game/lazerbeams.tscn")


func _process(_delta: float) -> void:
    spectrum = AudioServer.get_bus_effect_instance(0, 0)
    if spectrum == null:
        return

    var prev_hz = FREQ_MIN
    var energies = []
    for i in range(1, VU_COUNT + 1):
        var hz = FREQ_MIN + i * (FREQ_MAX - FREQ_MIN) / VU_COUNT
        var magnitude = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
        var energy = clampf((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
        energies.append(energy)
        prev_hz = hz

    # Smoothing
    for i in range(VU_COUNT):
        smoothed_energies[i] = lerp(smoothed_energies[i], energies[i], 1.0 - SMOOTH_FACTOR)

    # Trigger enemy ONLY on high enough peaks in any frequency
    for i in range(VU_COUNT):
        if energies[i] >= ENEMY_TRIGGER_THRESHOLD and bar_enemies[i] == null:
            var lazerbeam = lazerbeam_scene.instantiate()
            var viewport_size = get_viewport_rect().size
            var y = i * (float(viewport_size.y) / VU_COUNT + BAR_SPACING)
            lazerbeam.position = Vector2(viewport_size.x, y)
            lazerbeam.length = HEIGHT / 2.0
            lazerbeam.height = float(viewport_size.y) / VU_COUNT
            lazerbeam.color = Color.from_hsv(energies[i], 1.0, 1.0)
            add_child(lazerbeam)
            bar_enemies[i] = lazerbeam
            # Connect lazerbeam signal to handler
            lazerbeam.connect("player_touched_lazerbeam", Callable(self, "_on_player_touched_lazerbeam"))
        # Remove reference if lazerbeam is freed
        if bar_enemies[i] != null and not is_instance_valid(bar_enemies[i]):
            bar_enemies[i] = null

    queue_redraw()


func _draw():
    var viewport_size = get_viewport_rect().size
    var right_x = viewport_size.x
    var top_y = 0
    var bar_height = float(viewport_size.y) / VU_COUNT
    for i in range(VU_COUNT):
        var bar_length = smoothed_energies[i] * HEIGHT
        var y = top_y + i * (bar_height + BAR_SPACING)
        var x = right_x - bar_length
        var normalized_length = smoothed_energies[i]
        var color = Color.from_hsv(normalized_length, 1.0, 1.0, 0.75)  # 25% transparent
        draw_rect(Rect2(Vector2(x, y), Vector2(bar_length, bar_height)), color)


func _on_player_touched_lazerbeam(body):
    # Fade out the song when player touches lazerbeam
    var bottom = get_tree().get_root().get_node("Node2D/Bottom")
    if bottom:
        bottom.call("fade_out_song")
