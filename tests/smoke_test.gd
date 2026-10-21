extends SceneTree
## Headless smoke test for the MVP loop (docs/briefs/mvp.md §1): loads the main
## scene, then scripts the player through fly -> mine (real MiningLaser raycast)
## -> break -> collect (PickupPool magnet) -> dock (StationDock area) -> sell ->
## upgrade (GameState) and checks the ShipAssembler swapped the part model.
## The steps live in tests/smoke_runner.gd (loaded after the autoloads exist).
## Usage: godot --headless --path . --script res://tests/smoke_test.gd
## Exit code 0 = OK, 1 = failure.


func _initialize() -> void:
	var script := load("res://tests/smoke_runner.gd") as GDScript
	if script == null:
		push_error("SMOKE FAIL: cannot load tests/smoke_runner.gd")
		quit(1)
		return
	var runner: Node = script.new()
	runner.connect(&"finished", _on_finished)
	root.add_child.call_deferred(runner)


func _on_finished(code: int) -> void:
	quit(code)
