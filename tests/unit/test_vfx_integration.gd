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


func test_beam_with_node_origin_and_no_target() -> void:
	var origin := Node3D.new()
	add_child_autofree(origin)
	origin.global_position = Vector3(3, 0, 4)
	EventBus.mining_beam_started.emit(origin, null)
	assert_true(director.beam.active)
	assert_almost_eq(director.beam.target_point, Vector3(3, 0, 4), Vector3.ONE * 0.001)
	EventBus.mining_beam_updated.emit(origin, Vector3(3, 0, -6))
	assert_almost_eq(director.beam.target_point, Vector3(3, 0, -6), Vector3.ONE * 0.001)
	var rock := Node3D.new()
	add_child_autofree(rock)
	EventBus.asteroid_damaged.emit(rock, Vector3(3, 0, -5), 0.5)
	assert_almost_eq(director.beam.target_point, Vector3(3, 0, -5), Vector3.ONE * 0.001)
	assert_true(director.beam.hitting)
	EventBus.mining_beam_stopped.emit()


func test_ore_spawned_by_position_adds_glow() -> void:
	var pickup := Node3D.new()
	pickup.add_to_group(&"ore_pickups")
	add_child_autofree(pickup)
	pickup.global_position = Vector3(10, 0, 2)
	EventBus.ore_spawned.emit(Vector3(10, 0, 2), &"iron_ore", 2)
	assert_eq(pickup.find_children("*", "OreGlow", true, false).size(), 1)


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
