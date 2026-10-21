extends GutTest
## The VFX director accepts the EventBus signatures from mvp.md §6 (integration
## adapters in scripts/vfx/vfx_director.gd) and the sector scene wires it.

const DIRECTOR := "res://scenes/vfx/vfx_director.tscn"

var director: VfxDirector


func before_each() -> void:
	director = (load(DIRECTOR) as PackedScene).instantiate() as VfxDirector
	add_child_autofree(director)


func test_connects_to_bus_signals() -> void:
	for sig: StringName in [&"mining_beam_started", &"mining_beam_updated", &"mining_beam_stopped",
			&"asteroid_damaged", &"asteroid_destroyed", &"ore_spawned", &"ore_collected"]:
		assert_has(director.connected, sig)


func test_beam_follows_bus_signals() -> void:
	var origin := Node3D.new()
	add_child_autofree(origin)
	origin.global_position = Vector3(3, 0, 4)
	EventBus.mining_beam_started.emit(origin, null)
	assert_true(director.beam.active)
	EventBus.mining_beam_updated.emit(origin, Vector3(3, 0, -6))
	assert_almost_eq(director.beam.target_point, Vector3(3, 0, -6), Vector3.ONE * 0.001)
	EventBus.mining_beam_stopped.emit()
	assert_false(director.beam.active and director.beam.hitting)


func test_beam_source_is_the_mining_laser() -> void:
	var ship := Node3D.new()
	add_child_autofree(ship)
	var laser := MiningLaser.new()
	laser.use_player_input = false
	laser.definition = MiningLaserDefinition.new()
	ship.add_child(laser)
	EventBus.mining_beam_started.emit(laser, null)
	assert_eq(director._beam_source, laser, "director reads beam_end from MiningLaser")
	EventBus.mining_beam_stopped.emit()


func test_ore_spawned_by_position_decorates_pickup() -> void:
	if get_tree().current_scene == null:
		pending("VfxDirector decorates pickups only with a current_scene; covered by tests/smoke_test.gd")
		return
	var pool := PickupPool.new()
	add_child_autofree(pool)
	var p := pool.spawn(Vector3(10, 0, 2), &"ore_common_solid", 2)
	await wait_process_frames(3)
	assert_true(director._is_decorated(p), "glow/visual added to the pickup at the ore_spawned position")


func test_break_and_collect_take_contract_args() -> void:
	EventBus.asteroid_destroyed.emit(Vector3(1, 0, 1), 3.2)
	EventBus.ore_collected.emit(&"iron_ore", 1, Vector3(2, 0, 2))
	assert_almost_eq(VfxDirector.size_to_radius(3.2), 3.2, 0.001)


func test_sector_scene_has_vfx_nodes() -> void:
	var packed := load("res://scenes/main/mvp_sector.tscn") as PackedScene
	var state := packed.get_state()
	var names: Array[String] = []
	for i in state.get_node_count():
		names.append(String(state.get_node_name(i)))
	for n: String in ["VfxDirector", "SpaceBackground", "PostFx", "WorldEnvironment"]:
		assert_has(names, n)


## VFX contract (scenes/vfx/README.md): pickups are found by group, the beam
## end comes from the shooter's public beam_origin / beam_end.
func test_ore_pickups_join_group_ore_pickups() -> void:
	var pool := PickupPool.new()
	add_child_autofree(pool)
	var p := pool.spawn(Vector3.ZERO, &"ore_common_solid", 1)
	assert_true(p.is_in_group(&"ore_pickups"))
	assert_true(get_tree().get_nodes_in_group(&"ore_pickups").has(p))


func test_mining_laser_exposes_beam_origin_and_end() -> void:
	var laser := MiningLaser.new()
	autofree(laser)
	var names: Array[String] = []
	for prop: Dictionary in laser.get_property_list():
		var prop_name: String = prop["name"]
		names.append(prop_name)
	for n: String in ["beam_origin", "beam_end"]:
		assert_has(names, n, "MiningLaser.%s stays public" % n)
		assert_true(laser.get(n) is Vector3, "%s is a Vector3" % n)
