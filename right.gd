extends Node2D

var spectrum: AudioEffectSpectrumAnalyzerInstance
const VU_COUNT := 32
const FREQ_MAX := 11050.0
const HEIGHT := 250
const BAR_WIDTH := 10
const BAR_SPACING := 10  # Increased gap between bars
const MIN_DB := 90
const SMOOTH_FACTOR := 0.15
var smoothed_energies := []
const ENEMY_TRIGGER_THRESHOLD := 0.99  # Extremely low sensitivity
var bar_enemies := []


func _ready() -> void:
    smoothed_energies.resize(VU_COUNT)
    for i in range(VU_COUNT):
        smoothed_energies[i] = 0.0
    bar_enemies.resize(VU_COUNT)
    for i in range(VU_COUNT):
        bar_enemies[i] = null
    set_process(true)


func _process(delta: float) -> void:
    spectrum = AudioServer.get_bus_effect_instance(0, 0)
    if spectrum == null:
        return

    var prev_hz = 0.0
    var energies = []
    for i in range(1, VU_COUNT + 1):
        var hz = i * FREQ_MAX / VU_COUNT
        var magnitude = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
        var energy = clampf((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
        energies.append(energy)
        prev_hz = hz

    # Smoothing
    for i in range(VU_COUNT):
        smoothed_energies[i] = lerp(smoothed_energies[i], energies[i], 1.0 - SMOOTH_FACTOR)

        # Trigger enemy if energy crosses threshold and not already active
        if energies[i] >= ENEMY_TRIGGER_THRESHOLD and bar_enemies[i] == null:
            bar_enemies[i] = {
                "progress": 0.0,
                "speed": 1200.0,  # pixels/sec
                "color": Color.from_hsv(energies[i], 1.0, 1.0)
            }
        # Animate enemy if active
        if bar_enemies[i] != null:
            bar_enemies[i]["progress"] += bar_enemies[i]["speed"] * delta
            if bar_enemies[i]["progress"] > HEIGHT:
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

        # Draw enemy if active
        if bar_enemies[i] != null:
            var enemy_length = bar_enemies[i]["progress"]
            var enemy_x = right_x - enemy_length
            var enemy_color = bar_enemies[i]["color"]
            enemy_color.a = 0.75  # 25% transparent
            draw_rect(Rect2(Vector2(enemy_x, y), Vector2(enemy_length, bar_height)), enemy_color)
