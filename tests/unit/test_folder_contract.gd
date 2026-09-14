extends GutTest

const MANIFEST_LAYERS: Dictionary = {
	"autoload/": "Autoload",
	"core/": "Core",
	"core/contracts/": "Core",
	"core/contracts/generated/": "Core",
	"core/state/": "Core",
	"core/save/": "Core",
	"core/save/dto/": "Core",
	"core/rng/": "Core",
	"core/events/": "Core",
	"core/loc/": "Core",
	"core/input/": "Core",
	"core/log/": "Core",
	"core/util/": "Core",
	"data/": "Data",
	"data/source/": "Data",
	"data/source/canon/": "Data",
	"data/source/loc/": "Data",
	"data/source/_registry/": "Data",
	"data/source/_schema/": "Data",
	"data/generated/": "Data",
	"systems/": "Systems",
	"presentation/": "Presentation",
	"presentation/boot/": "Presentation",
	"content/": "outside the layer graph",
	"tools/": "outside the layer graph",
	"tools/validators/": "outside the layer graph",
	"tools/generators/": "outside the layer graph",
	"tools/lint/": "outside the layer graph",
	"tools/evidence/": "outside the layer graph",
	"tests/": "outside the layer graph",
	"tests/unit/": "outside the layer graph",
	"tests/integration/": "outside the layer graph",
	"tests/canon/": "outside the layer graph",
	"tests/fixtures/": "outside the layer graph",
	"tests/fixtures/saves/": "outside the layer graph",
}

const PERMITTED_ROOTS: Array[String] = [
	".github",
	"addons",
	"autoload",
	"core",
	"content",
	"data",
	"docs",
	"presentation",
	"systems",
	"tests",
	"tools",
]

const IGNORED_ROOTS: Array[String] = [
	".git",
	".godot",
	"export",
	"evidence",
	".worktrees",
	".vscode",
	".idea",
]

# This test reads the filesystem via DirAccess.
# It does not prove tracked/untracked Git status.
# It is a filesystem root-shape guard only.
# Git/versioned-tree proof belongs to T03 PR-time verification.


func test_each_manifest_directory_exists() -> void:
	for directory: String in MANIFEST_LAYERS:
		assert_true(
			DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://" + directory)),
			"Missing manifest directory: %s" % directory,
		)


func test_each_manifest_directory_has_readme() -> void:
	for directory: String in MANIFEST_LAYERS:
		var readme_path: String = "res://%sREADME.md" % directory
		assert_true(FileAccess.file_exists(readme_path), "Missing ownership marker: %s" % readme_path)


func test_each_readme_has_exact_three_line_shape() -> void:
	for directory: String in MANIFEST_LAYERS:
		var readme_path: String = "res://%sREADME.md" % directory
		var contents: String = FileAccess.get_file_as_string(readme_path)
		var lines: PackedStringArray = contents.trim_suffix("\n").split("\n", true)
		var has_exact_shape: bool = (
			contents.ends_with("\n")
			and not contents.contains("\r")
			and contents.count("\n") == 3
			and lines.size() == 3
			and lines[0].begins_with("Layer: ")
			and lines[1].begins_with("Owner: ")
			and lines[2].begins_with("Never: ")
		)
		assert_true(has_exact_shape, "Invalid ownership marker shape: %s" % readme_path)


func test_each_readme_layer_matches_manifest() -> void:
	for directory: String in MANIFEST_LAYERS:
		var readme_path: String = "res://%sREADME.md" % directory
		var layer_line: String = FileAccess.get_file_as_string(readme_path).get_slice("\n", 0)
		assert_eq(layer_line, "Layer: %s" % MANIFEST_LAYERS[directory], readme_path)


func test_root_directory_shape_is_permitted_or_ignored() -> void:
	var root_directories: PackedStringArray = DirAccess.get_directories_at("res://")
	for directory: String in root_directories:
		assert_true(
			PERMITTED_ROOTS.has(directory) or IGNORED_ROOTS.has(directory),
			"Unexpected root directory: %s" % directory,
		)
