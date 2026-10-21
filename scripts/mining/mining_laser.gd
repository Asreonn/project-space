class_name MiningLaser
extends Node3D
## MVP mining beam (Gameplay Designer; docs/briefs/mvp.md §3, mvp_balance.md §3).
## Hold fire_primary (LMB): a beam leaves the head's FX_MiningOrigin toward the
## mouse aim, clamped to firing_arc_deg around the nose and to beam_range, and
## raycasts the asteroid physics layer. The first asteroid hit takes
## definition.damage_per_second(mining_power) * dt through its
## apply_mining_damage(amount, hit_point) method (asteroid.gd, Godot Engineer).
## The beam never moves ore into cargo; ore drops on break and the magnet collects it.
## EventBus: mining_beam_started(origin, target) / mining_beam_updated(origin, target)
## each physics frame while on / mining_beam_stopped(). Positions in world space.
## Public API matches the integration build (setup, set_stats, mine, beam_*).

signal firing_changed(on: bool)
signal target_changed(target: Node3D)

## Physics layer 3 "asteroid" in project.godot -> bit value 4.
const ASTEROID_MASK := 1 << 2
const DAMAGE_METHOD := &"apply_mining_damage"

@export var definition: MiningLaserDefinition
## false: set wants_fire from code (tests / autopilot).
@export var use_player_input: bool = true

var ship: ShipController
var assembler: ShipAssembler
var mining_power: float = 10.0
var wants_fire: bool = false
var firing: bool = false
var beam_origin: Vector3 = Vector3.ZERO
var beam_end: Vector3 = Vector3.ZERO
## Asteroid root node currently under the beam (null = beam hits nothing).
var hit_asteroid: Node3D
var _spin_t: float = 0.0


func _ready() -> void:
	if definition == null:
		definition = MiningLaserDefinition.new()
	if ship == null:
		ship = _find_ship()
	_auto_setup.call_deferred()
	if EventBus.has_signal(&"asteroid_destroyed"):
		EventBus.connect(&"asteroid_destroyed", _on_asteroid_destroyed)


## Standalone player_ship.tscn: pick up the ship's assembler once the ship is ready.
func _auto_setup() -> void:
	if assembler == null and ship != null and ship.assembler != null:
		setup(ship, ship.assembler)


func setup(p_ship: ShipController, p_assembler: ShipAssembler) -> void:
	ship = p_ship
	if assembler != null and assembler.stats_changed.is_connected(set_stats):
		assembler.stats_changed.disconnect(set_stats)
	assembler = p_assembler
	if assembler != null:
		assembler.stats_changed.connect(set_stats)
		if not assembler.stats.is_empty():
			set_stats(assembler.stats)


func set_stats(stats: Dictionary) -> void:
	var mp: float = stats.get(definition.uses_stat, 10.0)
	mining_power = mp


func damage_per_second() -> float:
	return definition.damage_per_second(mining_power)


func _physics_process(dt: float) -> void:
	if use_player_input:
		wants_fire = Input.is_action_pressed(&"fire_primary")
	var locked := ship != null and ship.input_locked
	_set_firing(wants_fire and not locked)
	if firing:
		_tick(dt)


## Direct damage path (tests / scripted mining): bypasses the raycast.
func mine(asteroid: Node3D, dt: float) -> bool:
	if not _is_minable(asteroid):
		return false
	var ok: bool = asteroid.call(DAMAGE_METHOD, damage_per_second() * dt, asteroid.global_position)
	return ok


func get_origin() -> Vector3:
	var marker := assembler.get_mining_origin() if assembler != null else null
	if marker != null and marker.is_inside_tree():
		return marker.global_position
	return global_position


## Beam direction on the XZ plane: toward the aim point, clamped to the arc.
func get_aim_direction() -> Vector3:
	var fwd := ship.get_forward() if ship != null else _flat(-global_basis.z)
	if ship == null or not ship.has_aim:
		return fwd
	var to := ship.aim_point - get_origin()
	to.y = 0.0
	if to.length_squared() < 0.01:
		return fwd
	var dir := to.normalized()
	var arc := deg_to_rad(definition.firing_arc_deg)
	var angle := fwd.signed_angle_to(dir, Vector3.UP)
	if absf(angle) > arc:
		dir = fwd.rotated(Vector3.UP, signf(angle) * arc)
	return dir


func _set_firing(on: bool) -> void:
	if on == firing:
		return
	firing = on
	_spin_t = 0.0
	if on:
		_update_beam()
		EventBus.mining_beam_started.emit(beam_origin, beam_end)
	else:
		_set_target(null)
		EventBus.mining_beam_stopped.emit()
	firing_changed.emit(on)


func _tick(dt: float) -> void:
	_spin_t += dt
	_update_beam()
	EventBus.mining_beam_updated.emit(beam_origin, beam_end)
	if hit_asteroid != null and _spin_t >= definition.spin_up:
		hit_asteroid.call(DAMAGE_METHOD, damage_per_second() * dt, beam_end)


func _update_beam() -> void:
	beam_origin = get_origin()
	var far := beam_origin + get_aim_direction() * definition.beam_range
	beam_end = far
	var target: Node3D = null
	if is_inside_tree():
		var query := PhysicsRayQueryParameters3D.create(beam_origin, far, ASTEROID_MASK)
		if ship != null:
			query.exclude = [ship.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var collider: Object = hit["collider"]
			var root := _asteroid_root(collider as Node)
			if _is_minable(root):
				beam_end = hit["position"]
				target = root
	_set_target(target)


func _set_target(target: Node3D) -> void:
	if target == hit_asteroid:
		return
	hit_asteroid = target
	target_changed.emit(target)


## The collider may be a child body of the asteroid root; walk up to the node
## that owns apply_mining_damage().
static func _asteroid_root(n: Node) -> Node3D:
	while n != null:
		if n.has_method(DAMAGE_METHOD):
			return n as Node3D
		n = n.get_parent()
	return null


static func _is_minable(n: Node3D) -> bool:
	if n == null or not is_instance_valid(n) or not n.has_method(DAMAGE_METHOD):
		return false
	if not (&"is_broken" in n):
		return true
	var broken: bool = n.get(&"is_broken")
	return not broken


func _on_asteroid_destroyed(_position: Vector3, _size: float) -> void:
	# The broken asteroid leaves the asteroid layer; re-cast now so the beam
	# does not keep pointing at it for a frame.
	if firing:
		_update_beam()


func _find_ship() -> ShipController:
	var n := get_parent()
	while n != null:
		if n is ShipController:
			return n as ShipController
		n = n.get_parent()
	return null


static func _flat(v: Vector3) -> Vector3:
	v.y = 0.0
	return v.normalized()
