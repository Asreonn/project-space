class_name ShipController
extends CharacterBody3D
## Player flight controller. Spec: docs/briefs/mvp_balance.md §2 + ps-design
## m1_flight_tuning.md §1. CharacterBody3D locked to the XZ plane (Y = 0).
## - Nose turns to the mouse, turn rate capped by maneuver_speed (Wings);
##   scheme B (tuning.control_scheme = 1): W/S thrust + A/D turn.
## - Thrust along the nose; lateral grip, coast damping, Space brake,
##   Space + W drift, Shift boost. Every damping is exp(-k*dt) (frame-rate independent).
## Stats come from ShipAssembler.stats_changed / ShipStatsResolver through
## set_resolved_stats(); FlightTuning.default_* are only a fallback. No mesh binding.
## MVP: fuel off (boost = duration + cooldown only), no collision damage.

signal fuel_changed(fuel: float, capacity: float)
signal hull_changed(hull: float, max_hull: float)
signal mode_changed(mode: int)
signal boost_started
signal boost_ended
signal collided(impact_speed: float, damage: float)
signal destroyed
signal respawned

enum Mode { NORMAL, BRAKE, DRIFT }

const STAT_FLYING_SPEED := &"flying_speed"
const STAT_MANEUVER_SPEED := &"maneuver_speed"
const STAT_MASS := &"mass"
const STAT_FUEL_CAPACITY := &"fuel_capacity"
const STAT_FUEL_RATE := &"fuel_rate"
const STAT_HULL := &"hull"
const MIN_AIM_DIST_SQ := 0.04

@export var tuning: FlightTuning
## false: the in_* fields are written from outside (autopilot / tests).
@export var use_player_input: bool = true
## MVP has no fuel (brief §2): false = no burn, no limp mode, boost is free.
@export var fuel_enabled: bool = false
## Optional: when set, the ship builds its own ShipAssembler (player_ship.tscn
## standalone). Leave empty when a coordinator (MvpGame) calls assembler.build().
@export var hull_definition: ShipHullDefinition
@export var assembler_path: NodePath = ^"Visual/ShipAssembler"
## Optional VFX node with set_thrust(amount: float, boosting: bool)
## (vfx/mvp-effects scenes/vfx/engine_trail.tscn, instanced as Visual/EngineTrail).
## Missing node = no call; any node named EngineTrail under the ship also works.
@export var engine_trail_path: NodePath = ^"Visual/EngineTrail"

## Virtual input (player or autopilot).
var in_thrust: float = 0.0  ## -1..1 (S..W)
var in_strafe: float = 0.0  ## -1..1 (A..D); şema B'de dönüş
var in_brake: bool = false
var in_boost: bool = false
var aim_point: Vector3 = Vector3.ZERO  ## dünya, Y=0
var has_aim: bool = false

var mode: Mode = Mode.NORMAL
var boosting: bool = false
var fuel: float = 0.0
var hull: float = 0.0
var cargo_mass: float = 0.0  ## t; set by the cargo owner (GameState / MvpGame)
## true while the dock panel is open: input is ignored and the ship brakes to a stop.
var input_locked: bool = false
var assembler: ShipAssembler
var ship_state: ShipInstanceState

var _stats: Dictionary[StringName, float] = {}
var _yaw_vel: float = 0.0
var _boost_t: float = 0.0
var _boost_cd: float = 0.0
var _spawn: Transform3D
var _engine_trail: Node


func _ready() -> void:
	add_to_group(&"player")
	if tuning == null:
		tuning = FlightTuning.new()
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	_spawn = global_transform
	assembler = get_node_or_null(assembler_path) as ShipAssembler
	_engine_trail = _find_engine_trail()
	EventBus.station_panel_toggled.connect(_on_station_panel_toggled)
	EventBus.ship_stats_changed.connect(set_resolved_stats)
	if assembler != null and hull_definition != null:
		ship_state = ShipInstanceState.create_for(hull_definition)
		assembler.stats_changed.connect(set_resolved_stats)
		assembler.build(hull_definition, ship_state)
	fuel = get_stat(STAT_FUEL_CAPACITY)
	hull = get_stat(STAT_HULL)


func _on_station_panel_toggled(is_open: bool) -> void:
	input_locked = is_open


# --- Stat adapter -----------------------------------------------------------

## Output of ShipStatsResolver.resolve(hull, state). Empty = FlightTuning defaults.
func set_resolved_stats(stats: Dictionary) -> void:
	_stats.assign(stats)


func get_stat(key: StringName) -> float:
	if _stats.has(key):
		return _stats[key]
	match key:
		STAT_FLYING_SPEED: return tuning.default_flying_speed
		STAT_MANEUVER_SPEED: return tuning.default_maneuver_speed
		STAT_MASS: return tuning.default_mass
		STAT_FUEL_CAPACITY: return tuning.default_fuel_capacity
		STAT_FUEL_RATE: return tuning.default_fuel_rate
		STAT_HULL: return tuning.default_hull
	return 0.0


func get_total_mass() -> float:
	return get_stat(STAT_MASS) + tuning.loadout_mass + cargo_mass


func get_mass_ratio() -> float:
	return tuning.reference_mass / maxf(get_total_mass(), 0.01)


func get_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func get_speed_cap() -> float:
	var cap := get_stat(STAT_FLYING_SPEED)
	if boosting:
		cap *= tuning.boost_speed_mult
	if fuel_enabled and fuel <= 0.0:
		cap *= tuning.limp_speed_mult
	return cap


func get_forward() -> Vector3:
	var f := -global_basis.z
	f.y = 0.0
	return f.normalized()


# --- Simulation -------------------------------------------------------------

func _physics_process(dt: float) -> void:
	if input_locked:
		in_thrust = 0.0
		in_strafe = 0.0
		in_boost = false
		in_brake = true
	elif use_player_input:
		_read_player_input()
	_step(dt)
	if _engine_trail != null and _engine_trail.has_method(&"set_thrust"):
		_engine_trail.call(&"set_thrust", get_thrust_amount(), boosting)


## Engine trail drive value: flat speed / cruise speed (flying_speed), 0..1.
func get_thrust_amount() -> float:
	var flat := Vector2(velocity.x, velocity.z).length()
	return clampf(flat / maxf(get_stat(STAT_FLYING_SPEED), 0.1), 0.0, 1.0)


func _find_engine_trail() -> Node:
	var n: Node = null
	if engine_trail_path != NodePath():
		n = get_node_or_null(engine_trail_path)
	if n == null:
		n = find_child("EngineTrail", true, false)
	return n


func _read_player_input() -> void:
	in_thrust = Input.get_axis(&"move_back", &"move_forward")
	in_strafe = Input.get_axis(&"move_left", &"move_right")
	in_brake = Input.is_action_pressed(&"brake")
	in_boost = Input.is_action_pressed(&"boost")
	has_aim = false
	var cam := get_viewport().get_camera_3d()
	if cam:
		var mp := get_viewport().get_mouse_position()
		var origin := cam.project_ray_origin(mp)
		var dir := cam.project_ray_normal(mp)
		if absf(dir.y) > 0.0001:
			var t := -origin.y / dir.y
			if t > 0.0:
				aim_point = origin + dir * t
				aim_point.y = 0.0
				has_aim = true


func _step(dt: float) -> void:
	var m_ratio := get_mass_ratio()
	var accel_mult := pow(m_ratio, tuning.mass_exp_accel)
	var turn_mult := pow(m_ratio, tuning.mass_exp_turn)
	var brake_mult := pow(m_ratio, tuning.mass_exp_brake)
	var flying_speed := get_stat(STAT_FLYING_SPEED)
	var maneuver_speed := get_stat(STAT_MANEUVER_SPEED)
	var scheme_b := tuning.control_scheme == 1

	# Mod: Space = fren; Space + W = drift.
	var new_mode := Mode.NORMAL
	if in_brake:
		new_mode = Mode.DRIFT if in_thrust > 0.0 else Mode.BRAKE
	if new_mode != mode:
		mode = new_mode
		mode_changed.emit(mode)

	_update_boost(dt)

	# 1) Dönüş (§1.3)
	var max_w := deg_to_rad(maneuver_speed) * turn_mult * (tuning.drift_turn_mult if mode == Mode.DRIFT else 1.0)
	var w_target := 0.0
	if scheme_b:
		w_target = -in_strafe * max_w
	elif has_aim:
		var aim := aim_point - global_position
		aim.y = 0.0
		if aim.length_squared() > MIN_AIM_DIST_SQ:
			var target_yaw := atan2(-aim.x, -aim.z)
			var diff := wrapf(target_yaw - rotation.y, -PI, PI)
			w_target = clampf(diff * tuning.turn_gain, -max_w, max_w)
	_yaw_vel = lerpf(_yaw_vel, w_target, 1.0 - exp(-tuning.turn_response * dt))
	rotation.y = wrapf(rotation.y + _yaw_vel * dt, -PI, PI)
	rotation.x = 0.0
	rotation.z = 0.0

	var fwd := get_forward()
	var right := global_basis.x
	right.y = 0.0
	right = right.normalized()

	var cap := get_speed_cap()
	var a := flying_speed / maxf(tuning.accel_time_to_max, 0.01) * accel_mult
	var v := velocity
	v.y = 0.0
	var prev_speed := v.length()

	# 2) İleri/geri itki (burun yönünde)
	if mode != Mode.BRAKE and in_thrust != 0.0:
		var t_scale := 1.0 if in_thrust > 0.0 else tuning.reverse_thrust_ratio
		if mode == Mode.DRIFT:
			t_scale *= tuning.drift_thrust_mult
		if boosting:
			t_scale *= tuning.boost_accel_mult
		v += fwd * in_thrust * t_scale * a * dt

	# 3) Yanal tutuş + strafe (Wings: man_k)
	var man_k := maneuver_speed / maxf(tuning.maneuver_reference, 1.0)
	var v_fwd := fwd * v.dot(fwd)
	var v_lat := v - v_fwd
	var grip := tuning.lateral_grip * man_k * (tuning.drift_grip_mult if mode == Mode.DRIFT else 1.0)
	var lat_target := Vector3.ZERO
	if mode == Mode.NORMAL and not scheme_b:
		lat_target = right * in_strafe * tuning.strafe_speed_ratio * flying_speed * man_k
	v_lat = lat_target + (v_lat - lat_target) * exp(-grip * dt)

	# 4) Boyuna sönüm
	var damp := 0.0
	if mode == Mode.DRIFT:
		damp = tuning.drift_damp
	elif in_thrust == 0.0:
		damp = tuning.coast_damp
	v_fwd *= exp(-damp * dt)
	v = v_fwd + v_lat
	if mode == Mode.BRAKE:
		v *= exp(-tuning.brake_damp * brake_mult * dt)

	# 5) Hız tavanı: itki tavanı aşamaz; fazlalık üstel söner
	var sp := v.length()
	if sp > cap:
		sp = minf(sp, maxf(cap, prev_speed))
		sp = cap + (sp - cap) * exp(-tuning.overspeed_decay * dt)
		v = v.normalized() * sp

	velocity = v
	var pre_v := v
	move_and_slide()
	_handle_collisions(pre_v)
	velocity.y = 0.0
	if absf(global_position.y) > 0.0001:
		global_position.y = 0.0

	_burn_fuel(dt)


func _update_boost(dt: float) -> void:
	_boost_cd = maxf(0.0, _boost_cd - dt)
	var want := in_boost and in_thrust > 0.0 and mode != Mode.BRAKE
	if boosting:
		_boost_t += dt
		if not want or _boost_t >= tuning.boost_max_duration or (fuel_enabled and fuel <= 0.0):
			boosting = false
			_boost_cd = tuning.boost_cooldown
			boost_ended.emit()
	elif want and _boost_cd <= 0.0 and (not fuel_enabled or fuel >= tuning.boost_min_fuel):
		boosting = true
		_boost_t = 0.0
		if fuel_enabled:
			_set_fuel(fuel - tuning.boost_start_fuel)
		boost_started.emit()


func get_boost_cooldown() -> float:
	return _boost_cd


func _burn_fuel(dt: float) -> void:
	if not fuel_enabled or fuel <= 0.0:
		return
	var throttle := clampf(absf(in_thrust) + 0.5 * absf(in_strafe), 0.0, 1.0)
	if mode == Mode.BRAKE:
		throttle = 0.0
	var burn := get_stat(STAT_FUEL_RATE) * (tuning.fuel_idle_ratio + (1.0 - tuning.fuel_idle_ratio) * throttle)
	if boosting:
		burn += tuning.boost_fuel_per_s
	_set_fuel(fuel - burn * dt)


func _set_fuel(value: float) -> void:
	fuel = clampf(value, 0.0, get_stat(STAT_FUEL_CAPACITY))
	fuel_changed.emit(fuel, get_stat(STAT_FUEL_CAPACITY))


func _handle_collisions(pre_v: Vector3) -> void:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var n := c.get_normal()
		n.y = 0.0
		if n.length_squared() < 0.0001:
			continue
		n = n.normalized()
		var vn := pre_v.dot(n)
		if vn >= 0.0:
			continue
		var impact := -vn
		velocity += n * impact * tuning.collision_restitution
		var dmg := maxf(0.0, impact - tuning.collision_damage_threshold) * tuning.collision_damage_per_mps
		collided.emit(impact, dmg)
		if dmg > 0.0:
			apply_damage(dmg)
		break


func apply_damage(amount: float) -> void:
	hull = maxf(0.0, hull - amount)
	hull_changed.emit(hull, get_stat(STAT_HULL))
	if hull <= 0.0:
		destroyed.emit()
		respawn.call_deferred()


## Free respawn (M1); hull and fuel refill. Not used in the MVP (no damage).
func respawn(at: Transform3D = _spawn) -> void:
	global_transform = at
	velocity = Vector3.ZERO
	_yaw_vel = 0.0
	boosting = false
	_boost_cd = 0.0
	_boost_t = 0.0
	mode = Mode.NORMAL
	hull = get_stat(STAT_HULL)
	_set_fuel(get_stat(STAT_FUEL_CAPACITY))
	hull_changed.emit(hull, get_stat(STAT_HULL))
	respawned.emit()


func set_spawn(t: Transform3D) -> void:
	_spawn = t
