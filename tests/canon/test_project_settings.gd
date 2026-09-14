extends GutTest


func test_application_settings_match_t02_contract() -> void:
	assert_eq(
		ProjectSettings.get_setting("application/config/name"),
		"Galapagos The Origin"
	)
	assert_eq(ProjectSettings.get_setting("application/config/version"), "0.1.0")
	assert_eq(
		ProjectSettings.get_setting("application/run/main_scene"),
		"res://presentation/boot/boot.tscn"
	)
	assert_eq(ProjectSettings.get_setting("application/config/icon"), "res://icon.svg")


func test_feature_metadata_uses_native_godot_tags() -> void:
	var actual_features: PackedStringArray = ProjectSettings.get_setting(
		"application/config/features"
	)
	var expected_features: PackedStringArray = PackedStringArray(["4.7", "GL Compatibility"])
	assert_eq(actual_features, expected_features)


func test_window_settings_match_pixel_contract() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 320)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 180)
	assert_eq(ProjectSettings.get_setting("display/window/size/window_width_override"), 1280)
	assert_eq(ProjectSettings.get_setting("display/window/size/window_height_override"), 720)
	assert_false(ProjectSettings.get_setting("display/window/size/resizable"))
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "keep")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/scale_mode"), "integer")


func test_rendering_settings_match_pixel_contract() -> void:
	assert_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method"), "gl_compatibility")
	assert_eq(
		ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile"),
		"gl_compatibility"
	)
	assert_eq(
		ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"),
		0
	)
	assert_true(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel"))
	assert_true(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_vertices_to_pixel"))
	assert_eq(
		ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color"),
		Color(0, 0, 0, 1)
	)
