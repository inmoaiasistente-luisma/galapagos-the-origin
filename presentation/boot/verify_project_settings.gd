extends SceneTree

func _init() -> void:
	var failures: Array[String] = []
	var expected_features: PackedStringArray = PackedStringArray(["4.7", "GL Compatibility"])

	_check_equal(&"application/config/name", "Galapagos The Origin", failures)
	_check_equal(&"application/config/version", "0.1.0", failures)
	_check_equal(&"application/run/main_scene", "res://presentation/boot/boot.tscn", failures)
	_check_equal(&"application/config/features", expected_features, failures)
	_check_equal(&"application/config/icon", "res://icon.svg", failures)
	_check_equal(&"display/window/size/viewport_width", 320, failures)
	_check_equal(&"display/window/size/viewport_height", 180, failures)
	_check_equal(&"display/window/size/window_width_override", 1280, failures)
	_check_equal(&"display/window/size/window_height_override", 720, failures)
	_check_equal(&"display/window/size/resizable", false, failures)
	_check_equal(&"display/window/stretch/mode", "canvas_items", failures)
	_check_equal(&"display/window/stretch/aspect", "keep", failures)
	_check_equal(&"display/window/stretch/scale_mode", "integer", failures)
	_check_equal(
		&"rendering/textures/canvas_textures/default_texture_filter",
		0,
		failures
	)
	_check_equal(&"rendering/2d/snap/snap_2d_transforms_to_pixel", true, failures)
	_check_equal(&"rendering/2d/snap/snap_2d_vertices_to_pixel", true, failures)
	_check_equal(
		&"rendering/environment/defaults/default_clear_color",
		Color(0, 0, 0, 1),
		failures
	)
	_check_equal(&"rendering/renderer/rendering_method", "gl_compatibility", failures)
	_check_equal(&"rendering/renderer/rendering_method.mobile", "gl_compatibility", failures)

	if failures.is_empty():
		print("PROJECT_SETTINGS_VERIFICATION=PASS")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
	print("PROJECT_SETTINGS_VERIFICATION=FAIL count=%d" % failures.size())
	quit(1)


func _check_equal(key: StringName, expected: Variant, failures: Array[String]) -> void:
	var actual: Variant = ProjectSettings.get_setting(key)
	print("SETTING %s=%s" % [key, str(actual)])
	if actual != expected:
		failures.append("%s expected=%s actual=%s" % [key, str(expected), str(actual)])
