extends GutTest
## MVP world framework: data, asteroid break, pickup pool, asteroid field, dock.

const SECTOR := "res://data/sectors/mvp_sector_01.tres"
const ASTEROID_SCENE := "res://scenes/world/asteroid.tscn"
const STATION_SCENE := "res://scenes/world/station.tscn"

var sector: SectorDefinition
var pool: PickupPool


func _cargo_hull(capacity: float) -> ShipHullDefinition:
	return TestShips.make_hull({ShipStat.CARRY_CAPACITY: capacity, ShipStat.STORAGE_SOLID: capacity, ShipStat.MINING_POWER: 10.0}, {})


func before_each() -> void:
	sector = load(SECTOR) as SectorDefinition
	GameState.start_session(_cargo_hull(100.0), sector.resources, 0)
	pool = PickupPool.new()
	pool.tuning = load("res://data/loot/pickup_tuning.tres") as PickupTuning
	add_child_autofree(pool)


func _asteroid(def: AsteroidDefinition) -> Asteroid:
	var a := (load(ASTEROID_SCENE) as PackedScene).instantiate() as Asteroid
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	a.setup(def, rng, pool)
	add_child(a)
	return a


func test_sector_data() -> void:
	assert_eq(sector.get_total_asteroids(), 20)
	assert_eq(sector.asteroid_types.size(), sector.asteroid_counts.size())
	for def: AsteroidDefinition in sector.asteroid_types:
		assert_not_null(def.ore, "%s has ore" % def.id)
		assert_true([&"S", &"M", &"L"].has(def.get_size_name()))
	assert_eq(sector.resources.size(), 2)


func test_asteroid_breaks_and_drops_all_ore() -> void:
	var def := sector.asteroid_types[2] # asteroid_ore_m
	var a := _asteroid(def)
	assert_eq(a.size, def.get_size_name())
	watch_signals(EventBus)
	var hits := 0
	while not a.is_broken and hits < 1000:
		assert_true(a.apply_mining_damage(14.0 / 60.0, a.global_position))
		hits += 1
	assert_true(a.is_broken)
	assert_false(a.apply_mining_damage(1.0, Vector3.ZERO), "no damage after break")
	assert_signal_emitted(EventBus, "asteroid_damaged")
	assert_signal_emitted_with_parameters(EventBus, "asteroid_destroyed", [a.global_position, def.get_size_name()])
	assert_signal_emitted(EventBus, "ore_spawned")
	assert_eq(pool.get_total_units(def.ore.id), def.ore_units_max)


func test_asteroid_uses_model_when_present() -> void:
	var a := _asteroid(sector.asteroid_types[0])
	if ResourceLoader.exists(sector.asteroid_types[0].model_scene_paths[0]):
		assert_ne(a.model_path, "")
	assert_not_null(a.get_node_or_null(^"Visual"))
	a.queue_free()


func test_pool_collects_into_cargo_without_loss() -> void:
	GameState.start_session(_cargo_hull(5.0), sector.resources, 0)
	pool.spawn(Vector3.ZERO, &"ore_common_solid", 3)
	pool.spawn(Vector3.ZERO, &"ore_common_solid", 4)
	watch_signals(EventBus)
	var got := pool.collect_all()
	assert_eq(got, 5)
	assert_eq(GameState.get_cargo_amount(&"ore_common_solid"), 5)
	assert_eq(pool.get_total_units(), 2, "the rest stays in the world")
	assert_signal_emitted(EventBus, "ore_collected")
	assert_signal_emitted(EventBus, "cargo_rejected")


func test_pool_magnet_pulls_and_collects() -> void:
	var target := Node3D.new()
	add_child_autofree(target)
	target.position = Vector3(3.0, 0.0, 0.0)
	pool.target = target
	pool.spawn(Vector3.ZERO, &"ore_common_solid", 2)
	for i in 120:
		pool.step(1.0 / 60.0)
	assert_eq(GameState.get_cargo_amount(&"ore_common_solid"), 2)


func test_pool_does_not_pull_when_full() -> void:
	GameState.start_session(_cargo_hull(0.0), sector.resources, 0)
	var target := Node3D.new()
	add_child_autofree(target)
	target.position = Vector3(3.0, 0.0, 0.0)
	pool.target = target
	var p := pool.spawn(Vector3.ZERO, &"ore_common_solid", 2)
	for i in 120:
		pool.step(1.0 / 60.0)
	assert_eq(pool.get_total_units(), 2)
	assert_lt(p.position.distance_to(Vector3.ZERO), 0.5, "stays put")


func test_pool_cap_merges() -> void:
	pool.tuning = pool.tuning.duplicate() as PickupTuning
	pool.tuning.pool_max_active = 2
	pool.spawn(Vector3.ZERO, &"ore_common_solid", 1)
	pool.spawn(Vector3(5, 0, 0), &"ore_common_solid", 1)
	pool.spawn(Vector3(1, 0, 0), &"ore_common_solid", 3)
	assert_eq(pool.get_pickups().size(), 2)
	assert_eq(pool.get_total_units(), 5)


func test_asteroid_field_places_sector() -> void:
	var field := AsteroidField.new()
	field.sector = sector
	field.pickup_pool = pool
	add_child_autofree(field)
	field.spawn_all()
	var list := field.get_asteroids()
	assert_eq(list.size(), 20)
	for a: Asteroid in list:
		var d := a.position.distance_to(sector.station_position)
		assert_between(d, sector.ring_min_radius - 0.01, sector.ring_max_radius + 0.01)


func test_station_dock_signals_and_game_state() -> void:
	var station := (load(STATION_SCENE) as PackedScene).instantiate() as StationDock
	add_child_autofree(station)
	watch_signals(EventBus)
	station.set_docked(true)
	assert_signal_emitted(EventBus, "dock_entered")
	assert_true(GameState.docked)
	station.set_docked(false)
	assert_signal_emitted(EventBus, "dock_exited")
	assert_false(GameState.docked)
