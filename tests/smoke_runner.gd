extends Node
## Body of tests/smoke_test.gd (MVP loop). A Node loaded at runtime so the
## EventBus / GameState autoload identifiers resolve; tree = get_tree().

signal finished(code: int)

const MAX_MINE_FRAMES := 60 * 30
const MAX_COLLECT_FRAMES := 60 * 10
const MAX_TRIPS := 6

var _game: MvpGame
var _failed: bool = false
var _events: Dictionary[StringName, int] = {}


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var main_path: String = ProjectSettings.get_setting("application/run/main_scene")
	var packed := load(main_path) as PackedScene
	if packed == null:
		_fail("cannot load %s" % main_path)
		return
	_game = packed.instantiate() as MvpGame
	if _game == null:
		_fail("main scene root is not MvpGame")
		return
	for sig: StringName in [&"mining_beam_started", &"mining_beam_updated", &"asteroid_damaged", &"asteroid_destroyed",
			&"ore_spawned", &"ore_collected", &"dock_entered", &"cargo_sold", &"part_upgraded"]:
		var argc := 0
		for info: Dictionary in EventBus.get_signal_list():
			if info["name"] == sig:
				var args: Array = info["args"]
				argc = args.size()
		var cb := _count.bind(sig)
		EventBus.connect(sig, cb.unbind(argc) if argc > 0 else cb)
	get_tree().root.add_child(_game)
	get_tree().current_scene = _game
	for i in 5:
		await get_tree().physics_frame
	if _game.assembler == null or _game.laser == null:
		_fail("ship has no assembler/laser")
		return
	_check(_game.get_node_or_null(^"VfxDirector") != null, "VfxDirector in scene")
	_check(_game.world_env.environment != null, "WorldEnvironment has an environment")
	_check(_game.camera.far >= _game.camera.global_position.y + 130.0, "camera far >= height + 130 m")
	print("SMOKE: scene up, %d asteroids, credits %d" % [_game.field.get_asteroids().size(), GameState.credits])

	var ship := _game.ship
	var laser := _game.laser
	ship.use_player_input = false
	laser.use_player_input = false

	# Trips: mine a full hold (real beam), collect, dock, sell, until the
	# cheapest L2 upgrade is affordable (mvp.md: about 3 trips).
	var cheapest := _cheapest_part()
	var cost := GameState.get_upgrade_cost(cheapest)
	var trips := 0
	while GameState.credits < cost and trips < MAX_TRIPS:
		trips += 1
		var broken := 0
		while GameState.get_cargo_used() < GameState.get_cargo_capacity() and GameState.credits + GameState.get_cargo_value() < cost and broken < 12:
			var target := _nearest_asteroid(ship.global_position)
			if target == null:
				_fail("no asteroid to mine")
				return
			if not await _mine(target):
				return
			broken += 1
			if trips == 1 and broken == 1:
				for i in 4:
					await get_tree().process_frame
				var director := _game.get_node(^"VfxDirector") as VfxDirector
				var pickups := _game.pickups.get_pickups()
				_check(not pickups.is_empty() and director._is_decorated(pickups[0]), "VFX decorated the ore pickups (group ore_pickups)")
			if not await _collect():
				return
		laser.wants_fire = false
		_check(GameState.get_cargo_used() > 0, "trip %d: %d asteroids, cargo %d/%d worth %d" % [trips, broken, GameState.get_cargo_used(), GameState.get_cargo_capacity(), GameState.get_cargo_value()])
		ship.global_position = _game.station.get_dock_pad_position()
		ship.velocity = Vector3.ZERO
		for i in 6:
			await get_tree().physics_frame
		_check(GameState.docked, "trip %d: docked at the station" % trips)
		# E opens the station panel (locks ship input), Sell button, E closes.
		await _press_interact()
		_check(_game.hud.panel_open and ship.input_locked, "trip %d: E opened the station panel" % trips)
		var before_credits := GameState.credits
		_game.hud._sell_button.pressed.emit()
		var earned := GameState.credits - before_credits
		_check(earned > 0 and GameState.get_cargo_used() == 0, "trip %d: Sell button sold for %d, credits %d" % [trips, earned, GameState.credits])
		await _press_interact()
		_check(not _game.hud.panel_open and not ship.input_locked, "trip %d: E closed the panel" % trips)
		if _failed:
			finished.emit(1)
			return

	# Upgrade the cheapest part L1 -> L2 and check the model swap.
	var before := _part_model(cheapest)
	await _press_interact()
	_game.hud._rows[cheapest].pressed.emit()
	var ok := GameState.get_part_level(cheapest) == 2
	await _press_interact()
	await get_tree().process_frame
	_check(ok and GameState.get_part_level(cheapest) == 2, "%s upgraded to L2 (credits left %d)" % [cheapest, GameState.credits])
	var after := _part_model(cheapest)
	_check(after != null and after != before, "%s model swapped on upgrade" % cheapest)

	for sig: StringName in _events:
		print("SMOKE: %s x%d" % [sig, _events[sig]])
	for sig: StringName in [&"mining_beam_started", &"asteroid_damaged", &"asteroid_destroyed", &"ore_spawned", &"ore_collected", &"dock_entered", &"cargo_sold", &"part_upgraded"]:
		var fired: int = _events.get(sig, 0)
		_check(fired > 0, "EventBus.%s fired" % sig)
	if _failed:
		finished.emit(1)
		return
	print("SMOKE OK: %s (full loop)" % main_path)
	_game.queue_free()
	await get_tree().process_frame
	finished.emit(0)


func _mine(target: Asteroid) -> bool:
	var ship := _game.ship
	var laser := _game.laser
	var dir := target.global_position - ship.global_position
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD
	ship.global_position = target.global_position - dir * (target.radius + 3.0)
	ship.velocity = Vector3.ZERO
	ship.look_at(ship.global_position + dir, Vector3.UP)
	laser.wants_fire = true
	for i in MAX_MINE_FRAMES:
		ship.velocity = Vector3.ZERO
		ship.has_aim = true
		ship.aim_point = target.global_position if is_instance_valid(target) else ship.aim_point
		await get_tree().physics_frame
		if not is_instance_valid(target) or target.is_broken:
			laser.wants_fire = false
			return true
	_fail("asteroid %s did not break (hp %.1f)" % [target.name, target.hp])
	return false


func _collect() -> bool:
	var ship := _game.ship
	for i in MAX_COLLECT_FRAMES:
		var pickups := _game.pickups.get_pickups()
		if pickups.is_empty() or GameState.get_cargo_used() >= GameState.get_cargo_capacity():
			return true
		# Park the ship on the nearest pickup; the magnet does the rest.
		ship.global_position = pickups[0].global_position
		ship.velocity = Vector3.ZERO
		await get_tree().physics_frame
	_fail("pickups were not collected (%d left)" % _game.pickups.get_pickups().size())
	return false


func _press_interact() -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventAction.new()
		ev.action = &"interact"
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await get_tree().process_frame
	await get_tree().process_frame


func _cheapest_part() -> StringName:
	var best: StringName = &"head"
	for part: StringName in [&"head", &"body", &"wings", &"engine"]:
		if GameState.get_upgrade_cost(part) < GameState.get_upgrade_cost(best):
			best = part
	return best


func _part_model(part: StringName) -> Node:
	return _game.assembler.parts.get(part, null)


func _nearest_asteroid(from: Vector3) -> Asteroid:
	var best: Asteroid = null
	var best_d := INF
	for a: Asteroid in _game.field.get_asteroids():
		if a.is_broken:
			continue
		var d := a.global_position.distance_squared_to(from)
		if d < best_d:
			best_d = d
			best = a
	return best


func _count(sig: StringName) -> void:
	var n: int = _events.get(sig, 0)
	_events[sig] = n + 1


func _check(cond: bool, what: String) -> void:
	if cond:
		print("SMOKE: ok   %s" % what)
	else:
		_failed = true
		push_error("SMOKE FAIL: %s" % what)


func _fail(what: String) -> void:
	push_error("SMOKE FAIL: %s" % what)
	finished.emit(1)
