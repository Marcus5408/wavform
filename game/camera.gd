extends Camera2D

var spectrum: AudioEffectSpectrumAnalyzerInstance
var middle: Vector2
const disturbance: float = 5.0
const BASS_THRESHOLD: float = 0.45
var rng := RandomNumberGenerator.new()

# Ensures camera resets when entering the game scene
func _enter_tree() -> void:
    var viewport_size: Vector2 = get_viewport_rect().size
    middle = Vector2(viewport_size.x / 2, viewport_size.y / 2)
    self.position = Vector2(middle.x, middle.y)
    self.offset = Vector2(0, 0)


func _ready() -> void:
    self.position_smoothing_enabled = true
    var viewport_size: Vector2 = get_viewport_rect().size
    middle = Vector2(
        viewport_size.x / 2,
        viewport_size.y / 2
    )
    self.position = Vector2(middle.x, middle.y)
    self.offset = Vector2(0, 0)


func _process(_delta: float) -> void:
    spectrum = AudioServer.get_bus_effect_instance(0, 0)
    if spectrum == null or not spectrum is AudioEffectSpectrumAnalyzerInstance:
        self.offset = Vector2(0, 0)
        return

    var VU_COUNT = 32
    var FREQ_MAX = 7000.0
    var MIN_DB = 50
    var bass_energy = 0.0
    var prev_hz = 0.0
    var bass_band_count = 0
    # Sum energy in low frequencies (20Hz–250Hz)
    for i in range(1, VU_COUNT + 1):
        var hz = i * FREQ_MAX / VU_COUNT
        if hz <= 250.0:
            var magnitude = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
            bass_energy += clampf((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
            bass_band_count += 1
        prev_hz = hz
    if bass_band_count > 0:
        bass_energy /= bass_band_count

    # Rumble camera and window if bass energy is high
    if bass_energy >= BASS_THRESHOLD:
        var shake_vec = Vector2(
            rng.randf_range(-disturbance, disturbance),
            rng.randf_range(-disturbance, disturbance)
        )
        self.offset = shake_vec
        # Emit signal to shake window
        if not has_signal("window_shake"):
            add_user_signal("window_shake")
        emit_signal("window_shake", shake_vec)
    else:
        self.offset = Vector2(0, 0)
        if not has_signal("window_shake"):
            add_user_signal("window_shake")
        emit_signal("window_shake", Vector2.ZERO)
