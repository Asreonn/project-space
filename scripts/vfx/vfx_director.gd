class_name VfxDirector
extends Node3D
## One per sector (scenes/vfx/vfx_director.tscn). Listens to the EventBus
## autoload and drives every gameplay VFX itself; nobody else has to call it.
##   mining_beam_started/updated(origin, target)  -> MiningBeam on/follow
##   mining_beam_stopped()                         -> MiningBeam fade out
##   asteroid_damaged(asteroid, hp, max_hp, hit)   -> sparks/hot spot on (beam is hitting)
##   asteroid_destroyed(position, size)            -> pooled AsteroidBreak (size: radius m,
##                                                    or &"S"/&"M"/&"L")
##   ore_spawned(pickup, item_id, amount)          -> OreGlow child on the pickup node
##   ore_collected(item_id, amount[, position])    -> pooled collect pop at the pickup
## Signals are connected only if EventBus defines them, so this works while
## the bus is still growing. Every effect is bounded (see README budgets).

const ORE_GLOW_SCENE := preload("res://scenes/vfx/ore_glow.tscn")
## Radius (m) used for S/M/L when asteroid_destroyed sends a size class.
const SIZE_CLASS_RADIUS: Dictionary[StringName, float] = {&"S": 1.2, &"M": 2.5, &"L": 4.0}
const COLLECTOR_GROUP := &"pickup_collector"

## Ore colour per item id (glow + pop). Unknown ids use default_ore_color.
@export var ore_colors: Dictionary[StringName, Color] = {
	&"iron_ore": Color(1.0, 0.62, 0.25),
	&"copper_ore": Color(1.0, 0.55, 0.3),
	&"gold_ore": Color(1.0, 0.78, 0.3),
	&"crystal": Color(0.45, 0.85, 1.0),
	&"blue_crystal": Color(0.45, 0.85, 1.0),
}
@export var default_ore_color: Color = Color(1.0, 0.62, 0.25)
## Cap for live ore glows (extra pickups simply get no glow).
@export var max_ore_glows: int = 48
## Beam counts as "hitting" this long after the last asteroid_damaged.
@export var hit_hold_time: float = 0.2

var connected: Array[StringName] = []
var _since_hit: float = 1000.0
var _glows: Array[OreGlow] = []

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
		if hitting != beam.hitting:
			beam.set_target(beam.target_point, hitting)


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


func _on_beam_started(origin: Variant, target: Variant) -> void:
	beam.start(origin, _point(target))
	beam.set_target(_point(target), false)


func _on_beam_updated(origin: Variant, target: Variant) -> void:
	beam.set_origin(origin)
	beam.set_target(_point(target), beam.hitting)


func _on_beam_stopped() -> void:
	beam.stop()


func _on_asteroid_damaged(_asteroid: Node3D, _hp: float = 0.0, _max_hp: float = 0.0, hit_point: Variant = null) -> void:
	_since_hit = 0.0
	if hit_point is Vector3 and beam.active:
		var hp: Vector3 = hit_point
		beam.set_target(hp, true)
	elif beam.active:
		beam.set_target(beam.target_point, true)


func _on_asteroid_destroyed(at: Vector3, size: Variant = &"M") -> void:
	play_asteroid_break(at, size)


func _on_ore_spawned(pickup: Node3D, item_id: StringName = &"", _amount: int = 0) -> void:
	add_ore_glow(pickup, item_id)


func _on_ore_collected(item_id: StringName, _amount: int = 0, at: Variant = null) -> void:
	var p: Variant = at
	if not (p is Vector3):
		p = _guess_collect_point()
	if p is Vector3:
		var v: Vector3 = p
		play_collect(v, item_id)


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
