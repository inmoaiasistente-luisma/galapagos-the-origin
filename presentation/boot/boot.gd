extends Node2D

const LOGICAL_SIZE: Vector2i = Vector2i(320, 180)
const TILE_SIZE: int = 16
const COMPLETE_TILE_COLUMNS: int = 20
const COMPLETE_TILE_ROWS: int = 11
const FRACTIONAL_ROW_HEIGHT: int = 4
const BACKGROUND: Color = Color("07151c")
const GRID_MAJOR: Color = Color("24505b")
const GRID_MINOR: Color = Color("16343d")
const ACCENT: Color = Color("42d3a5")
const PARTIAL_ROW: Color = Color("d46b4c")

var _checker_texture: ImageTexture


func _ready() -> void:
	_checker_texture = _create_checker_texture()
	queue_redraw()

	var requested_size: Vector2i = _parse_size_argument()
	if requested_size != Vector2i.ZERO:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
		DisplayServer.window_set_size(requested_size)
		DisplayServer.window_set_position(Vector2i.ZERO)
		DisplayServer.window_move_to_foreground()

	var capture_path: String = _get_argument_value("--capture=")
	if not capture_path.is_empty():
		_capture_after_render.call_deferred(capture_path)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, LOGICAL_SIZE), BACKGROUND)

	for column: int in range(1, COMPLETE_TILE_COLUMNS):
		var x: float = float(column * TILE_SIZE)
		draw_line(Vector2(x, 0), Vector2(x, LOGICAL_SIZE.y), GRID_MINOR, 1.0)

	for row: int in range(1, COMPLETE_TILE_ROWS + 1):
		var y: float = float(row * TILE_SIZE)
		draw_line(Vector2(0, y), Vector2(LOGICAL_SIZE.x, y), GRID_MINOR, 1.0)

	draw_rect(Rect2(0, COMPLETE_TILE_ROWS * TILE_SIZE, LOGICAL_SIZE.x, FRACTIONAL_ROW_HEIGHT), PARTIAL_ROW)
	draw_rect(Rect2(0, 0, LOGICAL_SIZE.x, LOGICAL_SIZE.y), GRID_MAJOR, false, 1.0)

	_draw_one_pixel_ruler(Vector2i(8, 20))
	draw_texture_rect(_checker_texture, Rect2(240, 16, 64, 64), false)

	var baseline_rect: Rect2 = Rect2(120, 136, 16, 24)
	var tall_rect: Rect2 = Rect2(152, 128, 16, 32)
	draw_rect(baseline_rect, ACCENT, true)
	draw_rect(baseline_rect, Color.WHITE, false, 1.0)
	draw_rect(tall_rect, PARTIAL_ROW, true)
	draw_rect(tall_rect, Color.WHITE, false, 1.0)

	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(8, 12), "320x180  |  16x16  |  20 x 11.25", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	draw_string(font, Vector2(112, 173), "16x24", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color.WHITE)
	draw_string(font, Vector2(148, 173), "16x32", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color.WHITE)
	draw_string(font, Vector2(232, 91), "NEAREST", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color.WHITE)


func _draw_one_pixel_ruler(origin: Vector2i) -> void:
	for offset: int in range(64):
		var color: Color = Color.WHITE if offset % 2 == 0 else ACCENT
		draw_rect(Rect2(origin.x + offset, origin.y, 1, 1), color)
		draw_rect(Rect2(origin.x, origin.y + offset, 1, 1), color)


func _create_checker_texture() -> ImageTexture:
	var image: Image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y: int in range(8):
		for x: int in range(8):
			var color: Color = Color("f5f1d0") if (x + y) % 2 == 0 else Color("273e47")
			image.set_pixel(x, y, color)
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
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var window_position: Vector2i = DisplayServer.window_get_position()
	var window_size: Vector2i = DisplayServer.window_get_size()
	var viewport_image: Image = get_viewport().get_texture().get_image()
	var screen_image: Image = DisplayServer.screen_get_image()
	var window_rect: Rect2i = Rect2i(window_position, window_size)
	var image: Image = screen_image.get_region(window_rect)
	print(
		"BOOT_CAPTURE_DIAGNOSTIC window_position=%s viewport=%dx%d viewport_center=%s screen=%dx%d screen_center=%s"
		% [
			str(window_position),
			viewport_image.get_width(),
			viewport_image.get_height(),
			str(viewport_image.get_pixel(viewport_image.get_width() / 2, viewport_image.get_height() / 2)),
			screen_image.get_width(),
			screen_image.get_height(),
			str(screen_image.get_pixel(screen_image.get_width() / 2, screen_image.get_height() / 2))
		]
	)
	var absolute_path: String = ProjectSettings.globalize_path(capture_path)
	var result: Error = image.save_png(absolute_path)
	print(
		"BOOT_CAPTURE path=%s image=%dx%d window=%s result=%s renderer=%s"
		% [
			capture_path,
			image.get_width(),
			image.get_height(),
			str(window_size),
			error_string(result),
			ProjectSettings.get_setting("rendering/renderer/rendering_method")
		]
	)
	if result != OK:
		get_tree().quit(1)
		return
	get_tree().quit(0)
