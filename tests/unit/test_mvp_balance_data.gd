extends GutTest
## MVP balance data (docs/briefs/mvp_balance.md): every data file loads,
## part levels are monotonic (L1 <= L2 <= L3; lower-is-better stats reversed),
## L3 equals the in-grade cap, credits-only costs (D-011), the first upgrade is
## felt, and the economy sim meets the pacing targets.

const HULL := "res://data/ships/starter_shuttle_01.tres"
const FLIGHT := "res://data/ships/starter_flight_tuning.tres"
const LASER := "res://data/modules/laser_mk1.tres"
const PROPOSAL := "res://data/balance/mvp_economy_proposal.json"
const LOWER_IS_BETTER: Array[StringName] = ShipStat.LOWER_IS_BETTER
const FIRST_UPGRADE_BAND := Vector2(180.0, 300.0)
const FIRST_L3_MAX := 600.0 ## s, median: first L3 of any part by 10:00
const FULL_L3_BAND := Vector2(1200.0, 1500.0) ## s, median: full starter L3 at ~20-25 min
const SEEDS := 15

var hull: ShipHullDefinition


func before_each() -> void:
	hull = load(HULL)


func test_all_mvp_data_loads() -> void:
	assert_true(load(HULL) is ShipHullDefinition, HULL)
	for key: StringName in ShipPartDefinition.SLOT_KEYS:
		var path := "res://data/parts/%s_starter_shuttle_01.tres" % key
		assert_true(load(path) is ShipPartDefinition, path)
	assert_true(load(FLIGHT) is FlightTuning, FLIGHT)
	assert_true(load(LASER) is MiningLaserDefinition, LASER)
	var proposal: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROPOSAL))
	assert_true(proposal is Dictionary, PROPOSAL)


func test_part_levels_are_monotonic() -> void:
	for slot: int in ShipPartDefinition.Slot.values():
		var part := hull.get_part(slot as ShipPartDefinition.Slot)
		assert_eq(part.levels.size(), 3, String(part.id))
		var prev: Dictionary[StringName, float] = {}
		for n: int in [1, 2, 3]:
			var cur := _mods(part.get_level(n))
			for stat: StringName in prev.keys():
				assert_true(cur.has(stat), "%s L%d keeps %s" % [part.id, n, stat])
				if LOWER_IS_BETTER.has(stat):
					assert_true(cur[stat] <= prev[stat], "%s L%d %s lower-is-better" % [part.id, n, stat])
				else:
					assert_true(cur[stat] >= prev[stat], "%s L%d %s >= L%d" % [part.id, n, stat, n - 1])
			prev = cur


func test_resolved_stats_monotonic_and_l3_is_cap() -> void:
	var l1 := ShipStatsResolver.resolve(hull, ShipInstanceState.create_for(hull, 1))
	var l2 := ShipStatsResolver.resolve(hull, ShipInstanceState.create_for(hull, 2))
	var l3_raw := ShipStatsResolver.resolve(hull, ShipInstanceState.create_for(hull, 3), false)
	for stat: StringName in l1.keys():
		var a: float = l1[stat]
		var b: float = l2[stat]
		var c: float = l3_raw[stat]
		assert_true(ShipStat.is_better_or_equal(stat, b, a) and ShipStat.is_better_or_equal(stat, c, b), String(stat))
	for stat: StringName in hull.upgrade_caps.keys():
		var raw: float = l3_raw[stat]
		var cap: float = hull.upgrade_caps[stat]
		assert_almost_eq(raw, cap, 0.001, "L3 = cap: %s" % stat)


func test_costs_are_credits_only_and_rise() -> void:
	for slot: int in ShipPartDefinition.Slot.values():
		var part := hull.get_part(slot as ShipPartDefinition.Slot)
		assert_eq(part.get_level(1).cost.size(), 0, "%s L1 free" % part.id)
		var c2 := _credits(part.get_level(2))
		var c3 := _credits(part.get_level(3))
		assert_gt(c2, 0, "%s L2 cost" % part.id)
		assert_gt(c3, c2, "%s L3 > L2" % part.id)
		for lvl: ShipPartLevel in part.levels:
			for e: CostEntry in lvl.cost:
				assert_eq(e.item_id, &"credits", "D-011 credits only")


func test_every_level_has_its_model() -> void:
	for slot: int in ShipPartDefinition.Slot.values():
		var part := hull.get_part(slot as ShipPartDefinition.Slot)
		for lvl: ShipPartLevel in part.levels:
			assert_true(ResourceLoader.exists(lvl.scene_path), lvl.scene_path)


func test_first_upgrade_is_felt() -> void:
	var l1 := ShipStatsResolver.resolve(hull, ShipInstanceState.create_for(hull, 1))
	var head2 := ShipInstanceState.create_for(hull, 1)
	head2.part_levels[&"head"] = 2
	var body2 := ShipInstanceState.create_for(hull, 1)
	body2.part_levels[&"body"] = 2
	var mp_gain: float = ShipStatsResolver.resolve(hull, head2)[ShipStat.MINING_POWER] / l1[ShipStat.MINING_POWER] - 1.0
	var cargo_gain: float = ShipStatsResolver.resolve(hull, body2)[ShipStat.CARRY_CAPACITY] / l1[ShipStat.CARRY_CAPACITY] - 1.0
	assert_true(mp_gain >= 0.29, "Head L2 mining_power +%d%%" % roundi(mp_gain * 100.0))
	assert_true(cargo_gain >= 0.29, "Body L2 cargo +%d%%" % roundi(cargo_gain * 100.0))
	# Head L2 is the cheapest L2, so the first purchase is the felt one.
	var head_cost := _credits(hull.head.get_level(2))
	for part: ShipPartDefinition in [hull.body, hull.wings, hull.engine]:
		assert_true(head_cost <= _credits(part.get_level(2)), "Head L2 cheapest vs %s" % part.id)


func test_pacing_targets() -> void:
	var sim := MvpBalanceSim.new()
	var firsts: Array[float] = []
	var first3s: Array[float] = []
	var fulls: Array[float] = []
	for sd in SEEDS:
		var r := sim.simulate(1000 + sd)
		firsts.append(r.first_upgrade_t)
		first3s.append(r.first_l3_t)
		fulls.append(r.full_l3_t)
	firsts.sort()
	fulls.sort()
	var f := firsts[SEEDS >> 1]
	var l := fulls[SEEDS >> 1]
	assert_between(f, FIRST_UPGRADE_BAND.x, FIRST_UPGRADE_BAND.y, "first upgrade median %.0f s" % f)
	assert_between(l, FULL_L3_BAND.x, FULL_L3_BAND.y, "full L3 median %.0f s" % l)
	first3s.sort()
	var f3 := first3s[SEEDS >> 1]
	assert_between(f3, 0.0, FIRST_L3_MAX, "first L3 median %.0f s" % f3)


func test_sim_bot_profile_matches_real_scene() -> void:
	var sim := MvpBalanceSim.new()
	sim.set_profile(MvpBalanceSim.PROFILE_BOT)
	var runs: Array[float] = []
	var credits: Array[float] = []
	var firsts: Array[float] = []
	for sd in SEEDS:
		var r := sim.simulate(1000 + sd)
		runs.append(r.runs[0].duration)
		credits.append(float(r.runs[0].credits))
		firsts.append(r.first_upgrade_t)
	var m := MvpBalanceSim.MEASURED_REAL
	for pair: Array in [["run", runs], ["credits", credits], ["first", firsts]]:
		var key: String = pair[0]
		var vals: Array[float] = []
		var src: Array = pair[1]
		vals.assign(src)
		vals.sort()
		var med := vals[vals.size() >> 1]
		var real: float = m[key]
		assert_almost_eq(med, real, real * 0.2, "sim bot %s vs real scene" % key)


static func _mods(lvl: ShipPartLevel) -> Dictionary[StringName, float]:
	var out: Dictionary[StringName, float] = {}
	for m: StatModifier in lvl.modifiers:
		out[m.stat] = out.get(m.stat, 0.0) + m.value
	return out


static func _credits(lvl: ShipPartLevel) -> int:
	var c := 0
	for e: CostEntry in lvl.cost:
		if e.item_id == &"credits":
			c += e.amount
	return c
