extends Node2D

var original_window_pos := Vector2.ZERO


func _ready():
    # Enable bloom using Environment
    var env = Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0, 0, 0)
    env.glow_enabled = true
    env.glow_strength = 1.0
    env.glow_bicubic_upscale = true
    env.glow_hdr_bleed_treshold = 0.8
    env.glow_hdr_bleed_scale = 2.0
    get_viewport().environment = env

    # Add a bright Sprite2D with emission shader to show bloom
    var sprite = Sprite2D.new()
    var img = Image.create(200, 200, false, Image.FORMAT_RGBA8)
    img.fill(Color(1, 1, 1, 1))
    var tex = ImageTexture.create_from_image(img)
    sprite.texture = tex
    sprite.position = get_viewport_rect().size / 2
    var emission_shader = Shader.new()
    emission_shader.code = '''
        shader_type canvas_item;
        render_mode unshaded;
        void fragment() {
            COLOR = vec4(1.0, 1.0, 1.0, 1.0);
            COLOR.rgb *= 10.0; // Emission for bloom
        }
    '''
    var emission_mat = ShaderMaterial.new()
    emission_mat.shader = emission_shader
    sprite.material = emission_mat
    add_child(sprite)

    # Add CanvasLayer for post-processing
    var layer = CanvasLayer.new()
    add_child(layer)

    # Add ColorRect with fisheye shader (transparent)
    var rect = ColorRect.new()
    rect.rect_min_size = get_viewport_rect().size
    rect.color = Color(1, 1, 1, 0)  # Fully transparent
    layer.add_child(rect)

    var shader = Shader.new()
    shader.code = '''
        shader_type canvas_item;
        uniform float strength : hint_range(0.0, 1.0) = 0.5;
        void fragment() {
            vec2 uv = SCREEN_UV * 2.0 - 1.0;
            float r = length(uv);
            float theta = atan(uv.y, uv.x);
            float fisheye = mix(r, r*r, strength);
            vec2 new_uv = fisheye * vec2(cos(theta), sin(theta));
            new_uv = (new_uv + 1.0) * 0.5;
            COLOR = texture(SCREEN_TEXTURE, new_uv);
        }
    '''
    var mat = ShaderMaterial.new()
    mat.shader = shader
    rect.material = mat

    # Connect window shake signal from Camera2D
    var camera = get_node_or_null("Camera2D")
    if camera and camera.has_signal("window_shake"):
        camera.connect("window_shake", Callable(self, "_on_window_shake"))
    # Store original window position
    original_window_pos = DisplayServer.window_get_position()


func _on_window_shake(shake_vec: Vector2):
    if shake_vec != Vector2.ZERO:
        DisplayServer.window_set_position(original_window_pos + shake_vec)
    else:
        DisplayServer.window_set_position(original_window_pos)
