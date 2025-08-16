extends Camera2D

var spectrum: AudioEffectSpectrumAnalyzerInstance
var middle: Vector2
const disturbance: float = 5.0
const BEAT_THRESHOLD: float = 0.45
var prev_energy: float = 0.0

func _ready() -> void:
    self.position_smoothing_enabled = true
    var viewport_size: Vector2 = get_viewport_rect().size
    middle = Vector2(
        viewport_size.x / 2,
        viewport_size.y / 2  
    )
    self.position = Vector2(middle.x, middle.y)

func _process(delta: float) -> void:
    spectrum = AudioServer.get_bus_effect_instance(0, 0)
    if spectrum == null:
        return

    var VU_COUNT = 32
    var FREQ_MAX = 7000.0
    var MIN_DB = 50
    var energy = 0.0
    var prev_hz = 0.0 
    for i in range(1, VU_COUNT + 1):
        var hz = i * FREQ_MAX / VU_COUNT
        var magnitude = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
        energy = clampf((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
        prev_hz = hz
    
    # Detect beat drop (energy crosses threshold from below)
    if prev_energy < BEAT_THRESHOLD and energy >= BEAT_THRESHOLD:
        var rng = RandomNumberGenerator.new()
        self.offset = Vector2(
            rng.randf_range(-disturbance, disturbance),
            rng.randf_range(-disturbance, disturbance)
        )
    else:
        self.offset = Vector2(0, 0)
    
    prev_energy = energy
