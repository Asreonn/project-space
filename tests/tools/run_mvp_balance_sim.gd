extends SceneTree
## Prints the MVP pacing tables and checks the pacing targets.
##   godot --headless --path . -s res://tests/tools/run_mvp_balance_sim.gd [-- --markdown]
## Exit 0 = targets met, 1 = out of band.

const SEEDS := 25
const FIRST_UPGRADE_BAND := Vector2(180.0, 300.0) ## s (3-5 min, target ~4)
const FIRST_L3_MAX := 600.0 ## s, median (Game Designer: first L3 <= 10 min)
const FIRST_L3_SOFT_MAX := 660.0 ## s, slowest seed (ideally <= 11 min; warning only)
const FULL_L3_BAND := Vector2(1200.0, 1500.0) ## s (Game Designer: ~20-25 min median)
const SPEEDS: Array[float] = [10.0, 12.0, 14.0, 16.0]


func _init() -> void:
	var sim := MvpBalanceSim.new()
	var ok := true
	var med := _median_result(sim)
	var fv := sim.field_value()
	print("## Total upgrade cost: %d credits | full field: %d u, %d cr, %d HP" % [med.total_cost, fv["units"], fv["credits"], MvpBalanceSim._i(fv["hp"])])
	print("\n### Runs (median seed)\n")
	print("| run | start | duration | fly | mine | dock | asteroids | units | credits | levels |")
	print("|---|---|---|---|---|---|---|---|---|---|")
	for r: MvpBalanceSim.RunRow in med.runs:
		print("| %d | %s | %ds | %ds | %ds | %ds | %d | %d | %d | %s |" % [r.index, _mmss(r.start_t), roundi(r.duration), roundi(r.fly_t), roundi(r.mine_t), roundi(r.dock_t), r.asteroids, r.units, r.credits, r.levels])
	print("\n### Upgrade timeline (median seed)\n")
	print("| buy | part | level | cost | time |")
	print("|---|---|---|---|---|")
	var i := 1
	for b: Dictionary in med.buys:
		print("| %d | %s | L%d | %d | %s |" % [i, b["part"], b["level"], b["cost"], _mmss(MvpBalanceSim._f(b["t"]))])
		i += 1

	print("\n### Cruise speed sweep (L1 flying_speed override, %d seeds, median)\n" % SEEDS)
	print("| L1 cruise m/s | L1 run | first upgrade | first L3 | all L2 | full L3 |")
	print("|---|---|---|---|---|---|")
	for s: float in SPEEDS:
		sim.speed_delta = s - 12.0
		var runs: Array[float] = []
		var f: Array[float] = []
		var f3: Array[float] = []
		var l2: Array[float] = []
		var l3: Array[float] = []
		for sd in SEEDS:
			var r := sim.simulate(1000 + sd)
			runs.append(r.runs[0].duration)
			f.append(r.first_upgrade_t)
			f3.append(r.first_l3_t)
			l2.append(r.all_l2_t)
			l3.append(r.full_l3_t)
		print("| %d | %ds | %s | %s | %s | %s |" % [roundi(s), roundi(_median(runs)), _mmss(_median(f)), _mmss(_median(f3)), _mmss(_median(l2)), _mmss(_median(l3))])
	sim.speed_delta = 0.0

	var firsts: Array[float] = []
	var first3s: Array[float] = []
	var fulls: Array[float] = []
	for sd in SEEDS:
		var r := sim.simulate(1000 + sd)
		firsts.append(r.first_upgrade_t)
		first3s.append(r.first_l3_t)
		fulls.append(r.full_l3_t)
	firsts.sort()
	first3s.sort()
	fulls.sort()
	print("\n### Pacing check (%d seeds, default data)\n" % SEEDS)
	print("| metric | min | median | max | target |")
	print("|---|---|---|---|---|")
	print("| first upgrade | %s | %s | %s | 3:00-5:00 (~4:00) |" % [_mmss(firsts[0]), _mmss(firsts[SEEDS >> 1]), _mmss(firsts[SEEDS - 1])])
	print("| first L3 (any part) | %s | %s | %s | median <= 10:00 (max <= 11:00) |" % [_mmss(first3s[0]), _mmss(first3s[SEEDS >> 1]), _mmss(first3s[SEEDS - 1])])
	print("| full starter L3 | %s | %s | %s | 20:00-25:00 |" % [_mmss(fulls[0]), _mmss(fulls[SEEDS >> 1]), _mmss(fulls[SEEDS - 1])])
	var f_med := firsts[SEEDS >> 1]
	var f3_med := first3s[SEEDS >> 1]
	var l_med := fulls[SEEDS >> 1]
	if f3_med < 0.0 or f3_med > FIRST_L3_MAX:
		printerr("PACING FAIL: first L3 median %s" % _mmss(f3_med))
		ok = false
	if first3s[SEEDS - 1] > FIRST_L3_SOFT_MAX:
		print("PACING WARN: slowest first L3 %s > %s" % [_mmss(first3s[SEEDS - 1]), _mmss(FIRST_L3_SOFT_MAX)])
	if f_med < FIRST_UPGRADE_BAND.x or f_med > FIRST_UPGRADE_BAND.y:
		printerr("PACING FAIL: first upgrade median %s" % _mmss(f_med))
		ok = false
	if l_med < FULL_L3_BAND.x or l_med > FULL_L3_BAND.y:
		printerr("PACING FAIL: full L3 median %s" % _mmss(l_med))
		ok = false
	print("\nPACING %s" % ("OK" if ok else "FAIL"))
	quit(0 if ok else 1)


func _median_result(sim: MvpBalanceSim) -> MvpBalanceSim.Result:
	var all: Array[MvpBalanceSim.Result] = []
	for sd in SEEDS:
		all.append(sim.simulate(1000 + sd))
	all.sort_custom(func(a: MvpBalanceSim.Result, b: MvpBalanceSim.Result) -> bool: return a.full_l3_t < b.full_l3_t)
	return all[SEEDS >> 1]


static func _median(a: Array[float]) -> float:
	var b := a.duplicate()
	b.sort()
	return b[b.size() >> 1]


static func _mmss(s: float) -> String:
	if s < 0.0:
		return "-"
	var n := roundi(s)
	return "%d:%02d" % [floori(n / 60.0), n % 60]
