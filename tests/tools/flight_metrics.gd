extends RefCounted
## Headless flight + camera metrics for the starter shuttle (1.84 m) at several
## cruise speeds. Drives ShipController through its virtual input.
## Entry point: tests/tools/run_flight_metrics.gd (loads this after autoloads exist).
## Prints markdown tables (docs/briefs/mvp_balance.md §2).

const PLAYER_SHIP := "res://scenes/ship/player_ship.tscn"
const HULL := "res://data/ships/starter_shuttle_01.tres"
const SHIP_LENGTH_M := 1.84 ## D-009
const ASPECT := 16.0 / 9.0
const SPEEDS: Array[float] = [10.0, 12.0, 14.0, 16.0]
const DT := 1.0 / 60.0

var ship: ShipController


func run(tree: SceneTree) -> void:
	var packed: PackedScene = load(PLAYER_SHIP)
	ship = packed.instantiate() as ShipController
	ship.hull_definition = load(HULL)
	ship.use_player_input = false
	tree.root.add_child(ship)
	await tree.physics_frame
	var base: Dictionary = ship.assembler.stats.duplicate()
	var ft := ship.tuning

	print("### Flight metrics (empty cargo, L1 parts, scheme A)\n")
	print("| cruise m/s | SL/s | 0->95% | coast stop | Space brake stop | S reverse stop | 180 deg turn | boost peak | drift: lateral kept after 1 s |")
	print("|---|---|---|---|---|---|---|---|---|")
	for v: float in SPEEDS:
		var st: Dictionary = base.duplicate()
		st[ShipStat.FLYING_SPEED] = v
		ship.set_resolved_stats(st)
		var t95 := _time_to_speed(v * 0.95)
		var coast := _stop_distance(false, 0.0)
		var brake := _stop_distance(true, 0.0)
		var rev := _stop_distance(false, -1.0)
		var turn := _turn_time(180.0)
		var peak := _boost_peak()
		var drift := _drift_keep()
		print("| %d | %.1f | %.2f s | %.1f m (%.1f SL) | %.1f m (%.1f SL) | %.1f m | %.2f s | %.1f m/s | %d%% |" % [
			roundi(v), v / SHIP_LENGTH_M, t95, coast, coast / SHIP_LENGTH_M, brake, brake / SHIP_LENGTH_M, rev, turn, peak, roundi(drift * 100.0)])
	ship.set_resolved_stats(base)

	print("\n### Camera read (ortho, 16:9, ship %.2f m)\n" % SHIP_LENGTH_M)
	print("| view height | view width | ship %% of height | px on 1080p | laser range %.0f m / half-height | cross half-height @10 / 12 / 14 / 16 m/s |" % 10.0)
	print("|---|---|---|---|---|---|")
	for h: float in ft.ortho_sizes:
		var cross: PackedStringArray = []
		for v: float in SPEEDS:
			cross.append("%.2f" % (h * 0.5 / v))
		print("| %.0f m | %.1f m | %.1f%% | %d px | %.0f%% | %s s |" % [h, h * ASPECT, SHIP_LENGTH_M / h * 100.0, roundi(SHIP_LENGTH_M / h * 1080.0), 10.0 / (h * 0.5) * 100.0, " / ".join(cross)])
	print("\nlook_ahead_max %.1f m, aim_offset_max %.1f m, default zoom %.0f m" % [ft.look_ahead_max, ft.aim_offset_max, ft.ortho_sizes[ft.default_zoom_index]])
	ship.queue_free()


func _reset() -> void:
	ship.global_transform = Transform3D.IDENTITY
	ship.velocity = Vector3.ZERO
	ship.in_thrust = 0.0
	ship.in_strafe = 0.0
	ship.in_brake = false
	ship.in_boost = false
	ship.has_aim = false
	ship.boosting = false
	ship.rotation = Vector3.ZERO


func _step(n: int = 1) -> void:
	for i in n:
		ship.call(&"_step", DT)


func _cruise() -> void:
	_reset()
	ship.in_thrust = 1.0
	_step(180)


func _time_to_speed(target: float) -> float:
	_reset()
	ship.in_thrust = 1.0
	var t := 0.0
	while ship.get_speed() < target and t < 10.0:
		_step()
		t += DT
	return t


func _stop_distance(brake: bool, thrust: float) -> float:
	_cruise()
	var p0 := ship.global_position
	ship.in_thrust = thrust
	ship.in_brake = brake
	var t := 0.0
	while t < 20.0:
		_step()
		t += DT
		if ship.get_speed() < 0.5 or ship.velocity.dot(ship.get_forward()) < 0.0:
			break
	return p0.distance_to(ship.global_position)


func _turn_time(deg: float) -> float:
	_reset()
	var aim := Vector3(0.0, 0.0, -20.0).rotated(Vector3.UP, deg_to_rad(deg - 0.5))
	ship.aim_point = aim
	ship.has_aim = true
	var t := 0.0
	while t < 5.0:
		_step()
		t += DT
		var f := ship.get_forward()
		if rad_to_deg(f.angle_to(aim.normalized())) < 5.0:
			break
	return t


func _boost_peak() -> float:
	_cruise()
	ship.in_boost = true
	var peak := 0.0
	for i in 90:
		_step()
		peak = maxf(peak, ship.get_speed())
	ship.in_boost = false
	return peak


func _drift_keep() -> float:
	_cruise()
	ship.in_brake = true # Space + W = drift
	ship.rotation.y = deg_to_rad(90.0) # nose turned 90 deg, velocity now lateral
	var lat0 := absf(ship.velocity.dot(ship.global_basis.x))
	_step(60)
	var lat1 := absf(ship.velocity.dot(ship.global_basis.x))
	return lat1 / maxf(lat0, 0.001)
