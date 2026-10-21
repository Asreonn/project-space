extends SceneTree
## Headless smoke test: loads and instantiates the main scene, runs a few frames, exits.
## Usage: godot --headless --path . --script res://tests/smoke_test.gd
## Exit code 0 = OK, 1 = failure.

func _init() -> void:
	var main_path: String = ProjectSettings.get_setting("application/run/main_scene")
	var packed := load(main_path) as PackedScene
	if packed == null:
		push_error("SMOKE FAIL: cannot load %s" % main_path)
		quit(1)
		return
	var inst := packed.instantiate()
	root.add_child(inst)
	for i in 10:
		await process_frame
	print("SMOKE OK: %s" % main_path)
	quit(0)
