extends SceneTree
## Renders mvp_sector.tscn with the ship mining the nearest asteroid and saves
## a PNG. Needs a display (e.g. xvfb-run), not --headless:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script res://tests/tools/capture_mvp.gd -- out.png [--ortho=18] [--face=down]


func _initialize() -> void:
	var runner: Node = (load("res://tests/tools/capture_runner.gd") as GDScript).new()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--ortho="):
			runner.set(&"ortho_size", arg.trim_prefix("--ortho=").to_float())
		elif arg.begins_with("--face="):
			runner.set(&"face", arg.trim_prefix("--face="))
		else:
			runner.set(&"out_path", arg)
	runner.connect(&"finished", quit)
	root.add_child.call_deferred(runner)
