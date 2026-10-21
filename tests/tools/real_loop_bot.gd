extends Node
## Headless autopilot that plays the real MVP loop in scenes/main/mvp_sector.tscn
## (MvpGame, AsteroidField, PickupPool, StationDock, GameState economy, real
## MiningLaser) and logs every run: fly / mine / collect / dock split, ore by
## type, cargo used, credits earned, asteroids broken by size, pickups left.
## Entry: tests/tools/run_real_loop_measure.gd (run with --fixed-fps 60).
## Policy (same as MvpBalanceSim): nearest unbroken asteroid, collect its drop,
## return when fewer than RETURN_WHEN_FREE_BELOW units fit, sell, then buy the
## next step of the sim's plan when affordable (real GameState.try_upgrade).

signal finished(code: int)

const SECTOR_SCENE := "res://scenes/main/mvp_sector.tscn"
const RETURN_WHEN_FREE_BELOW := 2
const COLLECT_RADIUS := 22.0 ## m around the break point the bot chases pickups
const COLLECT_TIMEOUT := 12.0
const MINE_TIMEOUT := 40.0
const RUN_TIMEOUT := 600.0
const SELL_S := 2.0 ## UI time for E + Sell (the sim's SELL_S)
const SHOP_S_PER_BUY := 3.0
const ORE := &"ore_common_solid"

var seed_value: int = 0
var max_runs: int = 6
var max_time: float = 900.0
var stop_after_full_l3: bool = true
var game: MvpGame
var ship: ShipController
var laser: MiningLaser
var t: float = 0.0 ## simulated seconds (physics)
var phase: String = "fly"
var split: Dictionary[String, float] = {}
var rows: Array[Dictionary] = []
var buys: Array[Dictionary] = []
var spawned: Dictionary[StringName, int] = {}
var collected: Dictionary[StringName, int] = {}
var broken_by_size: Dictionary[StringName, int] = {}
var stuck_skips: int = 0
var _plan_step: int = 0
var _skip: Array[Asteroid] = []


func _ready() -> void:
	var packed := load(SECTOR_SCENE) as PackedScene
	game = packed.instantiate() as MvpGame
	if seed_value != 0:
		var sec := game.sector.duplicate() as SectorDefinition
		sec.rng_seed = seed_value
		game.sector = sec
		(game.get_node(^"AsteroidField") as AsteroidField).sector = sec
	add_child(game)
	EventBus.ore_spawned.connect(_on_spawned)
	EventBus.ore_collected.connect(_on_collected)
	EventBus.asteroid_destroyed.connect(_on_destroyed)
	_run.call_deferred()


func _physics_process(dt: float) -> void:
	t += dt
	split[phase] = split.get(phase, 0.0) + dt


func _on_spawned(_p: Vector3, item: StringName, amount: int) -> void:
	spawned[item] = spawned.get(item, 0) + amount


func _on_collected(item: StringName, amount: int, _p: Vector3) -> void:
	collected[item] = collected.get(item, 0) + amount


func _on_destroyed(_p: Vector3, radius: float) -> void:
	var s := &"S" if radius < 1.8 else (&"M" if radius < 3.3 else &"L")
	broken_by_size[s] = broken_by_size.get(s, 0) + 1


func _run() -> void:
	await get_tree().physics_frame
	ship = game.ship
	laser = game.laser
	ship.use_player_input = false
	laser.use_player_input = false
	var run := 0
	while run < max_runs and t < max_time:
		run += 1
		var row := await _one_run(run)
		rows.append(row)
		var n: int = row["asteroids"]
		if n == 0 or (stop_after_full_l3 and _plan_step >= MvpBalanceSim.PLAN_ECONOMY_FIRST.size()):
			break
	finished.emit(0)


func _one_run(index: int) -> Dictionary:
	var start := t
	split.clear()
	spawned.clear()
	collected.clear()
	broken_by_size.clear()
	var stats := GameState.get_stats()
	var row: Dictionary = {"run": index, "start": start, "levels": _levels(),
		"cap": GameState.get_cargo_capacity(), "dps": laser.damage_per_second(),
		"speed": stats.get(ShipStat.FLYING_SPEED, 0.0)}
	var asteroids := 0
	while GameState.free_units_for(ORE) >= RETURN_WHEN_FREE_BELOW and t - start < RUN_TIMEOUT:
		var rock := _pick_asteroid()
		if rock == null:
			break
		phase = "fly"
		var stand := laser.definition.beam_range * 0.55 + rock.radius
		await _fly_to(rock.global_position, stand, true, 30.0)
		await get_tree().physics_frame
		if not is_instance_valid(rock):
			continue
		phase = "mine"
		var at := rock.global_position
		var ok := await _mine(rock)
		if not ok:
			_skip.append(rock)
			stuck_skips += 1
			continue
		asteroids += 1
		phase = "collect"
		await _collect(at)
	var left := game.pickups.get_total_units()
	phase = "fly"
	var st := game.station
	var entrance := st.get_entrance_position()
	var outside := entrance + (entrance - st.global_position).normalized() * 8.0
	await _fly_to(outside, 4.0, true, 40.0)
	phase = "dock"
	await _fly_to(entrance, 2.0, false, 10.0)
	var guard := 0.0
	while not GameState.docked and guard < 12.0:
		await _fly_to(st.get_dock_pad_position(), 0.6, false, 2.0)
		await get_tree().physics_frame
		guard += 2.0
	await _wait_phys(SELL_S)
	var cargo := GameState.get_cargo()
	var used := GameState.get_cargo_used()
	var earned := GameState.sell_all_cargo() if GameState.docked else 0
	var plan := MvpBalanceSim.PLAN_ECONOMY_FIRST
	while _plan_step < plan.size():
		var part := plan[_plan_step]
		var cost := GameState.get_upgrade_cost(part)
		if cost < 0:
			_plan_step += 1
			continue
		if GameState.credits < cost:
			break
		if not GameState.try_upgrade(part):
			break
		buys.append({"part": part, "level": GameState.get_part_level(part), "cost": cost, "t": t})
		_plan_step += 1
		await _wait_phys(SHOP_S_PER_BUY)
	phase = "fly"
	await _fly_to(outside, 3.0, false, 8.0)
	row.merge({"duration": t - start, "fly": split.get("fly", 0.0), "mine": split.get("mine", 0.0),
		"collect": split.get("collect", 0.0), "dock": split.get("dock", 0.0), "asteroids": asteroids,
		"by_size": broken_by_size.duplicate(), "cargo": cargo, "used": used, "earned": earned,
		"credits": GameState.credits, "spawned": spawned.duplicate(), "collected": collected.duplicate(),
		"left_in_field": left})
	return row


func _levels() -> String:
	return "H%d B%d W%d E%d" % [GameState.get_part_level(&"head"), GameState.get_part_level(&"body"), GameState.get_part_level(&"wings"), GameState.get_part_level(&"engine")]


func _pick_asteroid() -> Asteroid:
	var best: Asteroid = null
	var best_d := INF
	for a: Asteroid in game.field.get_asteroids():
		if a.is_broken or _skip.has(a):
			continue
		var d := a.global_position.distance_to(ship.global_position)
		if d < best_d:
			best_d = d
			best = a
	return best


func _fly_to(to: Vector3, arrive: float, boost: bool, timeout: float) -> void:
	var tt := 0.0
	while tt < timeout:
		var off := to - ship.global_position
		off.y = 0.0
		var dist := off.length()
		var speed := ship.get_speed()
		if dist < arrive and speed < 1.5:
			break
		ship.has_aim = true
		ship.aim_point = to
		var facing := ship.get_forward().dot(off.normalized()) if dist > 0.01 else 1.0
		var stop_dist := speed * speed / 12.0 + arrive
		ship.in_brake = dist < stop_dist
		ship.in_thrust = 1.0 if facing > 0.8 and not ship.in_brake else 0.0
		ship.in_boost = boost and dist > 18.0 and facing > 0.95
		await get_tree().physics_frame
		tt += get_physics_process_delta_time()
	_idle()


func _mine(rock: Asteroid) -> bool:
	laser.wants_fire = true
	var tt := 0.0
	while is_instance_valid(rock) and not rock.is_broken and tt < MINE_TIMEOUT:
		ship.has_aim = true
		ship.aim_point = rock.global_position
		var dist := ship.global_position.distance_to(rock.global_position) - rock.radius
		var hitting := laser.hit_asteroid == rock
		ship.in_brake = hitting or dist < laser.definition.beam_range * 0.5
		ship.in_thrust = 0.0 if ship.in_brake else 0.5
		await get_tree().physics_frame
		tt += get_physics_process_delta_time()
	laser.wants_fire = false
	_idle()
	return not is_instance_valid(rock) or rock.is_broken


func _collect(around: Vector3) -> void:
	var tt := 0.0
	while tt < COLLECT_TIMEOUT:
		if GameState.free_units_for(ORE) <= 0:
			break
		var near: OrePickup = null
		var best := COLLECT_RADIUS
		for p: OrePickup in game.pickups.get_pickups():
			var d := p.global_position.distance_to(around)
			if d < best:
				best = d
				near = p
		if near == null:
			break
		ship.has_aim = true
		ship.aim_point = near.global_position
		var off := near.global_position - ship.global_position
		off.y = 0.0
		var facing := ship.get_forward().dot(off.normalized())
		ship.in_brake = ship.get_speed() > 5.0 and off.length() < 6.0
		ship.in_thrust = 0.7 if facing > 0.7 and not ship.in_brake else 0.0
		await get_tree().physics_frame
		tt += get_physics_process_delta_time()
	_idle()


func _idle() -> void:
	ship.in_thrust = 0.0
	ship.in_boost = false
	ship.in_brake = false


func _wait_phys(seconds: float) -> void:
	var tt := 0.0
	ship.in_brake = true
	while tt < seconds:
		await get_tree().physics_frame
		tt += get_physics_process_delta_time()
	ship.in_brake = false
