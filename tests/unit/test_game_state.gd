extends GutTest
## GameState autoload: cargo, credits, sell and upgrade API (mvp.md §5).

var ore: ResourceDefinition


func _make_hull() -> ShipHullDefinition:
	var h := TestShips.make_hull({ShipStat.CARRY_CAPACITY: 0.0, ShipStat.STORAGE_SOLID: 0.0}, {})
	for n: int in [1, 2, 3]:
		var lvl := h.body.get_level(n)
		lvl.modifiers = [TestShips.mod(ShipStat.CARRY_CAPACITY, 20.0 + 10.0 * n), TestShips.mod(ShipStat.STORAGE_SOLID, 20.0 + 10.0 * n)]
		if n > 1:
			var c := CostEntry.new()
			c.item_id = &"credits"
			c.amount = 100 * n
			lvl.cost = [c]
	return h


func before_each() -> void:
	ore = ResourceDefinition.new()
	ore.id = &"ore_test"
	ore.sell_price = 4
	GameState.start_session(_make_hull(), [ore] as Array[ResourceDefinition], 0)
	GameState.require_dock = false


func after_each() -> void:
	GameState.require_dock = true


func test_autoload_registered() -> void:
	var path: String = ProjectSettings.get_setting("autoload/GameState")
	assert_eq(path, "*res://scripts/core/game_state.gd")


func test_cargo_capacity_and_partial_accept() -> void:
	watch_signals(EventBus)
	assert_eq(GameState.get_cargo_capacity(), 30)
	assert_eq(GameState.add_cargo(&"ore_test", 25), 25)
	assert_eq(GameState.add_cargo(&"ore_test", 10), 5, "only 5 fit")
	assert_signal_emitted_with_parameters(EventBus, "cargo_rejected", [&"ore_test", 5, EventBus.REJECT_TOTAL_FULL])
	assert_signal_emitted_with_parameters(EventBus, "cargo_changed", [30, 30])
	assert_false(GameState.has_room_for(&"ore_test"))


func test_sell_all() -> void:
	GameState.add_cargo(&"ore_test", 10)
	watch_signals(EventBus)
	assert_eq(GameState.sell_all_cargo(), 40)
	assert_eq(GameState.credits, 40)
	assert_eq(GameState.get_cargo_units(), 0)
	assert_signal_emitted_with_parameters(EventBus, "cargo_sold", [10, 40])
	assert_signal_emitted_with_parameters(EventBus, "credits_changed", [40])


func test_upgrade_flow() -> void:
	watch_signals(EventBus)
	assert_eq(GameState.get_upgrade_cost(&"body"), 200)
	assert_false(GameState.try_upgrade(&"body"))
	assert_signal_emitted_with_parameters(EventBus, "upgrade_failed", [EventBus.UPGRADE_NOT_ENOUGH_CREDITS, &"body"])
	GameState.add_credits(500)
	var preview: Dictionary[StringName, float] = GameState.preview_stats(&"body")
	assert_eq(preview[ShipStat.CARRY_CAPACITY], 40.0)
	assert_true(GameState.try_upgrade(&"body"))
	assert_eq(GameState.get_part_level(&"body"), 2)
	assert_eq(GameState.credits, 300)
	assert_signal_emitted_with_parameters(EventBus, "part_upgraded", [&"body", 2])
	assert_signal_emitted(EventBus, "ship_stats_changed")
	assert_eq(GameState.get_cargo_capacity(), 40)
	assert_true(GameState.try_upgrade(&"body"))
	assert_eq(GameState.get_upgrade_cost(&"body"), -1)
	assert_false(GameState.try_upgrade(&"body"))
	assert_signal_emitted_with_parameters(EventBus, "upgrade_failed", [EventBus.UPGRADE_MAX_LEVEL, &"body"])


func test_upgrade_needs_dock() -> void:
	GameState.require_dock = true
	GameState.add_credits(500)
	assert_false(GameState.try_upgrade(&"body"))
	EventBus.dock_entered.emit()
	assert_true(GameState.try_upgrade(&"body"))
	EventBus.dock_exited.emit()
