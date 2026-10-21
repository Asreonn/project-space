extends GutTest
## ShipDataValidator rules 1-7 (ship_data_model.md §6) + §7 naming.

const STARTER_HULL := "res://data/ships/starter_shuttle_01.tres"
const M1_AUTHORED_LEVEL := 1

var hull: ShipHullDefinition


func before_each() -> void:
	# Deep copy so tests can break the data without touching the cached .tres.
	hull = (load(STARTER_HULL) as ShipHullDefinition).duplicate_deep(Resource.DEEP_DUPLICATE_ALL)


func _validate(h: ShipHullDefinition = hull) -> ShipDataValidator.Result:
	return ShipDataValidator.validate_hull(h, M1_AUTHORED_LEVEL, false)


func _has_error(r: ShipDataValidator.Result, needle: String) -> bool:
	for e in r.errors:
		if e.contains(needle):
			return true
	return false


func test_starter_ship_passes_m1_validation() -> void:
	var r := _validate()
	assert_true(r.is_ok(), str(r))


func test_mvp_starter_ship_passes_full_content_validation() -> void:
	# MVP (D-011): all three levels authored, models delivered.
	var r := ShipDataValidator.validate_hull(load(STARTER_HULL) as ShipHullDefinition, 3, true)
	assert_true(r.is_ok(), str(r))


func test_starter_ship_catalog_passes() -> void:
	var hulls: Array[ShipHullDefinition] = [load(STARTER_HULL)]
	var r := ShipDataValidator.validate_catalog(hulls, M1_AUTHORED_LEVEL, false)
	assert_true(r.is_ok(), str(r))


func test_missing_models_are_warnings_in_m1_mode() -> void:
	var r := _validate()
	if not ResourceLoader.exists(hull.head.levels[0].scene_path):
		assert_gt(r.warnings.size(), 0)


func test_full_content_mode_flags_missing_l2_l3() -> void:
	# With the contract default (all 3 levels authored) a ship whose L2/L3 are
	# empty is incomplete. The MVP starter data fills L2/L3 (D-011), so empty them here.
	for slot: int in ShipPartDefinition.Slot.values():
		for n: int in [2, 3]:
			var lvl := hull.get_part(slot as ShipPartDefinition.Slot).get_level(n)
			lvl.scene_path = ""
			lvl.cost.clear()
			lvl.modifiers.clear()
	var r := ShipDataValidator.validate_hull(hull, 3, false)
	assert_false(r.is_ok())
	assert_true(_has_error(r, "rule 4"))
	assert_true(_has_error(r, "rule 5"))


func test_missing_models_are_errors_when_required() -> void:
	var r := ShipDataValidator.validate_hull(hull, M1_AUTHORED_LEVEL, true)
	if ResourceLoader.exists(hull.head.levels[0].scene_path):
		pass_test("models delivered")
	else:
		assert_true(_has_error(r, "rule 4"))


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
	var r := ShipDataValidator.validate_catalog(hulls, M1_AUTHORED_LEVEL, false)
	assert_true(_has_error(r, "rule 2"), str(r))


func test_part_id_pattern() -> void:
	hull.head.id = &"starter_shuttle_01_head"
	assert_true(_has_error(_validate(), "should be 'head_starter_shuttle_01'"))


func test_rule3_level_count() -> void:
	hull.body.levels.pop_back()
	assert_true(_has_error(_validate(), "rule 3"))


func test_rule3_level_order() -> void:
	hull.body.levels[1].level = 3
	assert_true(_has_error(_validate(), "rule 3"))


func test_rule4_bad_scene_path() -> void:
	hull.head.levels[0].scene_path = "res://models/head.glb"
	assert_true(_has_error(_validate(), "rule 4"))


func test_rule5_l1_cost_must_be_empty() -> void:
	var c := CostEntry.new()
	c.item_id = &"credits"
	c.amount = 10
	hull.head.levels[0].cost = [c]
	assert_true(_has_error(_validate(), "rule 5"))


func test_rule6_cap_exceeded() -> void:
	hull.upgrade_caps[ShipStat.FLYING_SPEED] = 1.0
	assert_true(_has_error(_validate(), "rule 6"))


func test_rule7_fuel_in_base_stats() -> void:
	hull.base_stats.erase(ShipStat.FUEL_RATE)
	assert_true(_has_error(_validate(), "rule 7"))


func test_unknown_stat_key() -> void:
	hull.base_stats[&"flyng_speed"] = 1.0
	assert_false(_validate().is_ok())


func test_old_hardpoint_names_rejected() -> void:
	hull.hardpoints = [&"hp_left", &"hp_right"]
	assert_false(_validate().is_ok())
