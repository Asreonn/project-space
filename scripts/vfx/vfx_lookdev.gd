extends Node3D
## VFX look-dev scene: real starter ship (ShipAssembler) + asteroids + every
## MVP effect, driven through the EventBus exactly like the game will.
## Interactive: run the scene, keys 1-6 switch shots (engine, beam, break,
## ore, overview, background); Shift = boost in the engine shot.
## Capture (writes PNG frames + perf.txt, then quits):
##   godot --path . --fixed-fps 30 --resolution 1280x720 res://scenes/vfx/vfx_lookdev.tscn -- --capture=/abs/out/dir [--shots=engine,beam] [--bg-low] [--no-post]

const SHOTS: Array[StringName] = [&"engine", &"beam", &"break", &"ore", &"overview", &"background"]
const SHOT_LENGTH: Dictionary[StringName, float] = {
	&"engine": 4.0, &"beam": 3.0, &"break": 2.6, &"ore": 3.2, &"overview": 4.0, &"background": 3.0,
}
const HULL_PATH := "res://data/ships/starter_shuttle_01.tres"
const ASTEROIDS: Array[String] = [
	"res://assets/models/asteroids/asteroid_ore_m_01.glb",
	"res://assets/models/asteroids/asteroid_l_01.glb",
	"res://assets/models/asteroids/asteroid_m_02.glb",
	"res://assets/models/asteroids/asteroid_s_01.glb",
	"res://assets/models/asteroids/asteroid_ore_l_01.glb",
	"res://assets/models/asteroids/asteroid_s_02.glb",
]

var shot: StringName = &"overview"
var shot_time: float = 0.0
var capture_dir: String = ""
var capture_shots: Array[StringName] = []
var capture_every: int = 2

var _ship: Node3D
var _assembler: Node3D
var _trail: EngineTrail
var _asteroids: Array[Node3D] = []
var _pickups: Array[Node3D] = []
var _laser: VfxLookdevStubs.LaserStub
var _events_done: Dictionary = {}
var _frame: int = 0
var _perf: Array[String] = []
var _pf_frames: int = 0
var _pf_cpu: float = 0.0
var _pf_gpu: float = 0.0
var _pf_draw: int = 0
var _pf_prims: int = 0
var _pf_particles: int = 0

@onready var cam: Camera3D = $Camera
@onready var director: VfxDirector = $VfxDirector
@onready var bus: Node = get_node_or_null(^"/root/EventBus")


func _ready() -> void:
	_build_ship()
	_build_asteroids()
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--capture="):
			capture_dir = a.trim_prefix("--capture=")
		elif a == "--no-post":
			($PostFx as CanvasLayer).visible = false
			($WorldEnvironment as WorldEnvironment).environment = Environment.new()
		elif a == "--bg-low":
			($SpaceBackground as SpaceBackground).low_quality = true
		elif a.begins_with("--shots="):
			for s: String in a.trim_prefix("--shots=").split(","):
				capture_shots.append(StringName(s))
	if capture_dir != "":
		if capture_shots.is_empty():
			capture_shots = SHOTS.duplicate()
		DirAccess.make_dir_recursive_absolute(capture_dir)
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
		var first: StringName = capture_shots.pop_front()
		_start_shot(first)
	else:
		_start_shot(&"overview")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed:
		var k := (event as InputEventKey).physical_keycode
		if k >= KEY_1 and k <= KEY_6:
			_start_shot(SHOTS[k - KEY_1])


# --- Scene setup ---------------------------------------------------------------

func _build_ship() -> void:
	_ship = Node3D.new()
	_ship.name = "Ship"
	add_child(_ship)
	_ship.add_to_group(&"pickup_collector")
	var script_res := load("res://scripts/core/ship_assembler.gd") as Script
	var hull: Resource = load(HULL_PATH) if ResourceLoader.exists(HULL_PATH) else null
	if script_res != null and hull != null:
		_assembler = Node3D.new()
		_assembler.set_script(script_res)
		_assembler.name = "Visual"
		_ship.add_child(_assembler)
		_assembler.call(&"build", hull)
	else:
		_assembler = _placeholder_ship()
		_ship.add_child(_assembler)
	_trail = (load("res://scenes/vfx/engine_trail.tscn") as PackedScene).instantiate() as EngineTrail
	_ship.add_child(_trail)
	_laser = VfxLookdevStubs.LaserStub.new()
	_laser.name = "MiningLaser"
	_ship.add_child(_laser)


## Primitive ship with the contract empties, used only if the real data is missing.
func _placeholder_ship() -> Node3D:
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	var m := PrismMesh.new()
	m.size = Vector3(1.0, 1.8, 0.3)
	mi.mesh = m
	mi.rotation_degrees = Vector3(-90, 0, 0)
	root.add_child(mi)
	for p: Array in [["FX_EngineTrail_0", Vector3(-0.112, 0.028, 0.9)], ["FX_EngineTrail_1", Vector3(0.112, 0.028, 0.9)], ["FX_MiningOrigin", Vector3(0, 0.02, -0.945)]]:
		var e := Node3D.new()
		e.name = p[0]
		e.position = p[1]
		root.add_child(e)
	return root


func _build_asteroids() -> void:
	for path: String in ASTEROIDS:
		var n: Node3D
		if ResourceLoader.exists(path):
			n = (load(path) as PackedScene).instantiate() as Node3D
		else:
			var mi := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radial_segments = 7
			sm.rings = 4
			mi.mesh = sm
			n = mi
		add_child(n)
		_asteroids.append(n)


func _mining_origin() -> Node3D:
	return _ship.find_child("FX_MiningOrigin", true, false) as Node3D


func _place_asteroid(i: int, pos: Vector3, s: float = 1.0) -> void:
	var a := _asteroids[i]
	a.visible = true
	a.position = pos
	a.scale = Vector3.ONE * s
	a.rotation = Vector3(0.3 * i, 0.9 * i, 0.0)


## with_model: the pickup already loads the Modeler's model (game path);
## otherwise it carries the placeholder box (director swaps in the model).
func _make_pickup(pos: Vector3, item: StringName, with_model: bool = false) -> Node3D:
	var p := VfxLookdevStubs.PickupStub.new()
	p.item_id = item
	if with_model:
		p.model_path = OrePickupVisual.MODEL_CRYSTAL if String(item).contains("crystal") else OrePickupVisual.MODEL_ORE
	p.position = pos
	add_child(p)
	_pickups.append(p)
	if bus != null:
		bus.emit_signal(&"ore_spawned", p.global_position, item, 1)
	return p


## Radius (m) of an asteroid model from its mesh AABB.
func _asteroid_radius(i: int) -> float:
	var r := 1.0
	for mi: Node in _asteroids[i].find_children("*", "MeshInstance3D", true, false):
		var aabb := (mi as MeshInstance3D).get_aabb()
		r = maxf(r, maxf(aabb.size.x, aabb.size.z) * 0.5)
	return r * _asteroids[i].scale.x


## Mimics MiningLaser: beam from FX_MiningOrigin to the asteroid surface (or range end).
func _drive_beam(t: float, start_t: float, stop_t: float, ast: int, beam_range: float = 10.0) -> void:
	if bus == null:
		return
	var o := _mining_origin()
	if o == null:
		return
	var origin := o.global_position
	var c := _asteroids[ast].global_position
	var to := c - origin
	to.y = 0.0
	var dir := to.normalized()
	var surface := origin + dir * maxf(to.length() - _asteroid_radius(ast) * 0.8, 0.2)
	surface.y = 0.0
	var in_range := origin.distance_to(surface) <= beam_range
	_laser.beam_origin = origin
	_laser.beam_end = surface if in_range else origin + dir * beam_range
	if t >= start_t and t < stop_t:
		if not _events_done.has("beam_on"):
			_events_done["beam_on"] = true
			_laser.firing = true
			bus.emit_signal(&"mining_beam_started", o, null)
		if in_range and t >= start_t + 0.15 and not _events_done.has("beam_target"):
			_events_done["beam_target"] = true
			bus.emit_signal(&"mining_beam_started", o, _asteroids[ast])
		if in_range and t >= start_t + 0.4:
			var ratio := clampf(1.0 - (t - start_t) / maxf(stop_t - start_t, 0.1), 0.05, 1.0)
			bus.emit_signal(&"asteroid_damaged", _asteroids[ast], _laser.beam_end, ratio)
	elif t >= stop_t and _events_done.has("beam_on") and not _events_done.has("beam_off"):
		_events_done["beam_off"] = true
		_laser.firing = false
		bus.emit_signal(&"mining_beam_stopped")


# --- Shots ----------------------------------------------------------------------

func _start_shot(s: StringName) -> void:
	shot = s
	shot_time = 0.0
	_frame = 0
	_events_done.clear()
	_pf_frames = 0
	_pf_cpu = 0.0
	_pf_gpu = 0.0
	_pf_draw = 0
	_pf_prims = 0
	_pf_particles = 0
	if bus != null:
		bus.emit_signal(&"mining_beam_stopped")
	for p: Node3D in _pickups:
		if is_instance_valid(p):
			p.queue_free()
	_pickups.clear()
	for a: Node3D in _asteroids:
		a.visible = false
	_ship.visible = true
	_ship.position = Vector3.ZERO
	_ship.rotation = Vector3.ZERO
	_trail.set_thrust(0.0, false)
	var bg := $SpaceBackground as SpaceBackground
	bg.planet_offset = Vector2(34.0, -20.0)
	match shot:
		&"engine":
			_place_asteroid(3, Vector3(-5, 0, -8), 0.8)
			_place_asteroid(5, Vector3(4, 0, -16), 0.8)
		&"beam":
			_ship.position = Vector3(0, 0, 4.5)
			_place_asteroid(0, Vector3(0, 0, -3.0))
			_place_asteroid(3, Vector3(5, 0, 1.0), 0.8)
		&"break":
			_ship.position = Vector3(0, 0, 6)
			_place_asteroid(0, Vector3(-3.5, 0, -1.0))
			_place_asteroid(3, Vector3(4.0, 0, 2.0))
			_place_asteroid(1, Vector3(1.5, 0, -6.0), 0.9)
		&"ore":
			_ship.position = Vector3(0, 0, 1.2)
			_place_asteroid(4, Vector3(-5.5, 0, -3.5), 0.8)
			var items: Array[StringName] = [&"ore_common_solid", &"ore_common_solid", &"crystal_blue_solid", &"crystal_blue_solid", &"ore_common_solid"]
			for i in 5:
				var ang := -PI * 0.5 + (i - 2) * 0.5
				_make_pickup(Vector3(cos(ang) * 2.6, 0, sin(ang) * 2.2 - 0.2), items[i])
		&"overview", &"background":
			if shot == &"overview":
				_place_asteroid(0, Vector3(4, 0, -4))
				_place_asteroid(1, Vector3(-13, 0, -7))
				_place_asteroid(2, Vector3(-11, 0, 7))
				_place_asteroid(3, Vector3(9, 0, 5))
				_place_asteroid(4, Vector3(-16, 0, 0))
				_place_asteroid(5, Vector3(14, 0, -8))
				for i in 3:
					_make_pickup(Vector3(-4.0 + i * 1.3, 0, 3.2 + (i % 2) * 0.9), &"crystal_blue_solid" if i == 1 else &"ore_common_solid", true)
			else:
				_ship.visible = false
	_update_shot(0.0)


func _process(delta: float) -> void:
	shot_time += delta
	_update_shot(delta)
	if capture_dir != "":
		_capture_frame()


func _update_shot(delta: float) -> void:
	var t := shot_time
	match shot:
		&"engine":
			var thr := clampf(t / 1.6, 0.0, 1.0)
			var boost := t > 2.4 or Input.is_key_pressed(KEY_SHIFT)
			var speed := 1.0 + 6.0 * thr + (6.0 if boost else 0.0)
			_ship.position.z -= speed * delta
			_ship.rotation.y = 0.15 * sin(t * 1.3)
			_trail.set_thrust(thr, boost)
			_cam_at(_ship.position + Vector3(0, 0, -0.6), 6.5)
		&"beam":
			_trail.set_thrust(0.1, false)
			_ship.rotation.y = 0.12 * sin(t * 1.4)
			_cam_at(Vector3(0, 0, 1.6), 9.0)
			_drive_beam(t, 0.2, 2.7, 0)
		&"break":
			_cam_at(Vector3(0, 0, 0.5), 15.0)
			_once("b1", t >= 0.2, func() -> void: _break(0, 2.5))
			_once("b2", t >= 0.6, func() -> void: _break(3, 1.2))
			_once("b3", t >= 1.0, func() -> void: _break(1, 4.0))
		&"ore":
			_cam_at(Vector3(0, 0, 0.6), 9.0)
			_trail.set_thrust(0.15, false)
			for i in _pickups.size():
				var p := _pickups[i]
				if not is_instance_valid(p):
					continue
				p.rotate_y(delta * 1.5)
				if t > 1.0 + i * 0.3:
					var to := _ship.position - p.position
					var step := minf(to.length(), (4.0 + (t - 1.0 - i * 0.3) * 10.0) * delta)
					p.position += to.normalized() * step
					if to.length() < 0.35:
						if bus != null:
							bus.emit_signal(&"ore_collected", (p as VfxLookdevStubs.PickupStub).item_id, 1, p.global_position)
						p.queue_free()
		&"overview":
			# Strafe slowly on an arc ~7 m from the asteroid centre, nose on it.
			var ang := 2.2 + 0.18 * sin(t * 0.8)
			var center := _asteroids[0].global_position
			_ship.position = center + Vector3(cos(ang), 0, sin(ang)) * 7.0
			var face := center - _ship.position
			_ship.basis = Basis.looking_at(face.normalized(), Vector3.UP)
			_trail.set_thrust(0.3, false)
			_cam_at(_ship.position + Vector3(1.5, 0, -1.5), 40.0, 18.0)
			_drive_beam(t, 0.1, 99.0, 0)
			_once("ob", t >= 1.5, func() -> void: _break(3, 1.2))
			for p: Node3D in _pickups:
				if is_instance_valid(p):
					p.rotate_y(delta * 1.2)
		&"background":
			_cam_at(Vector3(t * 12.0 - 18.0, 0, -t * 4.0), 40.0, 18.0)


func _break(i: int, size: Variant) -> void:
	_asteroids[i].visible = false
	if bus != null:
		bus.emit_signal(&"asteroid_destroyed", _asteroids[i].global_position, size)


func _once(key: String, cond: bool, f: Callable) -> void:
	if cond and not _events_done.has(key):
		_events_done[key] = true
		f.call()


## Camera like game_camera.gd: above the focus, tilted 10 degrees towards +Z.
## ortho_size > 0 = orthographic (game default 18/24/32 m), else 35 deg perspective.
func _cam_at(focus: Vector3, dist: float, ortho_size: float = 0.0) -> void:
	var tilt := deg_to_rad(10.0)
	if ortho_size > 0.0:
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = ortho_size
	else:
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		cam.fov = 35.0
	cam.global_position = focus + Vector3(0.0, cos(tilt), sin(tilt)) * dist
	cam.look_at(focus, Vector3.FORWARD)


# --- Capture --------------------------------------------------------------------

func _capture_frame() -> void:
	_frame += 1
	var vp_rid := get_viewport().get_viewport_rid()
	_pf_frames += 1
	_pf_cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp_rid)
	_pf_gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp_rid)
	_pf_draw = maxi(_pf_draw, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	_pf_prims = maxi(_pf_prims, int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	_pf_particles = maxi(_pf_particles, _live_particle_budget())
	if _frame > 2 and _frame % capture_every == 0:
		var img := get_viewport().get_texture().get_image()
		var dir := capture_dir.path_join(String(shot))
		DirAccess.make_dir_recursive_absolute(dir)
		img.save_png(dir.path_join("f_%03d.png" % floori(float(_frame) / capture_every)))
	if shot_time >= SHOT_LENGTH[shot]:
		var n := maxi(_pf_frames, 1)
		_perf.append("%s: frames=%d avg_render_cpu_ms=%.2f avg_render_gpu_ms=%.2f max_draw_calls=%d max_primitives=%d max_particle_budget=%d" % [
			shot, n, _pf_cpu / n, _pf_gpu / n, _pf_draw, _pf_prims, _pf_particles])
		if capture_shots.is_empty():
			var f := FileAccess.open(capture_dir.path_join("perf.txt"), FileAccess.WRITE)
			f.store_string("\n".join(_perf) + "\n")
			f.close()
			print("\n".join(_perf))
			get_tree().quit(0)
		else:
			var next_shot: StringName = capture_shots.pop_front()
			_start_shot(next_shot)


## Upper bound of live particles: sum of amount * amount_ratio of emitting/visible systems.
func _live_particle_budget() -> int:
	var total := 0
	for n: Node in get_tree().root.find_children("*", "GPUParticles3D", true, false):
		var p := n as GPUParticles3D
		if p.is_visible_in_tree() and (p.emitting or p.one_shot):
			total += ceili(p.amount * p.amount_ratio)
	return total
