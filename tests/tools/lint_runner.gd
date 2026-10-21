extends SceneTree
## Loads every project script once (autoloads registered, so EventBus /
## GameState resolve) and reports scripts that fail to compile. Run through
## lint_strict.sh, which turns warnings into errors with override.cfg.

const ROOTS: Array[String] = ["res://scripts", "res://tests"]


func _initialize() -> void:
	var files: Array[String] = []
	for dir: String in ROOTS:
		_collect(dir, files)
	files.sort()
	var failed := 0
	for path: String in files:
		if path == get_script().resource_path:
			continue
		printerr("== %s" % path)
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			failed += 1
			printerr("LINT FAIL %s" % path)
	print("lint_runner: %d scripts, %d failed" % [files.size(), failed])
	quit(1 if failed > 0 else 0)


func _collect(dir: String, out: Array[String]) -> void:
	for sub: String in DirAccess.get_directories_at(dir):
		_collect(dir.path_join(sub), out)
	for f: String in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
