extends TextureRect

@export var audio_file_path: String = "res://Matsuri-FujiiKaze.wav"
@export var waveform_color: Color = Color.WHITE
@export var background_color: Color = Color.BLACK
@export var waveform_height_multiplier: float = 0.8 # Controls how much of the rect height the waveform occupies

var audio_stream: AudioStreamWAV = null
var waveform_image: Image = null
var waveform_texture: ImageTexture = null

func _ready() -> void:
    if audio_file_path.is_empty():
        printerr("Audio file path is not set.")
        return

    # Load the audio stream
    var loaded_stream = ResourceLoader.load(audio_file_path)
    if loaded_stream is AudioStreamWAV:
        audio_stream = loaded_stream
    else:
        printerr("Failed to load AudioStreamWAV from: ", audio_file_path)
        printerr("Please ensure the audio is a .wav file or implement decoding for other formats.")
        return

    # Generate and display the waveform
    generate_waveform()

func generate_waveform() -> void:
    if audio_stream == null:
        printerr("AudioStream is not loaded. Cannot generate waveform.")
        return

    var width = int(size.x)
    var height = int(size.y)
    if width <= 0 or height <= 0:
        printerr("TextureRect size is zero or negative. Cannot generate waveform.")
        return

    # Create a new Image for the waveform
    waveform_image = Image.new()
    waveform_image.create(width, height, false, Image.FORMAT_RGBA8)
    waveform_image.fill(background_color) # Fill with background color

    # Get audio data
    var format = audio_stream.format
    var bits = audio_stream.bits
    var stereo = audio_stream.stereo
    var data = audio_stream.data # PackedByteArray of raw audio data

    if data.is_empty():
        printerr("Audio data is empty. Cannot generate waveform.")
        return

    var num_channels = 2 if stereo else 1
    var bytes_per_sample = bits / 8
    var total_samples = data.size() / bytes_per_sample / num_channels

    if total_samples <= 0:
        printerr("No audio samples found. Cannot generate waveform.")
        return

    # Determine how many audio samples correspond to one pixel column
    var samples_per_pixel = float(total_samples) / width
    var center_y = height / 2

    # Calculate the vertical scaling factor for the waveform
    # We want the peaks to reach near the top/bottom of the allowed height
    var vertical_scale_factor = (height * waveform_height_multiplier) / 2.0

    # Iterate through each pixel column
    for x in range(width):
        var start_sample_index = int(x * samples_per_pixel)
        var end_sample_index = int((x + 1) * samples_per_pixel)
        end_sample_index = mini(end_sample_index, total_samples) # Clamp to total samples

        if end_sample_index <= start_sample_index:
            # Not enough samples for this pixel column, or at the very end
            continue

        var min_val = 0.0
        var max_val = 0.0
        var found_samples = false

        # Find min and max amplitude in this pixel's sample range
        for i in range(start_sample_index, end_sample_index):
            # Read sample value. Assumes little-endian for WAV.
            # Godot's AudioStreamWAV.data is raw PCM.
            # We need to manually parse bytes based on bits and format.

            # Simple approach: average left and right for mono, or pick left.
            # More complex: show separate L/R or sum for true mono representation.
            # For visualization, just picking the first channel's peak is common.
            var sample_index_in_data = i * bytes_per_sample * num_channels
            if sample_index_in_data + bytes_per_sample > data.size():
                break # Avoid reading past end of data

            var sample_value = 0.0

            if bits == 16:
                # Read 2 bytes (16-bit signed integer)
                var val = data.get_s16(sample_index_in_data)
                sample_value = float(val) / 32768.0 # Normalize to -1.0 to 1.0
            elif bits == 24:
                # Read 3 bytes (24-bit signed integer) - more complex
                # For simplicity here, if you have 24-bit, convert to 32-bit float or 16-bit
                # or implement proper 24-bit signed integer conversion.
                # Godot 4.x has `get_s24` and `get_s32`.
                # Assuming s32 for 24-bit (padded to 32)
                var val = data.get_s32(sample_index_in_data)
                sample_value = float(val) / 2147483648.0 # Normalize to -1.0 to 1.0
            elif bits == 32 and format == 2: # FORMAT_FLOAT is 2
                # Read 4 bytes (32-bit float)
                var val = data.get_float(sample_index_in_data)
                sample_value = val # Already normalized
            elif bits == 32 and format == 0: # PCM format is 0 in Godot
                # Read 4 bytes (32-bit signed integer)
                var val = data.get_s32(sample_index_in_data)
                sample_value = float(val) / 2147483648.0 # Normalize to -1.0 to 1.0
            else:
                printerr("Unsupported audio bit depth or format: %d bits, format %d" % [bits, format])
                return

            if not found_samples:
                min_val = sample_value
                max_val = sample_value
                found_samples = true
            else:
                min_val = minf(min_val, sample_value)
                max_val = maxf(max_val, sample_value)

        if found_samples:
            # Convert normalized amplitude values to pixel coordinates
            var pixel_y_max = int(center_y - max_val * vertical_scale_factor)
            var pixel_y_min = int(center_y - min_val * vertical_scale_factor)

            # Ensure coordinates are within image bounds
            pixel_y_max = clampi(pixel_y_max, 0, height - 1)
            pixel_y_min = clampi(pixel_y_min, 0, height - 1)

            # Draw a vertical line for the waveform segment
            for y_draw in range(pixel_y_max, pixel_y_min + 1):
                waveform_image.set_pixel(x, y_draw, waveform_color)

    # Create a texture from the generated image and set it to the TextureRect
    waveform_texture = ImageTexture.create_from_image(waveform_image)
    texture = waveform_texture
    print("Waveform generated successfully!")
