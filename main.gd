extends Node2D

# Configs for waveform display
const WAVEFORM_SAMPLE_COUNT := 512
const WAVEFORM_HEIGHT := 200
const WAVEFORM_COLOR := Color(1, 1, 1)
var BAR_WIDTH := 8  # Width of each bar in pixels
var BAR_SPACING := 1  # Space between bars in pixels
var MIN_BAR_HEIGHT := 2  # Minimum height of each bar in pixels

var viewport_size: Vector2


func _ready():
    viewport_size = get_viewport().get_visible_rect().size
    var waveform_width = viewport_size.x

    var song = load("res://sayitback-tvroom.wav")
    var audio_data = song.get_data()
    var result = process_audio_data(audio_data)
    var waveform = result[0]
    var _sample_rate = result[1]

    var waveform_visualizer = create_waveform_visualizer(waveform, waveform_width, WAVEFORM_HEIGHT, BAR_WIDTH, BAR_SPACING, MIN_BAR_HEIGHT)
    add_child(waveform_visualizer)

    # set beginning of visualizer to be in the middle of the screen
    waveform_visualizer.position = Vector2((viewport_size.x - waveform_width) / 2, (viewport_size.y - WAVEFORM_HEIGHT) / 2)

    var player = $AudioStreamPlayer
    player.stream = song
    player.play()


func process_audio_data(audio_data):
    var waveform = []
    var sample_rate = audio_data.size() / WAVEFORM_SAMPLE_COUNT
    for i in range(WAVEFORM_SAMPLE_COUNT):
        var byte_index = int(i * sample_rate) * 2  # 2 bytes per sample
        if byte_index + 1 < audio_data.size():
            var sample = audio_data[byte_index] | (audio_data[byte_index + 1] << 8)
            # Convert unsigned 16-bit sample to signed (two's complement)
            if sample >= 0x8000:
                sample -= 0x10000
            # Normalize sample to range [-1.0, 1.0] (32768 is the signed 16-bit max)
            var normalized_sample = float(sample) / 32768.0
            waveform.append(normalized_sample)
        else:
            waveform.append(0.0)
    return [waveform, sample_rate]


func create_waveform_visualizer(waveform_data, total_width, max_bar_height, bar_width, bar_spacing, min_bar_height):
    var max_amplitude = max(0.001, abs(waveform_data.max()))
    var normalized_waveform = []
    for value in waveform_data:
        var bar_height = max(abs(value) / max_amplitude * max_bar_height, min_bar_height)
        normalized_waveform.append(bar_height)

    var waveform_container = CanvasGroup.new()
    var bar_count = waveform_data.size()
    var total_bars_width = bar_count * bar_width + (bar_count - 1) * bar_spacing
    var start_x = (total_width - total_bars_width) / 2.0

    for i in range(bar_count):
        var bar = ColorRect.new()
        bar.color = WAVEFORM_COLOR
        bar.size = Vector2(bar_width, normalized_waveform[i])
        bar.position = Vector2(start_x + i * (bar_width + bar_spacing), (max_bar_height - normalized_waveform[i]) / 2)
        waveform_container.add_child(bar)

    return waveform_container
