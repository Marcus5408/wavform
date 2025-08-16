extends Node2D

const MS_PER_BAR := 100  # How much time (in ms) each bar represents
const WAVEFORM_HEIGHT := 400
const WAVEFORM_COLOR := Color(1, 1, 1)
var MIN_BAR_HEIGHT := 1  # Minimum height of each bar in pixels
var BAR_WIDTH := 10  # Width of each bar in pixels
var BAR_SPACING := 10  # Space between bars in pixels

# User-configurable vertical center for waveform (in pixels from top)
var waveform_y_pos = null  # If null, auto-center. Otherwise, set to desired y position.

var output_latency := 0.0
var processed_data := []
var mapped_waveform := []
var sample_rate := 44100
var waveform_offset := 0.0


func _ready():
    var player = $AudioStreamPlayer
    # player.stream = AudioStreamWAV.load_from_file("res://Matsuri-FujiiKaze.wav")
    player.stream = AudioStreamWAV.load_from_file("res://sayitback-tvroom.wav")

    processed_data = process_audio_data(player.stream.data)
    mapped_waveform = map_waveform(processed_data, MIN_BAR_HEIGHT, WAVEFORM_HEIGHT)
    output_latency = AudioServer.get_output_latency()
    player.play()
    waveform_y_pos = get_viewport_rect().size.y
    queue_redraw()


func _process(_delta: float) -> void:
    var audio_player = $AudioStreamPlayer
    if audio_player.playing:
        var time = audio_player.get_playback_position() + AudioServer.get_time_since_last_mix() - output_latency
        var playback_pos = time * 1000  # ms
        waveform_offset = float(playback_pos / MS_PER_BAR)
    queue_redraw()


func process_audio_data(audio_data):
    var waveform_data: Array = []
    sample_rate = 44100  # default to 44.1kHz
    var bit_size: int = 16  # default to 16-bit
    if audio_data.size() > 44:
        sample_rate = audio_data.decode_u32(24)
        sample_rate = 44100 if sample_rate == 0 else sample_rate
        bit_size = audio_data.decode_u8(34)
        bit_size = 16 if bit_size == 0 else bit_size
    @warning_ignore("integer_division")
    var bytes_per_sample: int = bit_size / int(8)
    var samples_per_bar = int((MS_PER_BAR / 1000.0) * sample_rate)
    for i in range(0, audio_data.size(), samples_per_bar * bytes_per_sample):
        var sum = 0.0
        var count = 0
        for j in range(i, min(i + samples_per_bar * bytes_per_sample, audio_data.size()), bytes_per_sample):
            var sample = 0.0
            match bit_size:
                8:
                    sample = audio_data.decode_u8(j) - 128 / 128.0
                16:
                    sample = audio_data.decode_s16(j) / 32768.0
                32:
                    sample = audio_data.decode_s32(j) / 2147483648.0
                _:
                    sample = sample / (2 ** (bit_size - 1))
            sum += abs(sample)
            count += 1
        var loudness = sum / max(count, 1)
        waveform_data.append(loudness)
    return waveform_data


func map_range(value: float, in_min: float, in_max: float, out_min: float, out_max: float) -> float:
    if in_max == in_min:
        return out_min
    return (value - in_min) * (out_max - out_min) / (in_max - in_min) + out_min


func map_waveform(raw_waveform: Array, min_bar_height: float, max_bar_height: float) -> Array:
    var raw_amplitude = [raw_waveform.min(), raw_waveform.max()]
    var result_waveform: Array = []
    for value in raw_waveform:
        var mapped_value = map_range(value, raw_amplitude[0], raw_amplitude[1], min_bar_height, max_bar_height)
        result_waveform.append(mapped_value)
    return result_waveform


func _draw():
    if mapped_waveform.size() == 0:
        return
    var viewport_size: Vector2 = get_viewport_rect().size
    var center_y: float
    if waveform_y_pos == null:
        center_y = viewport_size.y - (float(WAVEFORM_HEIGHT) / 2.0)
    else:
        center_y = float(waveform_y_pos)
    var start_x = viewport_size.x / 2 - (BAR_WIDTH + BAR_SPACING) * waveform_offset
    for i in range(mapped_waveform.size()):
        var bar_height = mapped_waveform[i]
        var x = start_x + i * (BAR_WIDTH + BAR_SPACING)
        var y = center_y - bar_height / 2
        var normalized_height = (bar_height - MIN_BAR_HEIGHT) / float(WAVEFORM_HEIGHT - MIN_BAR_HEIGHT)
        var color = Color.from_hsv(normalized_height, 1.0, 1.0)
        draw_rect(Rect2(Vector2(x, y), Vector2(BAR_WIDTH, bar_height)), color)
