extends Node2D

# Configs for waveform display
const MS_PER_BAR := 250
const WAVEFORM_HEIGHT := 200
const WAVEFORM_COLOR := Color(1, 1, 1)
var BAR_WIDTH := 6  # Width of each bar in pixels
var BAR_SPACING := 2  # Space between bars in pixels
var MIN_BAR_HEIGHT := 2  # Minimum height of each bar in pixels

var waveform_sample_count: int
var viewport_size: Vector2


func _ready():
    viewport_size = get_viewport().get_visible_rect().size

    var song = load("res://matsuri-fujiikaze.wav")
    var audio_data = song.get_data()
    var sample_rate = song.get_mix_rate()
    var waveform = process_audio_data(audio_data, sample_rate)

    var waveform_visualizer = create_waveform_visualizer(waveform, WAVEFORM_HEIGHT, BAR_WIDTH, BAR_SPACING, MIN_BAR_HEIGHT)
    add_child(waveform_visualizer)

    # set left side of visualizer to be in the middle of the screen
    waveform_visualizer.position = Vector2(viewport_size.x / 2, (viewport_size.y - WAVEFORM_HEIGHT) / 2)

    var player = $AudioStreamPlayer
    player.stream = song
    player.play()


func _process(delta: float) -> void:
    # Scroll visualizer based on sample_rate (ms per bar)
    var player = $AudioStreamPlayer
    if player.playing:
        var waveform_visualizer = get_node_or_null("WaveformVisualizer")
        if not waveform_visualizer:
            push_error("Waveform visualizer not found! What the...")
            return  # Exit if the visualizer is not found
        if waveform_visualizer:
            # Calculate pixels per millisecond using bar width + spacing and MS_PER_BAR
            var pixels_per_ms = float(BAR_WIDTH + BAR_SPACING) / MS_PER_BAR
            var pixels_per_frame = pixels_per_ms * (delta * 1000)
            waveform_visualizer.position.x -= pixels_per_frame


func process_audio_data(audio_data, sample_rate):
    var waveform = []
    var bytes_per_sample = 2  # 16-bit audio
    var ms_per_bar = MS_PER_BAR
    var total_samples = audio_data.size() / bytes_per_sample
    var samples_per_bar = int(sample_rate * ms_per_bar / 1000.0)
    waveform_sample_count = int(total_samples / samples_per_bar)
    for i in range(waveform_sample_count):
        var squared_sum = 0.0
        var count = 0
        var start_sample = i * samples_per_bar
        var end_sample = min(start_sample + samples_per_bar, total_samples)
        for s in range(start_sample, end_sample):
            var byte_index = int(s) * bytes_per_sample
            if byte_index + 1 < audio_data.size():
                var sample = audio_data[byte_index] | (audio_data[byte_index + 1] << 8)
                if sample >= 0x8000:
                    sample -= 0x10000
                var normalized_sample = float(sample) / 32768.0  # Normalize to -1.0 to 1.0 range
                squared_sum += normalized_sample * normalized_sample
                count += 1
        if count > 0:
            var mean = squared_sum / count
            var rms = sqrt(mean)
            waveform.append(rms)
        else:
            waveform.append(0.0)
    return waveform


func create_waveform_visualizer(waveform_data, max_bar_height, bar_width, bar_spacing, min_bar_height):
    var max_amplitude = max(0.001, abs(waveform_data.max()))
    var normalized_waveform = []
    for value in waveform_data:
        var normalized = clamp(abs(value) / max_amplitude, 0.0, 1.0)
        var bar_height = lerp(min_bar_height, max_bar_height, normalized)
        normalized_waveform.append(bar_height)

    var waveform_container = CanvasGroup.new()
    var bar_count = waveform_data.size()
    var _total_bars_width = bar_count * bar_width + (bar_count - 1) * bar_spacing
    var container_height = 0

    for i in range(bar_count):
        var bar = ColorRect.new()
        bar.color = WAVEFORM_COLOR
        bar.size = Vector2(bar_width, normalized_waveform[i])
        bar.position = Vector2(i * (bar_width + bar_spacing), (max_bar_height - normalized_waveform[i]) / 2)
        waveform_container.add_child(bar)
        container_height = max(container_height, normalized_waveform[i])

        # Add collision shape for each bar
        var collision = CollisionShape2D.new()
        var rect_shape = RectangleShape2D.new()
        rect_shape.extents = Vector2(bar_width / 2, normalized_waveform[i] / 2)
        collision.shape = rect_shape
        # Position collision shape at the center of the bar
        collision.position = bar.position + Vector2(bar_width / 2, normalized_waveform[i] / 2)
        waveform_container.add_child(collision)

    # recalculate CanvasGroup size
    waveform_container.set_fit_margin(20.0)
    waveform_container.name = "WaveformVisualizer"

    return waveform_container
