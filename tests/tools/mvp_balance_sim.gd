class_name MvpBalanceSim
extends RefCounted
## MVP economy pacing model (docs/briefs/mvp_balance.md §5). Reads the real ship
## data (.tres), the laser (.tres) and the asteroid / ore / sector proposal
## (data/balance/mvp_economy_proposal.json) and simulates:
## undock -> fly to field -> laser asteroids until cargo is full -> fly back ->
## sell -> buy upgrades -> repeat. Field depletion + respawn is modelled.
## Deterministic per seed. Player assumptions are the constants below.

const HULL_PATH := "res://data/ships/starter_shuttle_01.tres"
const LASER_PATH := "res://data/modules/laser_mk1.tres"
const FLIGHT_PATH := "res://data/ships/starter_flight_tuning.tres"
const PROPOSAL_PATH := "res://data/balance/mvp_economy_proposal.json"
const CREDITS := &"credits"

## --- player / route assumptions (balance_prototype) ---
const TRAVEL_EFF := 0.8 ## mean speed / flying_speed on station <-> field legs (no boost)
const HOP_EFF := 0.5 ## mean speed / flying_speed on short hops between asteroids
const AIM_EFF := 0.85 ## fraction of trigger time the beam is on target (new player)
const STANDOFF_M := 6.0 ## player mines from ~6 m (laser range 10 m)
const FIELD_DEPTH := 0.35 ## mean mining distance = ring_min + depth * (ring_max - ring_min)
const RETURN_EXTRA := 1.1 ## return leg a bit longer (drifted deeper while mining)
const CLUSTER_HOP_M := 22.0 ## extra flight when the current cluster is used up
const TURN_DEG := 100.0 ## mean nose turn to the next target
const REACTION_S := 0.5
const COLLECT_BASE_S := 1.5 ## wait for the magnet after a break
const COLLECT_PER_PICKUP_S := 0.15
const DOCK_S := 3.0 ## slow down inside the dock radius + press E
const UNDOCK_S := 1.5
const SELL_S := 2.0 ## open panel, "sell all"
const SHOP_S_PER_BUY := 3.0
const RETURN_WHEN_FREE_BELOW := 2 ## u; do not start a new asteroid for less

## Upgrade buy order when several parts are affordable.
const ORDER_MINER: Array[StringName] = [&"head", &"body", &"engine", &"wings"]

var hull: ShipHullDefinition
var laser: MiningLaserDefinition
var flight: FlightTuning
var proposal: Dictionary = {}
var prices: Dictionary[StringName, int] = {}
var speed_delta: float = 0.0 ## m/s added to the resolved flying_speed (cruise sweep)
var cost_scale: float = 1.0 ## multiplies every upgrade cost (what-if)


class RunRow:
	extends RefCounted
	var index: int
	var start_t: float
	var duration: float
	var fly_t: float
	var mine_t: float
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
	proposal = JSON.parse_string(FileAccess.get_file_as_string(PROPOSAL_PATH))
	for r: Dictionary in proposal["resources"]:
		prices[StringName(str(r["id"]))] = _i(r["sell_price"])


func next_cost(state: ShipInstanceState, part: StringName) -> int:
	if not state.can_upgrade(part):
		return -1
	var def := hull.get_part(ShipPartDefinition.SLOT_KEYS.find(part) as ShipPartDefinition.Slot)
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
		while s.can_upgrade(part):
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


func simulate(seed_value: int, max_time_s: float = 5400.0, order: Array[StringName] = ORDER_MINER) -> Result:
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
	var out_d := _f(sector["ring_min_radius"]) + (_f(sector["ring_max_radius"]) - _f(sector["ring_min_radius"])) * FIELD_DEPTH - STANDOFF_M
	while t < max_time_s:
		var stats := ShipStatsResolver.resolve(hull, state)
		var v: float = stats[ShipStat.FLYING_SPEED] + speed_delta
		var turn_s := TURN_DEG / maxf(stats[ShipStat.MANEUVER_SPEED], 1.0) + REACTION_S
		var dps: float = laser.damage_per_second(stats[ShipStat.MINING_POWER]) * AIM_EFF
		var cap := int(minf(stats[ShipStat.CARRY_CAPACITY], stats[ShipStat.STORAGE_SOLID]))
		var row := RunRow.new()
		row.index = run_i + 1
		row.start_t = t
		row.levels = "H%d B%d W%d E%d" % [state.part_levels[&"head"], state.part_levels[&"body"], state.part_levels[&"wings"], state.part_levels[&"engine"]]
		var fly := UNDOCK_S + _travel(out_d, v, TRAVEL_EFF)
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
			fly += _travel(hop, v, HOP_EFF) + turn_s
			var tm := laser.spin_up + _f(a["max_hp"]) / maxf(dps, 0.001)
			var units := _i(a["ore_units"])
			var per_pickup := (_i(a["units_per_pickup_min"]) + _i(a["units_per_pickup_max"])) * 0.5
			tm += COLLECT_BASE_S + COLLECT_PER_PICKUP_S * ceilf(units / per_pickup)
			var take := mini(units, cap - used)
			used += take
			value += take * prices[StringName(str(a["ore"]))]
			mine += tm
			row.asteroids += 1
			rock.ready_at = t + fly + mine + respawn
		fly += _travel(out_d * RETURN_EXTRA, v, TRAVEL_EFF)
		credits += value
		var dock := DOCK_S + SELL_S
		var bought := true
		while bought:
			bought = false
			for part: StringName in _order_candidates(state, order):
				var c := next_cost(state, part)
				if c >= 0 and c <= credits:
					credits -= c
					state.part_levels[part] += 1
					dock += SHOP_S_PER_BUY
					var at := t + fly + mine + dock
					res.buys.append({"part": part, "level": state.part_levels[part], "t": at, "cost": c})
					if res.first_upgrade_t < 0.0:
						res.first_upgrade_t = at
					bought = true
					break
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


## Lowest-level parts first (no L3 before every part is L2), then `order`.
func _order_candidates(state: ShipInstanceState, order: Array[StringName]) -> Array[StringName]:
	var lo := _min_level(state)
	var out: Array[StringName] = []
	for p: StringName in order:
		if state.part_levels[p] == lo:
			out.append(p)
	return out


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
