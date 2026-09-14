extends Node2D

const LOGICAL_SIZE: Vector2i = Vector2i(320, 180)
const FEATURES: Array[String] = [
	"canvas_modulate",
	"light_occluder",
	"normal_map",
	"backbuffer_blend",
	"screen_space",
]
const BACKGROUND: Color = Color("0b1820")
const CYAN: Color = Color("42d3a5")
const ORANGE: Color = Color("e8874f")
const BLUE: Color = Color("4287d3")

var _feature: String = "canvas_modulate"


func _ready() -> void:
	_feature = _get_argument_value("--renderer-feature=")
	if not FEATURES.has(_feature):
		push_error("Unknown renderer feature: %s" % _feature)
		get_tree().quit(1)
		return

	queue_redraw()
	_setup_feature(_feature)

	var requested_size: Vector2i = _parse_size_argument()
	if requested_size != Vector2i.ZERO:
		DisplayServer.window_set_size(requested_size)

	var capture_path: String = _get_argument_value("--capture=")
	if not capture_path.is_empty():
		_capture_after_render.call_deferred(capture_path)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, LOGICAL_SIZE), BACKGROUND)
	for y: int in range(0, LOGICAL_SIZE.y, 16):
		for x: int in range(0, LOGICAL_SIZE.x, 16):
			var color: Color = Color("173641") if ((x + y) / 16 as int) % 2 == 0 else Color("102830")
			draw_rect(Rect2(x, y, 16, 16), color)

	draw_circle(Vector2(72, 92), 36, CYAN)
	draw_rect(Rect2(128, 48, 64, 88), ORANGE)
	draw_circle(Vector2(248, 92), 40, BLUE)

	var font: Font = ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, 320, 18), Color("071015"))
	draw_string(font, Vector2(8, 13), "COMPATIBILITY  |  %s" % _feature.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)


func _setup_feature(feature: String) -> void:
	match feature:
		"canvas_modulate":
			_setup_canvas_modulate()
		"light_occluder":
			_setup_light_occluder()
		"normal_map":
			_setup_normal_map()
		"backbuffer_blend":
			_setup_backbuffer_blend()
		"screen_space":
			_setup_screen_space()


func _setup_canvas_modulate() -> void:
	var canvas_modulate: CanvasModulate = CanvasModulate.new()
	canvas_modulate.color = Color(0.48, 0.62, 0.9, 1.0)
	add_child(canvas_modulate)


func _setup_light_occluder() -> void:
	var light: PointLight2D = PointLight2D.new()
	light.texture = _create_radial_light_texture(128)
	light.position = Vector2(96, 88)
	light.energy = 1.35
	light.shadow_enabled = true
	light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	add_child(light)

	var polygon: OccluderPolygon2D = OccluderPolygon2D.new()
	polygon.polygon = PackedVector2Array([
		Vector2(-10, -32), Vector2(10, -32), Vector2(10, 32), Vector2(-10, 32)
	])
	var occluder: LightOccluder2D = LightOccluder2D.new()
	occluder.position = Vector2(160, 92)
	occluder.occluder = polygon
	add_child(occluder)


func _setup_normal_map() -> void:
	var canvas_texture: CanvasTexture = CanvasTexture.new()
	canvas_texture.diffuse_texture = _create_diffuse_texture(96)
	canvas_texture.normal_texture = _create_normal_texture(96)

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = canvas_texture
	sprite.position = Vector2(160, 96)
	add_child(sprite)

	var light: PointLight2D = PointLight2D.new()
	light.texture = _create_radial_light_texture(160)
	light.position = Vector2(124, 62)
	light.energy = 1.4
	add_child(light)


func _setup_backbuffer_blend() -> void:
	var backbuffer: BackBufferCopy = BackBufferCopy.new()
	backbuffer.copy_mode = BackBufferCopy.COPY_MODE_RECT
	backbuffer.rect = Rect2(Vector2.ZERO, LOGICAL_SIZE)
	add_child(backbuffer)

	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_add, unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
void fragment() {
	vec4 source = texture(screen_texture, SCREEN_UV);
	vec2 p = UV - vec2(0.5);
	float distance_to_ring = abs(length(p) - 0.23);
	float ring = 1.0 - smoothstep(0.018, 0.035, distance_to_ring);
	COLOR = vec4(source.rgb * 0.08 + vec3(1.0, 0.22, 0.04) * ring, ring * 0.85);
}
"""
	_add_fullscreen_shader(shader)


func _setup_screen_space() -> void:
	var shader: Shader = Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
void fragment() {
	vec4 source = texture(screen_texture, SCREEN_UV);
	vec2 centred = SCREEN_UV * 2.0 - 1.0;
	float vignette = clamp(1.1 - dot(centred, centred) * 0.38, 0.45, 1.0);
	float scanline = mix(0.72, 1.0, step(0.5, fract(FRAGCOORD.y / 4.0)));
	COLOR = vec4(source.rgb * vignette * scanline, source.a);
}
"""
	_add_fullscreen_shader(shader)


func _add_fullscreen_shader(shader: Shader) -> void:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	var overlay: ColorRect = ColorRect.new()
	overlay.position = Vector2.ZERO
	overlay.size = LOGICAL_SIZE
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.material = material
	add_child(overlay)


func _create_radial_light_texture(size: int) -> ImageTexture:
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var centre: Vector2 = Vector2(size - 1, size - 1) * 0.5
	var radius: float = float(size) * 0.5
	for y: int in range(size):
		for x: int in range(size):
			var strength: float = clamp(1.0 - Vector2(x, y).distance_to(centre) / radius, 0.0, 1.0)
			image.set_pixel(x, y, Color(strength, strength, strength, strength))
	return ImageTexture.create_from_image(image)


func _create_diffuse_texture(size: int) -> ImageTexture:
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y: int in range(size):
		for x: int in range(size):
			var cell: int = (x / 8 as int) + (y / 8 as int)
			var color: Color = Color("d9c89e") if cell % 2 == 0 else Color("7d9c8d")
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


func _create_normal_texture(size: int) -> ImageTexture:
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var centre: Vector2 = Vector2(size - 1, size - 1) * 0.5
	var radius: float = float(size) * 0.48
	for y: int in range(size):
		for x: int in range(size):
			var normal_xy: Vector2 = (Vector2(x, y) - centre) / radius
			var length_squared: float = normal_xy.length_squared()
			var normal_z: float = sqrt(max(0.0, 1.0 - length_squared))
			if length_squared > 1.0:
				normal_xy = normal_xy.normalized()
				normal_z = 0.0
			image.set_pixel(
				x,
				y,
				Color(normal_xy.x * 0.5 + 0.5, -normal_xy.y * 0.5 + 0.5, normal_z, 1.0)
			)
	return ImageTexture.create_from_image(image)


func _parse_size_argument() -> Vector2i:
	var raw_size: String = _get_argument_value("--evidence-size=")
	var parts: PackedStringArray = raw_size.split("x")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))


func _get_argument_value(prefix: String) -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return ""


func _capture_after_render(capture_path: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	var absolute_path: String = ProjectSettings.globalize_path(capture_path)
	var result: Error = image.save_png(absolute_path)
	print(
		"RENDERER_CHECK feature=%s status=%s renderer=%s screenshot=%s image=%dx%d"
		% [
			_feature,
			"PASS" if result == OK else "FAIL",
			ProjectSettings.get_setting("rendering/renderer/rendering_method"),
			capture_path,
			image.get_width(),
			image.get_height()
		]
	)
	if result != OK:
		get_tree().quit(1)
		return
	get_tree().quit(0)
