extends SceneTree
## Measures the real MVP loop with the autopilot in tests/tools/real_loop_bot.gd.
##   godot --headless --fixed-fps 60 --path . -s res://tests/tools/run_real_loop_measure.gd -- --seed=0 --runs=40 --max-time=2400
## --fixed-fps 60 makes one frame = 1/60 s of game time, so it runs faster than real time.
## Prints one markdown row per run, the upgrade timeline and a summary line. Exit 0.

var _bot: Node


func _initialize() -> void:
	var seed_value := 0
	var runs := 6
	var max_time := 900.0
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			seed_value = arg.trim_prefix("--seed=").to_int()
		elif arg.begins_with("--runs="):
			runs = arg.trim_prefix("--runs=").to_int()
		elif arg.begins_with("--max-time="):
			max_time = arg.trim_prefix("--max-time=").to_float()
	var script := load("res://tests/tools/real_loop_bot.gd") as GDScript
	_bot = script.new()
	_bot.set(&"seed_value", seed_value)
	_bot.set(&"max_runs", runs)
	_bot.set(&"max_time", max_time)
	_bot.connect(&"finished", _on_finished)
	root.add_child.call_deferred(_bot)


func _on_finished(_code: int) -> void:
	var rows: Array = _bot.get(&"rows")
	var seed_value: int = _bot.get(&"seed_value")
	print("\n### Real loop (seed %d)\n" % seed_value)
	print("| run | start | dur | fly | mine | collect | dock | levels | cap | dps | ast S/M/L | spawned u | collected u | sold u (ore/crystal) | left in field u | earned | credits |")
	print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
	for r: Dictionary in rows:
		var bs: Dictionary = r["by_size"]
		var cargo: Dictionary = r["cargo"]
		var sp: Dictionary = r["spawned"]
		var co: Dictionary = r["collected"]
		var start: float = r["start"]
		var dur: float = r["duration"]
		var fly: float = r["fly"]
		var mine: float = r["mine"]
		var col: float = r["collect"]
		var dock: float = r["dock"]
		print("| %d | %s | %ds | %ds | %ds | %ds | %ds | %s | %d | %.1f | %d/%d/%d | %d | %d | %d (%d/%d) | %d | %d | %d |" % [
			r["run"], _mmss(start), roundi(dur), roundi(fly), roundi(mine), roundi(col), roundi(dock),
			r["levels"], r["cap"], r["dps"], bs.get(&"S", 0), bs.get(&"M", 0), bs.get(&"L", 0), _sum(sp), _sum(co),
			r["used"], cargo.get(&"ore_common_solid", 0), cargo.get(&"crystal_blue_solid", 0),
			r["left_in_field"], r["earned"], r["credits"]])
	print("\n| buy | part | level | cost | time |\n|---|---|---|---|---|")
	var i := 1
	var first_t := -1.0
	var first_l3 := -1.0
	var last_t := -1.0
	var buys: Array = _bot.get(&"buys")
	for b: Dictionary in buys:
		var bt: float = b["t"]
		var lvl: int = b["level"]
		print("| %d | %s | L%d | %d | %s |" % [i, b["part"], lvl, b["cost"], _mmss(bt)])
		if first_t < 0.0:
			first_t = bt
		if first_l3 < 0.0 and lvl >= 3:
			first_l3 = bt
		last_t = bt
		i += 1
	var full := last_t if buys.size() >= 8 else -1.0
	var skips: int = _bot.get(&"stuck_skips")
	var sim_t: float = _bot.get(&"t")
	print("SUMMARY seed=%d first_upgrade=%.0f first_l3=%.0f full_l3=%.0f stuck_skips=%d sim_time=%.0f" % [
		seed_value, first_t, first_l3, full, skips, sim_t])
	quit(0)


static func _sum(d: Dictionary) -> int:
	var s := 0
	for k: Variant in d:
		var v: int = d[k]
		s += v
	return s


static func _mmss(s: float) -> String:
	if s < 0.0:
		return "-"
	var n := roundi(s)
	return "%d:%02d" % [floori(n / 60.0), n % 60]
