extends GutTest
## EventBus autoload exists and its signals match the M1 + MVP list.

const EXPECTED_ARGS: Dictionary[String, int] = {
	"hull_changed": 2,
	"fuel_changed": 2,
	"energy_changed": 2,
	"heat_changed": 2,
	"slot_selected": 1,
	"cargo_added": 2,
	"cargo_rejected": 3,
	"player_died": 0,
	"player_respawned": 0,
	"mining_beam_started": 2,
	"mining_beam_stopped": 0,
	"mining_beam_updated": 2,
	"asteroid_damaged": 3,
	"asteroid_destroyed": 2,
	"ore_spawned": 3,
	"ore_collected": 3,
	"cargo_changed": 2,
	"cargo_sold": 2,
	"credits_changed": 1,
	"dock_entered": 0,
	"dock_exited": 0,
	"station_panel_toggled": 1,
	"part_upgraded": 2,
	"upgrade_failed": 2,
	"ship_stats_changed": 1,
}


func _bus() -> Node:
	return get_tree().root.get_node_or_null(^"EventBus")


func test_autoload_registered() -> void:
	assert_true(ProjectSettings.has_setting("autoload/EventBus"))
	var path: String = ProjectSettings.get_setting("autoload/EventBus")
	assert_eq(path, "*res://scripts/core/event_bus.gd")
	assert_not_null(_bus(), "EventBus node in tree")


func test_signals_and_arg_counts() -> void:
	var bus := _bus()
	if bus == null:
		fail_test("EventBus missing")
		return
	for signal_name: String in EXPECTED_ARGS:
		assert_true(bus.has_signal(signal_name), signal_name)
	for info: Dictionary in bus.get_signal_list():
		var signal_name: String = info["name"]
		if EXPECTED_ARGS.has(signal_name):
			var args: Array = info["args"]
			assert_eq(args.size(), EXPECTED_ARGS[signal_name], "%s arg count" % signal_name)


func test_emit_reaches_listener() -> void:
	var bus := _bus()
	watch_signals(bus)
	bus.emit_signal(&"cargo_rejected", &"gas_test", 1, &"NO_STORAGE_FOR_PHASE")
	assert_signal_emitted_with_parameters(bus, "cargo_rejected", [&"gas_test", 1, &"NO_STORAGE_FOR_PHASE"])
