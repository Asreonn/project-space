extends SceneTree
## godot --headless --path . -s res://tests/tools/run_flight_metrics.gd
## Loads the metrics script at runtime so its EventBus-using dependencies
## compile after the autoloads are registered.


func _initialize() -> void:
	_go.call_deferred()


func _go() -> void:
	await process_frame
	var script: GDScript = load("res://tests/tools/flight_metrics.gd")
	var metrics: RefCounted = script.new()
	await metrics.call(&"run", self)
	quit(0)
