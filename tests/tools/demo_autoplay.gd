extends Node
## Scripted MVP demo (tests/tools/demo_autoplay.tscn) for video capture:
##   1 flight + boost, 2 mine and break an asteroid (nose on target, beam from
##   the nose), 3 magnet collect, 4 fly to the station, dock, E, sell,
##   5 Head L2 with a close camera on the model swap, 6 F9 debug credits and Head L3.
## Drives the real ship (virtual input: thrust/boost/brake/aim) and the real
## station panel; nothing is teleported. Saves one PNG per step.
## Record (one window, Forward+ on llvmpipe works under Xvfb):
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --audio-driver Dummy \
##     --resolution 1280x720 --fixed-fps 30 --write-movie /tmp/demo.avi \
##     res://tests/tools/demo_autoplay.tscn -- --shots=/workspace/out/mvp_demo
## Requires a debug build for F9 (DebugCheats).

const SECTOR_SCENE := "res://scenes/main/mvp_sector.tscn"
const MAX_SECONDS := 95.0
const DEMO_PART := &"head"

var game: MvpGame
var ship: ShipController
var laser: MiningLaser
var shots_dir: String = "user://mvp_demo"
var _t: float = 0.0


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots_dir = arg.trim_prefix("--shots=")
	DirAccess.make_dir_recursive_absolute(shots_dir)
	game = (load(SECTOR_SCENE) as PackedScene).instantiate() as MvpGame
	add_child(game)
	_run.call_deferred()


func _process(dt: float) -> void:
	_t += dt
	if _t > MAX_SECONDS:
		push_warning("demo: time cap reached, quitting")
		get_tree().quit()


func _run() -> void:
	await _wait(0.3)
	ship = game.ship
	laser = game.laser
	ship.use_player_input = false
	laser.use_player_input = false
	_log("start")

	# 1) Flight and boost: a loop out from the spawn, boost on the long leg.
	var spawn := ship.global_position
	await _fly_to(spawn + Vector3(-16.0, 0.0, 8.0), 3.0, false, 5.0)
	await _fly_to(spawn + Vector3(-6.0, 0.0, 26.0), 3.0, false, 4.0)
	await _fly_to(spawn + Vector3(30.0, 0.0, 34.0), 4.0, true, 5.0, 1.6)
	_shot("01_flight")
	await _fly_to(spawn + Vector3(40.0, 0.0, 36.0), 4.0, true, 4.0)

	# 2) + 3) Mine two asteroids, collect their ore with the magnet.
	for i in 3:
		var rock := _pick_asteroid()
		if rock == null:
			break
		var stand := laser.definition.beam_range * 0.55 + rock.radius
		await _fly_to(rock.global_position, stand, false, 12.0)
		await _mine(rock, "02_mine_break" if i == 0 else "")
		await _collect(8.0, "03_collect" if i == 0 else "")

	# 4) Station: around the hub to the entrance, onto the pad, E, Sell.
	var st := game.station
	var entrance := st.get_entrance_position()
	await _fly_to(entrance + (entrance - st.global_position).normalized() * 10.0, 4.0, true, 14.0)
	await _fly_to(entrance, 2.0, false, 6.0)
	await _fly_to(st.get_dock_pad_position(), 0.8, false, 6.0)
	await _hold_still(0.6)
	_log("docked=%s" % GameState.docked)
	await _press(&"interact")
	await _wait(1.0)
	game.hud._sell_button.pressed.emit()
	await _wait(1.2)
	_shot("04_dock_sell")
	await _wait(2.0)

	# 5) Head L2, close camera on the swap. The first trip pays ~40 cr and L2
	#    costs 320, so F9 (debug credits) tops up first when needed.
	game.camera.set_size_override(7.0)
	await _wait(1.4)
	while GameState.credits < GameState.get_upgrade_cost(DEMO_PART):
		await _press(&"debug_add_credits")
		await _wait(0.6)
	game.hud._rows[DEMO_PART].pressed.emit()
	_log("head L%d" % GameState.get_part_level(DEMO_PART))
	await _wait(1.6)
	_shot("05_l2_swap")
	await _wait(2.0)

	# 6) F9 credits, then Head L3.
	while GameState.credits < GameState.get_upgrade_cost(DEMO_PART):
		await _press(&"debug_add_credits")
		await _wait(0.7)
	game.hud._rows[DEMO_PART].pressed.emit()
	_log("head L%d" % GameState.get_part_level(DEMO_PART))
	await _wait(1.6)
	_shot("06_l3_swap")
	await _wait(2.5)

	# Outro: close the panel, zoom out, fly off.
	await _press(&"interact")
	game.camera.set_size_override(-1.0)
	await _fly_to(entrance + Vector3(0.0, 0.0, -30.0), 3.0, true, 6.0)
	await _wait(1.0)
	_log("done, credits %d" % GameState.credits)
	get_tree().quit()


# --- Autopilot ---------------------------------------------------------------

## Steers toward `to` (turn to aim, thrust when roughly facing it, brake near).
## Returns when within `arrive` m and slow, or after `timeout` s / `max_t` s.
func _fly_to(to: Vector3, arrive: float, boost: bool, timeout: float, max_t: float = -1.0) -> void:
	var t := 0.0
	while t < timeout and (max_t < 0.0 or t < max_t):
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
		t += get_physics_process_delta_time()
	_idle()


func _idle() -> void:
	ship.in_thrust = 0.0
	ship.in_boost = false
	ship.in_brake = false


func _hold_still(seconds: float) -> void:
	ship.in_brake = true
	await _wait(seconds)
	ship.in_brake = false


func _mine(rock: Asteroid, shot: String) -> void:
	laser.wants_fire = true
	ship.in_brake = true
	var t := 0.0
	var shot_done := shot == ""
	while is_instance_valid(rock) and not rock.is_broken and t < 25.0:
		ship.has_aim = true
		ship.aim_point = rock.global_position
		# Creep in if the asteroid is out of reach.
		var dist := ship.global_position.distance_to(rock.global_position) - rock.radius
		ship.in_brake = dist < laser.definition.beam_range * 0.7
		ship.in_thrust = 0.0 if ship.in_brake else 0.5
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if not shot_done and laser.hit_asteroid == rock and t > 1.5:
			_shot(shot)
			shot_done = true
	laser.wants_fire = false
	_idle()
	_log("asteroid broken=%s after %.1fs" % [not is_instance_valid(rock) or rock.is_broken, t])
	await _wait(0.4)


func _collect(timeout: float, shot: String) -> void:
	var t := 0.0
	var start_cargo := GameState.get_cargo_used()
	var shot_done := shot == ""
	while t < timeout:
		var near: OrePickup = null
		var best := 30.0
		for p: OrePickup in game.pickups.get_pickups():
			var d := p.global_position.distance_to(ship.global_position)
			if d < best:
				best = d
				near = p
		if near == null or GameState.get_cargo_used() >= GameState.get_cargo_capacity():
			break
		ship.has_aim = true
		ship.aim_point = near.global_position
		var facing := ship.get_forward().dot((near.global_position - ship.global_position).normalized())
		ship.in_brake = ship.get_speed() > 4.0
		ship.in_thrust = 0.6 if facing > 0.7 and not ship.in_brake else 0.0
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if not shot_done and GameState.get_cargo_used() > start_cargo:
			_shot(shot)
			shot_done = true
	_idle()
	_log("cargo %d/%d" % [GameState.get_cargo_used(), GameState.get_cargo_capacity()])


func _pick_asteroid() -> Asteroid:
	var best: Asteroid = null
	var best_d := INF
	for a: Asteroid in game.field.get_asteroids():
		if a.is_broken or a.size == &"L" or a.global_position.distance_to(game.station.global_position) > 70.0:
			continue
		var d := a.global_position.distance_to(ship.global_position)
		if d < best_d:
			best_d = d
			best = a
	return best


# --- Helpers -----------------------------------------------------------------

func _press(action: StringName) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await get_tree().process_frame


func _wait(seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		await get_tree().process_frame
		t += get_process_delta_time()


func _shot(file_name: String) -> void:
	var img: Image = null
	if DisplayServer.get_name() != "headless":
		img = get_viewport().get_texture().get_image()
	if img == null:
		_log("shot %s skipped (no renderer)" % file_name)
		return
	var path := shots_dir.path_join(file_name + ".png")
	var err := img.save_png(path)
	_log("shot %s err=%d" % [path, err])


func _log(msg: String) -> void:
	print("[demo %5.1fs] %s" % [_t, msg])
