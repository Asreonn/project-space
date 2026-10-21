extends GutTest
## ShipDataValidator: ship_data_model.md v0.2.1 §6 rules 0-10 + MVP mode (D-011).

const STARTER_HULL := "res://data/ships/starter_shuttle_01.tres"
const MODE := ShipDataValidator.Mode

var hull: ShipHullDefinition


func before_each() -> void:
	# Deep copy so tests can break the data without touching the cached .tres.
	hull = (load(STARTER_HULL) as ShipHullDefinition).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)


## Mode matching the starter data: MVP once L2/L3 are authored, else the M1 contract.
func _starter_mode() -> ShipDataValidator.Mode:
	return MODE.MVP if hull.authored_up_to_level >= 3 else MODE.CONTRACT


func _validate(h: ShipHullDefinition = hull, mode: ShipDataValidator.Mode = _starter_mode()) -> ShipDataValidator.Result:
	return ShipDataValidator.validate_hull(h, mode, false)


func _has_error(r: ShipDataValidator.Result, needle: String) -> bool:
	for e in r.errors:
		if e.contains(needle):
			return true
	return false


func _credits(amount: int) -> CostEntry:
	var c := CostEntry.new()
	c.item_id = &"credits"
	c.amount = amount
	return c


func _ore(amount: int) -> CostEntry:
	var c := CostEntry.new()
	c.item_id = &"ore_common_solid"
	c.amount = amount
	return c


## Synthetic hull with all 3 levels authored; costs follow the given mode.
func _full_hull(mode: ShipDataValidator.Mode) -> ShipHullDefinition:
	var h := TestShips.make_hull({ShipStat.FUEL_CAPACITY: 100.0, ShipStat.FUEL_RATE: 0.2}, {ShipStat.FLYING_SPEED: 14.0})
	h.id = &"test_hull_01"
	for slot: int in ShipPartDefinition.Slot.values():
		var part := h.get_part(slot as ShipPartDefinition.Slot)
		var key := ShipPartDefinition.slot_key(slot as ShipPartDefinition.Slot)
		for n: int in [1, 2, 3]:
			var lvl := part.get_level(n)
			lvl.scene_path = "res://assets/models/ships/%s/%s_L%d.glb" % [h.id, key, n]
			lvl.modifiers = [TestShips.mod(ShipDataValidator.MAIN_STAT[key], 10.0 + n)]
			if slot == ShipPartDefinition.Slot.ENGINE:
				lvl.modifiers = [TestShips.mod(ShipStat.FLYING_SPEED, 11.0 + n)]
			if n == 2:
				lvl.cost.assign([_credits(120)] if mode == MODE.MVP else [_ore(40)])
			elif n == 3:
				lvl.cost.assign([_credits(300)] if mode == MODE.MVP else [_ore(80), _credits(300)])
	return h


func test_starter_ship_passes() -> void:
	var r := _validate()
	assert_true(r.is_ok(), str(r))


func test_starter_ship_catalog_passes() -> void:
	var hulls: Array[ShipHullDefinition] = [load(STARTER_HULL)]
	var r := ShipDataValidator.validate_catalog(hulls, _starter_mode(), false)
	assert_true(r.is_ok(), str(r))


func test_starter_models_exist_when_required() -> void:
	var r := ShipDataValidator.validate_hull(hull, _starter_mode(), true)
	assert_false(_has_error(r, "does not exist"), str(r))


func test_full_synthetic_hull_passes_both_modes() -> void:
	var mvp := ShipDataValidator.validate_hull(_full_hull(MODE.MVP), MODE.MVP, false)
	assert_true(mvp.is_ok(), str(mvp))
	var contract := ShipDataValidator.validate_hull(_full_hull(MODE.CONTRACT), MODE.CONTRACT, false)
	assert_true(contract.is_ok(), str(contract))


func test_mvp_mode_rejects_resource_costs() -> void:
	var r := ShipDataValidator.validate_hull(_full_hull(MODE.CONTRACT), MODE.MVP, false)
	assert_true(_has_error(r, "rule 5 (MVP"), str(r))


func test_contract_mode_rejects_credit_only_l2() -> void:
	var r := ShipDataValidator.validate_hull(_full_hull(MODE.MVP), MODE.CONTRACT, false)
	assert_true(_has_error(r, "rule 5"), str(r))


func test_levels_above_authored_are_warnings() -> void:
	var h := _full_hull(MODE.MVP)
	h.authored_up_to_level = 1
	for slot: int in ShipPartDefinition.Slot.values():
		var part := h.get_part(slot as ShipPartDefinition.Slot)
		part.authored_up_to_level = 1
		for n: int in [2, 3]:
			part.levels[n - 1].scene_path = ""
			part.levels[n - 1].cost.clear()
			part.levels[n - 1].modifiers.clear()
	var r := ShipDataValidator.validate_hull(h, MODE.CONTRACT, false)
	assert_true(r.is_ok(), str(r))
	assert_gt(r.warnings.size(), 0)
	h.authored_up_to_level = 3
	for slot: int in ShipPartDefinition.Slot.values():
		h.get_part(slot as ShipPartDefinition.Slot).authored_up_to_level = 3
	r = ShipDataValidator.validate_hull(h, MODE.MVP, false)
	assert_true(_has_error(r, "rule 4"))
	assert_true(_has_error(r, "rule 5"))


func test_rule0_part_authored_above_hull() -> void:
	var h := _full_hull(MODE.MVP)
	h.authored_up_to_level = 2
	assert_true(_has_error(ShipDataValidator.validate_hull(h, MODE.MVP, false), "rule 0"))


func test_rule1_missing_part() -> void:
	hull.wings = null
	assert_true(_has_error(_validate(), "rule 1"))


func test_rule1_slot_mismatch() -> void:
	hull.head.slot = ShipPartDefinition.Slot.ENGINE
	assert_true(_has_error(_validate(), "rule 1"))


func test_rule2_foreign_part() -> void:
	hull.engine.hull_id = &"other_ship_01"
	assert_true(_has_error(_validate(), "rule 2"))


func test_rule2_part_shared_between_hulls() -> void:
	var other: ShipHullDefinition = hull.duplicate()
	other.id = &"other_ship_01"
	var hulls: Array[ShipHullDefinition] = [hull, other]
	var r := ShipDataValidator.validate_catalog(hulls, _starter_mode(), false)
	assert_true(_has_error(r, "rule 2"), str(r))


func test_part_id_pattern() -> void:
	hull.head.id = &"starter_shuttle_01_head"
	assert_true(_has_error(_validate(), "should be 'head_starter_shuttle_01'"))


func test_rule3_level_order() -> void:
	hull.body.levels[0].level = 3
	assert_true(_has_error(_validate(), "rule 3"))


func test_rule4_bad_scene_path() -> void:
	hull.head.levels[0].scene_path = "res://models/head.glb"
	assert_true(_has_error(_validate(), "rule 4"))


func test_rule5_l1_cost_must_be_empty() -> void:
	hull.head.levels[0].cost = [_credits(10)]
	assert_true(_has_error(_validate(), "rule 5"))


func test_rule6_cap_exceeded() -> void:
	hull.upgrade_caps[ShipStat.FLYING_SPEED] = 1.0
	assert_true(_has_error(_validate(), "rule 6"))


func test_rule6_l3_must_reach_cap() -> void:
	var h := _full_hull(MODE.MVP)
	h.upgrade_caps[ShipStat.FLYING_SPEED] = 20.0
	assert_true(_has_error(ShipDataValidator.validate_hull(h, MODE.MVP, false), "must equal cap"))


func test_rule6_lower_is_better_cap_is_a_floor() -> void:
	var h := _full_hull(MODE.MVP)
	h.base_stats[ShipStat.MASS] = 1.0
	h.upgrade_caps[ShipStat.MASS] = 2.0
	assert_true(_has_error(ShipDataValidator.validate_hull(h, MODE.MVP, false), "rule 6"))


func test_rule8_main_stat_must_not_drop() -> void:
	var h := _full_hull(MODE.MVP)
	h.head.levels[2].modifiers = [TestShips.mod(ShipStat.MINING_POWER, 1.0)]
	assert_true(_has_error(ShipDataValidator.validate_hull(h, MODE.MVP, false), "rule 8"))


func test_rule9_storage_above_carry() -> void:
	var h := _full_hull(MODE.MVP)
	h.body.levels[0].modifiers.append(TestShips.mod(ShipStat.STORAGE_SOLID, 500.0))
	assert_true(_has_error(ShipDataValidator.validate_hull(h, MODE.MVP, false), "rule 9"))


func test_rule7_fuel_in_base_stats() -> void:
	hull.base_stats.erase(ShipStat.FUEL_RATE)
	assert_true(_has_error(_validate(), "rule 7"))


func test_rule10_hardpoint_ids() -> void:
	hull.hardpoints = [&"hp_left", &"hp_right"]
	assert_true(_has_error(_validate(), "rule 10"))
	hull.hardpoints = [&"L", &"R", &"Top"]
	assert_true(_has_error(_validate(), "rule 10"))


func test_unknown_stat_key() -> void:
	hull.base_stats[&"flyng_speed"] = 1.0
	assert_false(_validate().is_ok())
