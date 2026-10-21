class_name MvpBalanceSim
extends RefCounted
## MVP economy pacing model (docs/briefs/mvp_balance.md §4). Reads the real game
## data the MVP scene uses: ship + parts, laser, flight tuning and the sector
## (data/sectors/mvp_sector_01.tres -> asteroid types/counts, resources/prices,
## ring, respawn) and simulates:
## undock -> fly to field -> laser asteroids until cargo is full -> fly back ->
## sell -> buy upgrades -> repeat. Field depletion + respawn is modelled.
## Deterministic per seed. Player assumptions are the profile vars below:
## "bot" is calibrated to the real-scene autopilot (tests/tools/real_loop_bot.gd,
## perfect aim, nearest asteroid), "human" (default, used for pacing) adds
## new-player losses on top of it.

const HULL_PATH := "res://data/ships/starter_shuttle_01.tres"
const LASER_PATH := "res://data/modules/laser_mk1.tres"
const FLIGHT_PATH := "res://data/ships/starter_flight_tuning.tres"
const SECTOR_PATH := "res://data/sectors/mvp_sector_01.tres"
const CREDITS := &"credits"

## --- player / route assumptions (balance_prototype) ---
## Real MVP scene measured by tests/tools/run_real_loop_measure.gd (autopilot
## real_loop_bot.gd, eng/mvp-integration 3aff395 + v0.3 costs, seeds 0/11/22/33/44):
## medians of the 14 L1 runs (s, credits) and of the 5 upgrade timelines (s).
## The "bot" profile must stay within 20 % of these (run_mvp_balance_sim.gd).
const MEASURED_REAL := {"run": 77.0, "fly": 22.0, "mine": 32.0, "collect": 16.0, "dock": 5.0,
	"credits": 152.0, "first": 220.0, "first_l3": 573.0, "full": 1353.0}
const PROFILE_HUMAN := &"human"
const PROFILE_BOT := &"bot"
const STANDOFF_M := 6.0 ## player mines from ~6 m (laser range 10 m)
const RETURN_EXTRA := 1.1 ## return leg a bit longer (drifted deeper while mining)
const CLUSTER_HOP_M := 22.0 ## extra flight when the current cluster is used up
const TURN_DEG := 100.0 ## mean nose turn to the next target
const DOCK_S := 3.0 ## slow down inside the dock radius + press E
const UNDOCK_S := 1.5
const SELL_S := 2.0 ## open panel, "sell all"
const SHOP_S_PER_BUY := 3.0
const RETURN_WHEN_FREE_BELOW := 2 ## u; do not start a new asteroid for less

## Reference buy plan ("economy first" player): mining power and cargo first,
## then the first L3 (Head), then mobility. The sim saves for the next step and
## buys it as soon as it is affordable (several per dock if credits allow).
const PLAN_ECONOMY_FIRST: Array[StringName] = [&"head", &"body", &"head", &"engine", &"wings", &"body", &"engine", &"wings"]

var hull: ShipHullDefinition
var laser: MiningLaserDefinition
var flight: FlightTuning
## Sector data in plain dictionaries: {"resources", "asteroids", "sector"}.
var proposal: Dictionary = {}
var profile: StringName = PROFILE_HUMAN
var travel_eff: float = 0.8 ## mean speed / flying_speed on station <-> field legs
var hop_eff: float = 0.5 ## mean speed / flying_speed on short hops between asteroids
var aim_eff: float = 0.85 ## fraction of trigger time the beam is on target
var field_depth: float = 0.35 ## mean mining distance = ring_min + depth * (ring_max - ring_min)
var reaction_s: float = 0.5
var collect_base_s: float = 1.5 ## wait for the magnet after a break
var collect_per_pickup_s: float = 0.15
var prices: Dictionary[StringName, int] = {}
var speed_delta: float = 0.0 ## m/s added to the resolved flying_speed (cruise sweep)
var cost_scale: float = 1.0 ## multiplies every upgrade cost (what-if)


class RunRow:
	extends RefCounted
	var index: int
	var start_t: float
	var duration: float
	var fly_t: float
	var mine_t: float ## laser time (incl. collect_t)
	var collect_t: float
	var dock_t: float
	var asteroids: int
	var units: int
	var credits: int
	var levels: String


class Result:
	extends RefCounted
	var runs: Array[RunRow] = []
	var buys: Array[Dictionary] = []
	var first_upgrade_t: float = -1.0
	var first_l3_t: float = -1.0
	var all_l2_t: float = -1.0
	var full_l3_t: float = -1.0
	var total_cost: int = 0


class Rock:
	extends RefCounted
	var def: Dictionary
	var ready_at: float = 0.0


func _init() -> void:
	hull = load(HULL_PATH)
	laser = load(LASER_PATH)
	flight = load(FLIGHT_PATH)
	proposal = load_sector_data(load(SECTOR_PATH) as SectorDefinition)
	set_profile(PROFILE_HUMAN)
	for r: Dictionary in proposal["resources"]:
		prices[StringName(str(r["id"]))] = _i(r["sell_price"])


## "bot": calibrated on the real MVP scene (real_loop_bot.gd, 5 seeds, eng
## 3aff395). "human": the same route with new-player losses (aim, detours,
## slower pickup chasing). Pacing targets are checked on "human".
func set_profile(p: StringName) -> void:
	profile = p
	if p == PROFILE_BOT:
		travel_eff = 1.0
		hop_eff = 0.6
		aim_eff = 1.0
		field_depth = 0.3
		reaction_s = 0.3
		collect_base_s = 1.6
		collect_per_pickup_s = 0.25
	else:
		travel_eff = 0.8
		hop_eff = 0.5
		aim_eff = 0.85
		field_depth = 0.35
		reaction_s = 0.5
		collect_base_s = 1.8
		collect_per_pickup_s = 0.25


## Real sector resource -> the plain dictionaries the model works on.
static func load_sector_data(sec: SectorDefinition) -> Dictionary:
	var res: Array[Dictionary] = []
	for r: ResourceDefinition in sec.resources:
		res.append({"id": r.id, "sell_price": r.sell_price})
	var ast: Array[Dictionary] = []
	for i in sec.asteroid_types.size():
		var a: AsteroidDefinition = sec.asteroid_types[i]
		var count: int = sec.asteroid_counts[i] if i < sec.asteroid_counts.size() else 0
		var f := a.secondary_fraction if a.secondary_ore != null else 0.0
		var unit_value := a.ore.sell_price * (1.0 - f) + (a.secondary_ore.sell_price * f if f > 0.0 else 0.0)
		ast.append({"id": a.id, "size": a.size, "radius": a.radius, "max_hp": a.max_hp, "unit_value": unit_value,
			"ore": a.ore.id, "ore_units": (a.ore_units_min + maxi(a.ore_units_min, a.ore_units_max)) * 0.5,
			"units_per_pickup_min": a.units_per_pickup_min, "units_per_pickup_max": a.units_per_pickup_max,
			"count": count})
	return {"resources": res, "asteroids": ast, "sector": {
		"ring_min_radius": sec.ring_min_radius, "ring_max_radius": sec.ring_max_radius,
		"cluster_size": [sec.cluster_size_min, sec.cluster_size_max], "min_gap": sec.min_gap,
		"respawn_delay": sec.respawn_delay, "starting_credits": sec.starting_credits}}


func next_cost(state: ShipInstanceState, part: StringName) -> int:
	var def := hull.get_part(ShipPartDefinition.SLOT_KEYS.find(part) as ShipPartDefinition.Slot)
	if not state.can_upgrade(part, def):
		return -1
	var lvl := def.get_level(state.part_levels[part] + 1)
	var c := 0
	for e: CostEntry in lvl.cost:
		if e.item_id == CREDITS:
			c += e.amount
	return roundi(c * cost_scale)


func total_upgrade_cost() -> int:
	var s := ShipInstanceState.create_for(hull)
	var sum := 0
	for part: StringName in ShipPartDefinition.SLOT_KEYS:
		var def := hull.get_part(ShipPartDefinition.SLOT_KEYS.find(part) as ShipPartDefinition.Slot)
		while s.can_upgrade(part, def):
			sum += next_cost(s, part)
			s.part_levels[part] += 1
	return sum


func field_value() -> Dictionary:
	var units := 0
	var credits := 0
	var hp := 0.0
	for a: Dictionary in proposal["asteroids"]:
		var n := _i(a["count"])
		units += n * _i(a["ore_units"])
		credits += n * _i(a["ore_units"]) * prices[StringName(str(a["ore"]))]
		hp += n * _f(a["max_hp"])
	return {"units": units, "credits": credits, "hp": hp}


func _travel(d: float, v: float, eff: float) -> float:
	return d / maxf(v * eff, 0.1) + flight.accel_time_to_max * 0.5


func simulate(seed_value: int, max_time_s: float = 5400.0, plan: Array[StringName] = PLAN_ECONOMY_FIRST) -> Result:
	var res := Result.new()
	res.total_cost = total_upgrade_cost()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var sector: Dictionary = proposal["sector"]
	var cluster_min := _i(sector["cluster_size"][0])
	var cluster_max := _i(sector["cluster_size"][1])
	var respawn := _f(sector["respawn_delay"])
	var rocks: Array[Rock] = []
	for a: Dictionary in proposal["asteroids"]:
		for i in _i(a["count"]):
			var r := Rock.new()
			r.def = a
			rocks.append(r)
	var state := ShipInstanceState.create_for(hull)
	var credits := _i(sector["starting_credits"])
	var t := 0.0
	var run_i := 0
	var step := 0
	var out_d := _f(sector["ring_min_radius"]) + (_f(sector["ring_max_radius"]) - _f(sector["ring_min_radius"])) * field_depth - STANDOFF_M
	while t < max_time_s:
		var stats := ShipStatsResolver.resolve(hull, state)
		var v: float = stats[ShipStat.FLYING_SPEED] + speed_delta
		var turn_s := TURN_DEG / maxf(stats[ShipStat.MANEUVER_SPEED], 1.0) + reaction_s
		var dps: float = laser.damage_per_second(stats[ShipStat.MINING_POWER]) * aim_eff
		var cap := int(minf(stats[ShipStat.CARRY_CAPACITY], stats[ShipStat.STORAGE_SOLID]))
		var row := RunRow.new()
		row.index = run_i + 1
		row.start_t = t
		row.levels = "H%d B%d W%d E%d" % [state.part_levels[&"head"], state.part_levels[&"body"], state.part_levels[&"wings"], state.part_levels[&"engine"]]
		var fly := UNDOCK_S + _travel(out_d, v, travel_eff)
		var mine := 0.0
		var used := 0
		var value := 0
		var in_cluster := 0
		var cluster_len := rng.randi_range(cluster_min, cluster_max)
		while used <= cap - RETURN_WHEN_FREE_BELOW:
			var now := t + fly + mine
			var avail: Array[Rock] = []
			for r: Rock in rocks:
				if r.ready_at <= now:
					avail.append(r)
			if avail.is_empty():
				mine += 5.0 # field empty: wait for respawns
				continue
			var rock := avail[rng.randi_range(0, avail.size() - 1)]
			var a := rock.def
			var radius := _f(a["radius"])
			var hop := _f(sector["min_gap"]) + radius * 2.0
			if in_cluster >= cluster_len:
				hop += CLUSTER_HOP_M
				in_cluster = 0
				cluster_len = rng.randi_range(cluster_min, cluster_max)
			in_cluster += 1
			fly += _travel(hop, v, hop_eff) + turn_s
			var tm := laser.spin_up + _f(a["max_hp"]) / maxf(dps, 0.001)
			var units := _i(a["ore_units"])
			var per_pickup := (_i(a["units_per_pickup_min"]) + _i(a["units_per_pickup_max"])) * 0.5
			var ct := collect_base_s + collect_per_pickup_s * ceilf(units / per_pickup)
			tm += ct
			row.collect_t += ct
			var take := mini(units, cap - used)
			used += take
			value += roundi(take * _f(a["unit_value"])) if a.has("unit_value") else take * prices[StringName(str(a["ore"]))]
			mine += tm
			row.asteroids += 1
			rock.ready_at = t + fly + mine + respawn
		fly += _travel(out_d * RETURN_EXTRA, v, travel_eff)
		credits += value
		var dock := DOCK_S + SELL_S
		while step < plan.size():
			var part: StringName = plan[step]
			var c := next_cost(state, part)
			if c < 0:
				step += 1
				continue
			if c > credits:
				break
			credits -= c
			state.part_levels[part] += 1
			step += 1
			dock += SHOP_S_PER_BUY
			var at := t + fly + mine + dock
			res.buys.append({"part": part, "level": state.part_levels[part], "t": at, "cost": c})
			if res.first_upgrade_t < 0.0:
				res.first_upgrade_t = at
			if res.first_l3_t < 0.0 and state.part_levels[part] >= ShipHullDefinition.MAX_PART_LEVEL:
				res.first_l3_t = at
		row.fly_t = fly
		row.mine_t = mine
		row.dock_t = dock
		row.duration = fly + mine + dock
		row.units = used
		row.credits = value
		res.runs.append(row)
		t += row.duration
		run_i += 1
		if res.all_l2_t < 0.0 and _min_level(state) >= 2:
			res.all_l2_t = t
		if _min_level(state) >= ShipHullDefinition.MAX_PART_LEVEL:
			res.full_l3_t = t
			break
	return res


func _min_level(state: ShipInstanceState) -> int:
	var m := ShipHullDefinition.MAX_PART_LEVEL
	for p: StringName in ShipPartDefinition.SLOT_KEYS:
		m = mini(m, state.part_levels[p])
	return m


static func _f(v: Variant) -> float:
	var f: float = v
	return f


static func _i(v: Variant) -> int:
	var f: float = v
	return roundi(f)
