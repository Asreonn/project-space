class_name VfxDirector
extends Node3D
## One per sector (scenes/vfx/vfx_director.tscn). Listens to the EventBus
## autoload and drives every gameplay VFX itself; nobody else has to call it.
## Contract = scripts/core/event_bus.gd (mvp.md §6):
##   mining_beam_started(origin: Node3D, target: Node3D)  -> beam on. origin = FX_MiningOrigin
##       (followed every frame), target = asteroid or null. Emitted again on retarget.
##   mining_beam_stopped()                               -> beam fades out
##   asteroid_damaged(asteroid, hit_position, hp_ratio)  -> exact contact point, sparks, heat
##   asteroid_destroyed(position, radius: float)         -> pooled AsteroidBreak (S/M/L fallback)
##   ore_spawned(position, item_id, amount)              -> pickup glow (see _on_ore_spawned)
##   ore_collected(item_id, amount, position)            -> pooled collect pop
## Beam end, in priority order: the shooter's `beam_end` (a node with beam_origin/beam_end
## near the origin, i.e. MiningLaser), the last hit_position, the target's surface,
## else origin_node -Z * fallback_range. The beam never invents its own length.
## Older Vector3 forms (mining_beam_updated, 4-arg asteroid_damaged) are still accepted.

const ORE_GLOW_SCENE := preload("res://scenes/vfx/ore_glow.tscn")
const ORE_VISUAL_SCENE := preload("res://scenes/vfx/ore_pickup_visual.tscn")
## Radius (m) used for S/M/L when asteroid_destroyed sends a size class.
const SIZE_CLASS_RADIUS: Dictionary[StringName, float] = {&"S": 1.2, &"M": 2.5, &"L": 4.0}
const COLLECTOR_GROUP := &"pickup_collector"

## Ore colour per item id (glow + pop). Unknown ids use default_ore_color.
@export var ore_colors: Dictionary[StringName, Color] = {
	&"ore_common_solid": Color(1.0, 0.62, 0.25),
	&"crystal_blue_solid": Color(0.4, 0.85, 1.0),
}
@export var default_ore_color: Color = Color(1.0, 0.62, 0.25)
## Cap for live ore glows (extra pickups simply get no glow).
@export var max_ore_glows: int = 48
## Beam counts as "hitting" this long after the last asteroid_damaged.
@export var hit_hold_time: float = 0.2
## Only used when nothing else tells where the beam ends (no shooter, no target).
@export var fallback_range: float = 10.0
## Wrap a freshly spawned pickup's `Visual` in ore_pickup_visual.tscn (glow + bob;
## an existing model is kept, a placeholder box is replaced by the Modeler's model).
## Off = only add an OreGlow (e.g. once ore_pickup.tscn instances the visual itself).
@export var upgrade_placeholder_pickups: bool = true

var connected: Array[StringName] = []
var _since_hit: float = 1000.0
var _glows: Array[OreGlow] = []
var _beam_target: Node3D
var _beam_source: Node
var _last_hit: Vector3 = Vector3.ZERO
var _heat: float = 0.0
var _pending_spawns: Array[Dictionary] = []

@onready var beam: MiningBeam = $MiningBeam
@onready var pool: VfxPool = $VfxPool


func _ready() -> void:
	var bus := get_node_or_null(^"/root/EventBus")
	if bus == null:
		push_warning("VfxDirector: no EventBus autoload, effects only via direct calls")
		return
	_try(bus, &"mining_beam_started", _on_beam_started)
	_try(bus, &"mining_beam_updated", _on_beam_updated)
	_try(bus, &"mining_beam_stopped", _on_beam_stopped)
	_try(bus, &"asteroid_damaged", _on_asteroid_damaged)
	_try(bus, &"asteroid_destroyed", _on_asteroid_destroyed)
	_try(bus, &"ore_spawned", _on_ore_spawned)
	_try(bus, &"ore_collected", _on_ore_collected)


func _process(delta: float) -> void:
	_since_hit += delta
	if beam.active:
		var hitting := _since_hit <= hit_hold_time
		beam.set_end(_resolve_beam_end(hitting), hitting, _heat)
	if not _pending_spawns.is_empty():
		_attach_pending_glows()


func _resolve_beam_end(hitting: bool) -> Vector3:
	var origin := beam.origin_point
	if beam.origin_node != null and is_instance_valid(beam.origin_node):
		origin = beam.origin_node.global_position
	if _beam_source != null and is_instance_valid(_beam_source):
		var e: Variant = _beam_source.get(&"beam_end")
		if e is Vector3:
			var v: Vector3 = e
			if v.distance_squared_to(origin) > 0.0001:
				return v
	if hitting:
		return _last_hit
	if _beam_target != null and is_instance_valid(_beam_target):
		var c := _beam_target.global_position
		var to := c - origin
		to.y = 0.0
		var r := 0.0
		if _beam_target.has_method(&"get_radius"):
			var rv: Variant = _beam_target.call(&"get_radius")
			if rv is float:
				r = rv
		var dist := to.length()
		if dist > 0.001:
			return origin + to / dist * maxf(dist - r * 0.85, 0.1)
		return c
	if beam.origin_node != null and is_instance_valid(beam.origin_node):
		var fwd := -beam.origin_node.global_basis.z
		fwd.y = 0.0
		return origin + fwd.normalized() * fallback_range
	return beam.target_point


# --- Direct API (also used by the lookdev scene) -----------------------------

func play_asteroid_break(at: Vector3, size: Variant) -> void:
	pool.play(&"asteroid_break", at, size_to_radius(size))


func play_collect(at: Vector3, item_id: StringName = &"") -> void:
	pool.play(&"ore_collect", at, -1.0, ore_color(item_id))


func add_ore_glow(pickup: Node3D, item_id: StringName = &"") -> OreGlow:
	var alive: Array[OreGlow] = []
	for g: Variant in _glows:
		if is_instance_valid(g):
			var og: OreGlow = g
			alive.append(og)
	_glows = alive
	if pickup == null or _glows.size() >= max_ore_glows:
		return null
	var glow := ORE_GLOW_SCENE.instantiate() as OreGlow
	glow.color = ore_color(item_id)
	pickup.add_child(glow)
	_glows.append(glow)
	return glow


func ore_color(item_id: StringName) -> Color:
	return ore_colors.get(item_id, default_ore_color)


static func size_to_radius(size: Variant) -> float:
	if size is StringName or size is String:
		var key: StringName = StringName(str(size))
		return SIZE_CLASS_RADIUS.get(key, 2.5)
	if size is float or size is int:
		var r: float = size
		return r
	return 2.5


# --- EventBus handlers --------------------------------------------------------

func _try(bus: Node, sig: StringName, cb: Callable) -> void:
	if bus.has_signal(sig):
		bus.connect(sig, cb)
		connected.append(sig)


func _on_beam_started(origin: Variant, target: Variant = null) -> void:
	_beam_target = null
	if target is Node3D:
		_beam_target = target
	if origin is Node3D:
		var on: Node3D = origin
		_beam_source = _find_beam_source(on)
	else:
		_beam_source = null
	var was_active := beam.active
	beam.start(origin, beam.target_point if was_active else _point(origin))
	if not was_active:
		_since_hit = 1000.0
		_heat = 0.0
	if target is Vector3:
		var tv: Vector3 = target
		beam.set_end(tv, false)
	else:
		beam.set_end(_resolve_beam_end(false), false)


func _on_beam_updated(origin: Variant, target: Variant) -> void:
	beam.set_origin(origin)
	if target is Vector3:
		var tv: Vector3 = target
		_last_hit = tv
	beam.set_end(_point(target), beam.hitting)


func _on_beam_stopped() -> void:
	beam.stop()
	_beam_target = null
	_beam_source = null


## Current bus: (asteroid, hit_position: Vector3, hp_ratio: float).
## Older bus: (asteroid, current_hp, max_hp, hit_point: Vector3).
func _on_asteroid_damaged(_asteroid: Node3D, a: Variant = null, b: Variant = null, c: Variant = null) -> void:
	var hit: Variant = null
	var ratio := -1.0
	if a is Vector3:
		hit = a
		if b is float:
			ratio = b
	elif c is Vector3:
		hit = c
		if a is float and b is float:
			var cur: float = a
			var mx: float = b
			if mx > 0.0:
				ratio = cur / mx
	if not (hit is Vector3):
		return
	var hv: Vector3 = hit
	if _since_hit > hit_hold_time:
		beam.flash()
	_since_hit = 0.0
	_last_hit = hv
	if ratio >= 0.0:
		_heat = clampf(1.0 - ratio, 0.0, 1.0)
	if beam.active and _beam_source == null:
		beam.set_end(hv, true, _heat)


## A node near the beam origin that exposes beam_origin/beam_end (MiningLaser).
func _find_beam_source(origin: Node3D) -> Node:
	var n: Node = origin
	for i in 6:
		if n == null:
			break
		if _is_beam_source(n):
			return n
		for child: Node in n.find_children("*", "", true, false):
			if _is_beam_source(child):
				return child
		n = n.get_parent()
	return null


static func _is_beam_source(n: Node) -> bool:
	return (n.get(&"beam_end") is Vector3) and (n.get(&"beam_origin") is Vector3)


func _on_asteroid_destroyed(at: Vector3, radius: Variant = 2.5) -> void:
	play_asteroid_break(at, radius)


## Current bus sends a position: the pickup node is found next frame near that
## point (pickups expose item_id); older bus sent the pickup node itself.
func _on_ore_spawned(pickup_or_position: Variant, item_id: StringName = &"", _amount: int = 0) -> void:
	if pickup_or_position is Node3D:
		var pn: Node3D = pickup_or_position
		_decorate_pickup(pn, item_id)
	elif pickup_or_position is Vector3:
		_pending_spawns.append({"pos": pickup_or_position, "item": item_id, "tries": 3})


func _on_ore_collected(item_id: StringName, _amount: int = 0, at: Variant = null) -> void:
	var p: Variant = at
	if not (p is Vector3):
		p = _guess_collect_point()
	if p is Vector3:
		var v: Vector3 = p
		play_collect(v, item_id)


func _attach_pending_glows() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		_pending_spawns.clear()
		return
	var candidates: Array[Node3D] = []
	var found: Array[Node] = get_tree().get_nodes_in_group(&"ore_pickups")
	if found.is_empty():
		found = scene.find_children("*", "Node3D", true, false)
	for n: Node in found:
		if n.get(&"item_id") is StringName and n.get(&"velocity") is Vector3 and not _is_decorated(n):
			candidates.append(n as Node3D)
	var keep: Array[Dictionary] = []
	for req: Dictionary in _pending_spawns:
		var pos: Vector3 = req["pos"]
		var best: Node3D = null
		var best_d := 1.0
		for cnd: Node3D in candidates:
			var d := cnd.global_position.distance_squared_to(pos)
			if d < best_d:
				best_d = d
				best = cnd
		if best != null:
			candidates.erase(best)
			var item: StringName = req["item"]
			_decorate_pickup(best, item)
		else:
			var tries: int = req["tries"]
			if tries > 1:
				req["tries"] = tries - 1
				keep.append(req)
	_pending_spawns = keep


func _is_decorated(n: Node) -> bool:
	for c: Node in n.get_children():
		if c is OreGlow or c is OrePickupVisual:
			return true
	return false


## Placeholder box -> model + glow + bob (if allowed), else just a glow.
func _decorate_pickup(pickup: Node3D, item_id: StringName) -> void:
	if pickup == null or _is_decorated(pickup):
		return
	var id := item_id
	if id == &"" and pickup.get(&"item_id") is StringName:
		id = pickup.get(&"item_id")
	var visual := pickup.get_node_or_null(^"Visual") as Node3D
	if not upgrade_placeholder_pickups:
		add_ore_glow(pickup, id)
		return
	var v := ORE_VISUAL_SCENE.instantiate() as OrePickupVisual
	v.item_id = id
	v.glow_color = ore_color(id)
	var is_placeholder := visual is MeshInstance3D and (visual as MeshInstance3D).mesh is BoxMesh
	if visual != null:
		visual.name = "SourceVisual"
		if is_placeholder:
			visual.queue_free()
		else:
			v.adopt(visual) # keep the model the pickup already loaded, add glow + bob around it
	v.name = "Visual"
	pickup.add_child(v)


## ore_collected has no position yet: use the glowing pickup closest to a
## pickup collector (the one being collected this frame), else the collector.
func _guess_collect_point() -> Variant:
	var collectors := get_tree().get_nodes_in_group(COLLECTOR_GROUP)
	if collectors.is_empty():
		return null
	var c := collectors[0] as Node3D
	if c == null:
		return null
	var best: Variant = c.global_position
	var best_d := 4.0 # m^2: only pickups right at the ship count
	for gv: Variant in _glows:
		if not is_instance_valid(gv):
			continue
		var g: OreGlow = gv
		if g.is_inside_tree():
			var d := g.global_position.distance_squared_to(c.global_position)
			if d < best_d:
				best_d = d
				best = g.global_position
	return best


static func _point(v: Variant) -> Vector3:
	if v is Vector3:
		var p: Vector3 = v
		return p
	if v is Node3D:
		var n: Node3D = v
		return n.global_position
	return Vector3.ZERO
