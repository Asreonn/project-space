extends GutTest
## ShipStatsResolver on the starter ship and on synthetic hulls.

const STARTER_HULL := "res://data/ships/starter_shuttle_01.tres"

var hull: ShipHullDefinition


func before_each() -> void:
	hull = load(STARTER_HULL)


func test_starter_hull_loads() -> void:
	assert_not_null(hull)
	assert_eq(hull.id, &"starter_shuttle_01")
	assert_eq(hull.native_grade, Grade.Value.E)
	assert_eq(hull.head.id, &"head_starter_shuttle_01")


func test_l1_adds_part_modifiers_to_base() -> void:
	var stats := ShipStatsResolver.resolve(hull, ShipInstanceState.create_for(hull))
	for stat: StringName in hull.base_stats.keys():
		assert_true(stats.has(stat), "resolved stats contain %s" % stat)
	var expected := hull.base_stats.duplicate()
	for slot: int in ShipPartDefinition.Slot.values():
		for m: StatModifier in hull.get_part(slot).get_level(1).modifiers:
			expected[m.stat] = expected.get(m.stat, 0.0) + m.value
	for stat: StringName in expected.keys():
		var v: float = expected[stat]
		if hull.upgrade_caps.has(stat):
			v = minf(v, hull.upgrade_caps[stat])
		assert_almost_eq(stats[stat], v, 0.0001, String(stat))


func test_primary_stats_come_from_matching_parts() -> void:
	# PDF mapping: Head -> damage, Engine -> flying_speed, Wings -> maneuver, Body -> carry.
	var stats := ShipStatsResolver.resolve(hull, ShipInstanceState.create_for(hull))
	assert_gt(stats[ShipStat.DAMAGE], hull.base_stats[ShipStat.DAMAGE])
	assert_gt(stats[ShipStat.FLYING_SPEED], hull.base_stats[ShipStat.FLYING_SPEED])
	assert_gt(stats[ShipStat.MANEUVER_SPEED], hull.base_stats[ShipStat.MANEUVER_SPEED])
	assert_gt(stats[ShipStat.CARRY_CAPACITY], hull.base_stats[ShipStat.CARRY_CAPACITY])


func test_fuel_stats_are_hull_base_values() -> void:
	var stats := ShipStatsResolver.resolve(hull, ShipInstanceState.create_for(hull))
	assert_eq(stats[ShipStat.FUEL_CAPACITY], hull.base_stats[ShipStat.FUEL_CAPACITY])
	assert_eq(stats[ShipStat.FUEL_RATE], hull.base_stats[ShipStat.FUEL_RATE])


func test_empty_l2_l3_do_not_change_base() -> void:
	# Synthetic hull: the MVP starter data fills L2/L3, so use empty levels here.
	hull = TestShips.make_hull(hull.base_stats.duplicate(), hull.upgrade_caps.duplicate())
	var l3 := ShipStatsResolver.resolve(hull, ShipInstanceState.create_for(hull, 3))
	for stat: StringName in hull.base_stats.keys():
		var cap: float = hull.upgrade_caps.get(stat, INF)
		assert_almost_eq(l3[stat], minf(hull.base_stats[stat], cap), 0.0001)


func test_add_then_mul_then_cap() -> void:
	var h := TestShips.make_hull({ShipStat.FLYING_SPEED: 10.0}, {ShipStat.FLYING_SPEED: 100.0})
	h.engine.levels[0].modifiers = [TestShips.mod(ShipStat.FLYING_SPEED, 2.0), TestShips.mod(ShipStat.FLYING_SPEED, 1.5, StatModifier.Op.MUL)]
	h.wings.levels[0].modifiers = [TestShips.mod(ShipStat.FLYING_SPEED, 2.0, StatModifier.Op.MUL)]
	var stats := ShipStatsResolver.resolve(h, ShipInstanceState.create_for(h))
	assert_almost_eq(stats[ShipStat.FLYING_SPEED], (10.0 + 2.0) * 1.5 * 2.0, 0.0001)
	h.upgrade_caps[ShipStat.FLYING_SPEED] = 20.0
	stats = ShipStatsResolver.resolve(h, ShipInstanceState.create_for(h))
	assert_almost_eq(stats[ShipStat.FLYING_SPEED], 20.0, 0.0001, "clamped to cap")
	var raw := ShipStatsResolver.resolve(h, ShipInstanceState.create_for(h), false)
	assert_almost_eq(raw[ShipStat.FLYING_SPEED], 36.0, 0.0001, "raw is not clamped")


func test_part_levels_select_level() -> void:
	var h := TestShips.make_hull({ShipStat.DAMAGE: 1.0}, {})
	for i in 3:
		h.head.levels[i].modifiers = [TestShips.mod(ShipStat.DAMAGE, float(i + 1) * 10.0)]
	var state := ShipInstanceState.create_for(h)
	state.part_levels[&"head"] = 2
	assert_almost_eq(ShipStatsResolver.resolve(h, state)[ShipStat.DAMAGE], 21.0, 0.0001)
	state.part_levels[&"head"] = 3
	assert_almost_eq(ShipStatsResolver.resolve(h, state)[ShipStat.DAMAGE], 31.0, 0.0001)


func test_stat_only_in_modifiers_is_resolved() -> void:
	var h := TestShips.make_hull({}, {})
	h.body.levels[0].modifiers = [TestShips.mod(ShipStat.STORAGE_GAS, 5.0)]
	assert_almost_eq(ShipStatsResolver.resolve(h, ShipInstanceState.create_for(h))[ShipStat.STORAGE_GAS], 5.0, 0.0001)


func test_instance_state_upgrade_limit() -> void:
	hull = TestShips.make_hull({}, {})
	var state := ShipInstanceState.create_for(hull)
	assert_true(state.can_upgrade(&"engine", hull.engine))
	state.part_levels[&"engine"] = 3
	assert_false(state.can_upgrade(&"engine", hull.engine))
	state.part_levels[&"engine"] = 1
	var m1_engine := hull.engine.duplicate() as ShipPartDefinition
	m1_engine.authored_up_to_level = 1
	assert_false(state.can_upgrade(&"engine", m1_engine), "authored_up_to_level limits upgrades")
