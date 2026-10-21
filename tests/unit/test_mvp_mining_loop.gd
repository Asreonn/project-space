extends GutTest
## Short MVP loop on the real player ship: the laser breaks an S asteroid,
## the ore is "collected" (pickups belong to the Engineer, so the stub hands the
## drop over directly), sold at the proposal price, and the credits of the sim's
## first runs afford the first upgrade, which swaps the Head model and raises dps.

const PLAYER_SHIP := "res://scenes/ship/player_ship.tscn"
const HULL := "res://data/ships/starter_shuttle_01.tres"
const PROPOSAL := "res://data/balance/mvp_economy_proposal.json"

var ship: ShipController
var laser: MiningLaser
var proposal: Dictionary
var started: Array[Vector3] = []
var stopped := 0


func before_each() -> void:
	proposal = JSON.parse_string(FileAccess.get_file_as_string(PROPOSAL))
	var packed: PackedScene = load(PLAYER_SHIP)
	ship = packed.instantiate() as ShipController
	ship.hull_definition = load(HULL)
	ship.use_player_input = false
	add_child_autofree(ship)
	laser = ship.get_node("MiningLaser") as MiningLaser
	laser.use_player_input = false
	started.clear()
	stopped = 0
	EventBus.mining_beam_started.connect(_on_started)
	EventBus.mining_beam_stopped.connect(_on_stopped)


func after_each() -> void:
	EventBus.mining_beam_started.disconnect(_on_started)
	EventBus.mining_beam_stopped.disconnect(_on_stopped)


func _on_started(origin: Vector3, _target: Vector3) -> void:
	started.append(origin)


func _on_stopped() -> void:
	stopped += 1


func _entry(id: String) -> Dictionary:
	for a: Dictionary in proposal["asteroids"]:
		if a["id"] == id:
			return a
	return {}


func _price(item: StringName) -> int:
	for r: Dictionary in proposal["resources"]:
		if StringName(str(r["id"])) == item:
			return _i(r["sell_price"])
	return 0


func test_ship_assembles_with_resolved_stats() -> void:
	await wait_physics_frames(2)
	assert_not_null(laser.assembler, "laser picked up the ship assembler")
	assert_almost_eq(ship.get_stat(ShipStat.FLYING_SPEED), 12.0, 0.001)
	assert_almost_eq(laser.mining_power, 10.0, 0.001)
	assert_almost_eq(laser.damage_per_second(), 14.0, 0.001)


func test_beam_breaks_small_asteroid_then_sell_and_upgrade() -> void:
	var entry := _entry("asteroid_rock_s")
	var rock := StubAsteroid.from_proposal(entry)
	add_child_autofree(rock)
	rock.global_position = Vector3(0.0, 0.0, -6.0) # 6 m ahead of the nose (-Z)
	await wait_physics_frames(2)

	laser.wants_fire = true
	var f0 := Engine.get_physics_frames()
	var guard := 0
	while not rock.is_broken and guard < 600:
		await wait_physics_frames(1)
		guard += 1
	var frames := Engine.get_physics_frames() - f0
	laser.wants_fire = false
	await wait_physics_frames(2)

	assert_true(rock.is_broken, "S asteroid broke")
	var hz := float(Engine.physics_ticks_per_second)
	var expected := laser.definition.spin_up + rock.max_hp / laser.damage_per_second()
	assert_almost_eq(float(frames) / hz, expected, 0.2, "break time ~ spin_up + HP / dps")
	assert_eq(started.size(), 1, "mining_beam_started once")
	assert_eq(stopped, 1, "mining_beam_stopped once")
	assert_null(laser.hit_asteroid, "beam released the broken asteroid")

	# collect + sell (economy service stand-in: sell_price * units)
	var cargo: Dictionary[StringName, int] = {rock.ore: rock.ore_units}
	var credits := 0
	for k: StringName in cargo.keys():
		credits += _price(k) * cargo[k]
	assert_gt(credits, 0, "S asteroid is worth something")

	# credits of the sim's first runs reach the first (Head L2) upgrade
	var sim := MvpBalanceSim.new()
	var r := sim.simulate(1000)
	var first_part: StringName = r.buys[0]["part"]
	assert_eq(first_part, &"head", "first purchase is the Head")
	var state := ShipInstanceState.create_for(ship.hull_definition)
	var cost := sim.next_cost(state, &"head")
	var earned := 0
	for row: MvpBalanceSim.RunRow in r.runs:
		earned += row.credits
		if earned >= cost:
			break
	assert_true(earned >= cost, "sim runs afford Head L2 (%d >= %d)" % [earned, cost])

	var old_path: String = laser.assembler.used_scene_paths[&"head"]
	var old_dps := laser.damage_per_second()
	ship.assembler.set_part_level(ShipPartDefinition.Slot.HEAD, 2)
	assert_ne(laser.assembler.used_scene_paths[&"head"], old_path, "head model swapped")
	assert_gt(laser.damage_per_second(), old_dps * 1.29, "Head L2 dps +30%")


static func _f(v: Variant) -> float:
	var f: float = v
	return f


static func _i(v: Variant) -> int:
	var f: float = v
	return roundi(f)
