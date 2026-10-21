class_name MvpFxBridge
extends Node3D
## VFX glue for the MVP sector (mvp.md §5, scenes/vfx/README.md).
## mvp_sector.tscn instances VfxDirector, SpaceBackground and PostFx directly
## and sets WorldEnvironment to environment_space.tres; this node only:
## - puts ONE scenes/vfx/engine_trail.tscn under the ship's Visual (it finds the
##   FX_EngineTrail_<n> empties and re-attaches on rebuilds itself) and calls
##   set_thrust(amount, boosting) every frame;
## - falls back to primitive placeholders (beam, break flash, trail cones) when
##   the VFX scenes are missing, so the loop stays readable without them.

const ENGINE_TRAIL := "res://scenes/vfx/engine_trail.tscn"
const ENVIRONMENT := "res://scenes/vfx/environment_space.tres"

## The sector's VfxDirector; when it is there the placeholder beam/break are off.
@export var director_path: NodePath

var ship: ShipController
var assembler: ShipAssembler
var has_director: bool = false
## The VFX EngineTrail node (null = placeholder cones).
var engine_trail: Node3D

var _trails: Array[Node3D] = []
var _beam: Node3D
var _beam_origin: Node3D
var _beam_target: Node3D
var _beam_hit: Vector3 = Vector3.ZERO


func setup(p_ship: ShipController, p_assembler: ShipAssembler, world_env: WorldEnvironment) -> void:
	ship = p_ship
	assembler = p_assembler
	if world_env != null and world_env.environment == null and ResourceLoader.exists(ENVIRONMENT):
		world_env.environment = load(ENVIRONMENT) as Environment
	if ResourceLoader.exists(ENGINE_TRAIL):
		var packed := load(ENGINE_TRAIL) as PackedScene
		engine_trail = packed.instantiate() as Node3D if packed != null else null
	if engine_trail != null:
		engine_trail.name = "EngineTrail"
		var visual := assembler.get_parent() as Node3D
		(visual if visual != null else ship as Node3D).add_child(engine_trail)
		return
	assembler.assembled.connect(_attach_trails)
	assembler.part_level_changed.connect(_on_part_level_changed)
	_attach_trails()


func _ready() -> void:
	has_director = director_path != NodePath() and get_node_or_null(director_path) != null
	if has_director:
		return
	EventBus.mining_beam_started.connect(_on_beam_started)
	EventBus.mining_beam_stopped.connect(_on_beam_stopped)
	EventBus.asteroid_damaged.connect(_on_asteroid_damaged)
	EventBus.asteroid_destroyed.connect(_on_asteroid_destroyed)
	_beam = Node3D.new()
	_beam.name = "PlaceholderBeam"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.06
	mesh.bottom_radius = 0.06
	mesh.height = 1.0
	mesh.radial_segments = 8
	mesh.material = _glow(Color(1.0, 0.55, 0.25), 4.0)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	_beam.add_child(mi)
	_beam.visible = false
	add_child(_beam)


func _process(_dt: float) -> void:
	_update_trails()
	if _beam == null or not _beam.visible:
		return
	if not is_instance_valid(_beam_origin):
		_beam.visible = false
		return
	var a := _beam_origin.global_position
	var b := _beam_hit
	if is_instance_valid(_beam_target) and b == Vector3.ZERO:
		b = _beam_target.global_position
	var length := a.distance_to(b)
	if length < 0.05:
		return
	_beam.global_position = (a + b) * 0.5
	_beam.look_at(b, Vector3.UP)
	_beam.scale = Vector3(1.0, 1.0, length)


func _on_beam_started(origin: Node3D, target: Node3D) -> void:
	_beam_origin = origin
	_beam_target = target
	_beam_hit = Vector3.ZERO
	_beam.visible = true


func _on_beam_stopped() -> void:
	_beam.visible = false
	_beam_target = null


func _on_asteroid_damaged(asteroid: Node3D, hit_position: Vector3, _hp_ratio: float) -> void:
	if asteroid == _beam_target:
		_beam_hit = hit_position


func _on_asteroid_destroyed(pos: Vector3, radius: float) -> void:
	var scale_m := radius
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	var mat := _glow(Color(1.0, 0.75, 0.45), 3.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.name = "BreakFlash"
	mi.mesh = mesh
	add_child(mi, true)
	mi.global_position = pos
	var tween := mi.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.4).from(0.9)
	tween.parallel().tween_property(mi, "scale", Vector3.ONE * scale_m * 1.3, 0.4).from(Vector3.ONE * scale_m * 0.4)
	tween.tween_callback(mi.queue_free)


func _on_part_level_changed(slot: ShipPartDefinition.Slot, _level: int) -> void:
	if slot == ShipPartDefinition.Slot.ENGINE or slot == ShipPartDefinition.Slot.BODY:
		_attach_trails()


func _attach_trails() -> void:
	_trails.clear()
	if assembler == null:
		return
	for marker: Node3D in assembler.get_engine_trail_points():
		var existing := marker.get_node_or_null(^"Trail") as Node3D
		if existing != null:
			_trails.append(existing)
			continue
		var trail := _placeholder_trail()
		trail.name = "Trail"
		marker.add_child(trail)
		_trails.append(trail)


func _update_trails() -> void:
	if ship == null or not is_instance_valid(ship):
		return
	var fly := maxf(ship.get_stat(ShipController.STAT_FLYING_SPEED), 0.1)
	var amount := clampf(maxf(ship.in_thrust, 0.0) * 0.6 + ship.get_speed() / fly * 0.4, 0.0, 1.0)
	if is_instance_valid(engine_trail):
		engine_trail.call(&"set_thrust", amount, ship.boosting)
		return
	for t: Node3D in _trails:
		if not is_instance_valid(t):
			continue
		var len_scale := 0.15 + amount * (1.6 if ship.boosting else 1.0)
		t.scale = Vector3(1.0, 1.0, len_scale)
		t.visible = amount > 0.02


static func _placeholder_trail() -> Node3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = 0.06
	mesh.height = 0.7
	mesh.radial_segments = 6
	mesh.material = _glow(Color(0.45, 0.8, 1.0), 3.0)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	mi.position = Vector3(0.0, 0.0, 0.35)
	var root := Node3D.new()
	root.add_child(mi)
	return root


static func _glow(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	return mat
