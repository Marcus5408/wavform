extends Node2D

# Configs for waveform display
const MS_PER_BAR := 125  # How much time (in ms) each bar represents
const WAVEFORM_HEIGHT := 600
const WAVEFORM_COLOR := Color(1, 1, 1)
var MIN_BAR_HEIGHT := 2  # Minimum height of each bar in pixels
var BAR_WIDTH := 10  # Width of each bar in pixels
var BAR_SPACING := 10  # Space between bars in pixels

var output_latency := 0.0

func _ready():
    var player = $AudioStreamPlayer
    player.stream = AudioStreamWAV.load_from_file("res://sayitback-tvroom.wav")

    var processed_data = process_audio_data(player.stream.data)
    var waveform_visualizer = create_waveform_visualizer(processed_data, MIN_BAR_HEIGHT, WAVEFORM_HEIGHT, BAR_WIDTH, BAR_SPACING)
    add_child(waveform_visualizer)
    var viewport_size: Vector2 = get_viewport_rect().size
    waveform_visualizer.position = Vector2(
        viewport_size.x / 2,
        (viewport_size.y / 2) - (waveform_visualizer.size.y / 2)
    )

    output_latency = AudioServer.get_output_latency()
    player.play()

func _process(_delta: float) -> void:
    var waveform_visualizer = $WaveformVisualizer
    var audio_player = $AudioStreamPlayer
    if audio_player.playing:
        var time = audio_player.get_playback_position() + AudioServer.get_time_since_last_mix() - output_latency
        # Use audio_player.get_playback_position() for accurate sync
        var playback_pos = time * 1000  # ms
        var bar_offset = float(playback_pos / MS_PER_BAR)
        var move_x = -(bar_offset * (BAR_WIDTH + BAR_SPACING))
        waveform_visualizer.position.x = move_x + (get_viewport_rect().size.x / 2)

func process_audio_data(audio_data):
    var waveform_data: Array = []
    # check the WAV file header various info.
    var sample_rate: int = 44100  # default to 44.1kHz
    var bit_size: int = 16  # default to 16-bit
    if audio_data.size() > 44:
        # read WAV header info
        sample_rate = audio_data.decode_u32(24)
        sample_rate = 44100 if sample_rate == 0 else sample_rate
        bit_size = audio_data.decode_u8(34)
        bit_size = 16 if bit_size == 0 else bit_size
    @warning_ignore("integer_division") # just for the line below
    var bytes_per_sample: int = bit_size / int(8)
    var samples_per_bar = int((MS_PER_BAR / 1000.0) * sample_rate)
    for i in range(0, audio_data.size(), samples_per_bar * bytes_per_sample):
        var sum = 0.0
        var count = 0
        for j in range(i, min(i + samples_per_bar * bytes_per_sample, audio_data.size()), bytes_per_sample):
            var sample = 0.0
            match bit_size:
                8:
                    sample = audio_data.decode_u8(j) - 128 / 128.0  # 8-bit unsigned to [-1, 1]
                16:
                    sample = audio_data.decode_s16(j) / 32768.0  # 16-bit signed to [-1, 1]
                32:
                    sample = audio_data.decode_s32(j) / 2147483648.0  # 32-bit signed to [-1, 1]
                _:
                    sample = sample / (2 ** (bit_size - 1))  # normalize other bit sizes
            sum += abs(sample)
            count += 1
        var loudness = sum / max(count, 1)
        waveform_data.append(loudness)

    return waveform_data

func map_range(value: float, in_min: float, in_max: float, out_min: float, out_max: float) -> float:
    return (value - in_min) * (out_max - out_min) / (in_max - in_min) + out_min

func create_waveform_visualizer(raw_waveform: Array, min_bar_height: float, max_bar_height: float, bar_width: float, bar_spacing: int) -> HBoxContainer:
    # step 1: figure out what the range of raw_waveform's data is
    var raw_amplitude = [raw_waveform.min(), raw_waveform.max()]

    # step 2: map raw_amplitude to bar_height
    var mapped_waveform: Array = []
    for value in raw_waveform:
        var mapped_value = map_range(value, raw_amplitude[0], raw_amplitude[1], min_bar_height, max_bar_height)
        mapped_waveform.append(mapped_value)
    
    # step 3: create a container for the bars
    var waveform_container = HBoxContainer.new()
    waveform_container.name = "WaveformVisualizer"
    waveform_container.size = Vector2(bar_width * mapped_waveform.size() + bar_spacing * (mapped_waveform.size() - 1), max_bar_height)
    waveform_container.add_theme_constant_override("separation", bar_spacing)
    waveform_container.alignment = HBoxContainer.ALIGNMENT_CENTER
    waveform_container.z_index = 1000
    waveform_container.set_anchors_preset(Control.PRESET_CENTER_LEFT)

    # step 4: create bars based on mapped_waveform
    for index in range(mapped_waveform.size()):
        var bar_height: float = mapped_waveform[index]
        # 4-1: lock aspect ratio!
        var aspect_ratio_container = AspectRatioContainer.new()
        aspect_ratio_container.ratio = bar_width / bar_height
        # 4a: create a bar
        var bar_rect: ColorRect = ColorRect.new()
        bar_rect.color = WAVEFORM_COLOR
        bar_rect.size = Vector2(bar_width, bar_height)
        bar_rect.custom_minimum_size = Vector2(bar_width, bar_height)
        bar_rect.name = "Bar_%d" % index
        # 4b: add collision shape
        var collision: CollisionShape2D = CollisionShape2D.new()
        var rect_shape: RectangleShape2D = RectangleShape2D.new()
        rect_shape.extents = Vector2(bar_width / 2, bar_height / 2)
        collision.shape = rect_shape
        bar_rect.add_child(collision)
        # 4c: add the bar to the container
        aspect_ratio_container.add_child(bar_rect)
        waveform_container.add_child(aspect_ratio_container)

    # step 5: return the container
    return waveform_container
