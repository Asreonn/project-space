extends GutTest
## ShipAssembler: body first, other parts at body Socket_* transforms,
## per-part model swap, contract empties (ship_data_model.md §7).

const STARTER_HULL := "res://data/ships/starter_shuttle_01.tres"

var hull: ShipHullDefinition
var assembler: ShipAssembler


func before_each() -> void:
	hull = load(STARTER_HULL)
	assembler = ShipAssembler.new()
	add_child_autofree(assembler)
	assembler.build(hull)


func test_builds_four_parts_with_body_root() -> void:
	for slot: int in ShipPartDefinition.Slot.values():
		assert_not_null(assembler.get_part_node(slot), ShipPartDefinition.slot_key(slot))
	var body := assembler.get_part_node(ShipPartDefinition.Slot.BODY)
	assert_eq(body.transform, Transform3D.IDENTITY, "body origin = ship center")
	assert_eq(String(body.name), "Body")


func test_parts_sit_on_body_sockets() -> void:
	for slot: ShipPartDefinition.Slot in [ShipPartDefinition.Slot.HEAD, ShipPartDefinition.Slot.WINGS, ShipPartDefinition.Slot.ENGINE]:
		var socket := assembler.get_socket(slot)
		assert_not_null(socket, "Socket_%s" % ShipPartDefinition.slot_key(slot))
		assert_almost_eq(assembler.get_part_node(slot).global_position, socket.global_position, Vector3.ONE * 0.0001)


func test_no_invalid_legacy_names() -> void:
	for bad: String in ["PartSocket_*", "Socket_Body", "Hardpoint_hp_*", "FX_Thruster_*"]:
		assert_eq(assembler.find_children(bad, "", true, false).size(), 0, bad)


func test_hardpoints_and_fx_empties() -> void:
	for hp: StringName in hull.hardpoints:
		assert_not_null(assembler.find_hardpoint(hp), "Hardpoint_%s" % hp)
	assert_not_null(assembler.find_hardpoint(&"L"))
	assert_not_null(assembler.find_hardpoint(&"R"))
	var trails := assembler.get_engine_trail_points()
	assert_gt(trails.size(), 0)
	assert_eq(String(trails[0].name), "FX_EngineTrail_0")
	assert_not_null(assembler.get_mining_origin())


func test_missing_models_fall_back_to_placeholders() -> void:
	if ResourceLoader.exists(hull.head.levels[0].scene_path):
		pass_test("models delivered")
		return
	assert_true(assembler.is_placeholder(ShipPartDefinition.Slot.HEAD))


func test_stats_match_resolver() -> void:
	assert_eq(assembler.stats, ShipStatsResolver.resolve(hull, ShipInstanceState.create_for(hull)))


func test_set_part_level_swaps_only_that_part() -> void:
	watch_signals(assembler)
	var old_engine := assembler.get_part_node(ShipPartDefinition.Slot.ENGINE)
	var old_head := assembler.get_part_node(ShipPartDefinition.Slot.HEAD)
	assembler.set_part_level(ShipPartDefinition.Slot.ENGINE, 2)
	assert_eq(assembler.state.part_levels[&"engine"], 2)
	assert_ne(assembler.get_part_node(ShipPartDefinition.Slot.ENGINE), old_engine, "engine model swapped")
	assert_eq(assembler.get_part_node(ShipPartDefinition.Slot.HEAD), old_head, "head untouched")
	assert_signal_emitted_with_parameters(assembler, "part_level_changed", [ShipPartDefinition.Slot.ENGINE, 2])
	assert_signal_emitted(assembler, "stats_changed")


func test_body_swap_reseats_parts() -> void:
	assembler.set_part_level(ShipPartDefinition.Slot.BODY, 3)
	var socket := assembler.get_socket(ShipPartDefinition.Slot.ENGINE)
	assert_almost_eq(assembler.get_part_node(ShipPartDefinition.Slot.ENGINE).global_position, socket.global_position, Vector3.ONE * 0.0001)
	assert_eq(assembler.get_child_count(), 4)


func test_level_is_clamped() -> void:
	assembler.set_part_level(ShipPartDefinition.Slot.HEAD, 9)
	assert_eq(assembler.state.part_levels[&"head"], 3)


func test_head_points_to_nose() -> void:
	# Nose is -Z: the head socket must be in front of the ship center.
	assert_lt(assembler.get_socket(ShipPartDefinition.Slot.HEAD).position.z, 0.0)
	assert_gt(assembler.get_socket(ShipPartDefinition.Slot.ENGINE).position.z, 0.0)
