class_name EngineTrail
extends Node3D
## Engine trail for a whole ship (scenes/vfx/engine_trail.tscn).
## Instance it anywhere under the player ship; it finds every
## `FX_EngineTrail_<n>` empty in the ship and puts one EngineNozzleFx on each.
## The ship calls:
##   $EngineTrail.set_thrust(amount, boosting)   # amount 0..1, boost = bigger/brighter
## Re-attaches by itself when the ShipAssembler rebuilds (assembled /
## part_level_changed) and on EventBus.part_upgraded(&"engine", level).

const TRAIL_PREFIX := "FX_EngineTrail_"
const NOZZLE_SCENE := preload("res://scenes/vfx/engine_nozzle.tscn")

## Node to search for FX_EngineTrail_<n>. Empty = the nearest ancestor that
## contains such empties (normally the ship root).
@export var ship_root: Node
## Bigger ships / nozzles: 1.0 = starter shuttle (1.84 m, ~0.11 m nozzles).
@export var size_scale: float = 1.0

var nozzles: Array[EngineNozzleFx] = []
var thrust: float = 0.0
var boosting: bool = false
var _root: Node


func _ready() -> void:
	var bus := get_node_or_null(^"/root/EventBus")
	if bus != null and bus.has_signal(&"part_upgraded"):
		bus.connect(&"part_upgraded", _on_part_upgraded)
	# The ShipAssembler usually builds in the ship's _ready, after ours: wait a frame.
	_attach_deferred.call_deferred()


## amount: 0..1 throttle / normalised speed. boosting: boost look.
func set_thrust(amount: float, is_boosting: bool = false) -> void:
	thrust = clampf(amount, 0.0, 1.0)
	boosting = is_boosting
	for n: EngineNozzleFx in nozzles:
		if is_instance_valid(n):
			n.set_throttle(thrust)
			n.set_boost(boosting)


## Finds the empties again and (re)creates the nozzle effects. Returns the count.
func attach(root: Node = null) -> int:
	_clear()
	_root = root if root != null else _find_root()
	if _root == null:
		return 0
	for sig: StringName in [&"assembled", &"part_level_changed"]:
		for src: Node in _assemblers(_root):
			if src.has_signal(sig) and not src.is_connected(sig, _on_rebuilt):
				src.connect(sig, _on_rebuilt)
	var points := _root.find_children(TRAIL_PREFIX + "*", "Node3D", true, false)
	points.sort_custom(func(a: Node, b: Node) -> bool: return String(a.name).naturalnocasecmp_to(String(b.name)) < 0)
	for p: Node in points:
		var fx := NOZZLE_SCENE.instantiate() as EngineNozzleFx
		fx.size_scale = size_scale
		p.add_child(fx)
		fx.set_throttle(thrust)
		fx.set_boost(boosting)
		nozzles.append(fx)
	return nozzles.size()


func _attach_deferred() -> void:
	attach(ship_root)


func _find_root() -> Node:
	var n: Node = get_parent()
	while n != null and n != get_tree().root:
		if not n.find_children(TRAIL_PREFIX + "*", "Node3D", true, false).is_empty():
			return n
		if n.has_signal(&"assembled"):
			return n
		n = n.get_parent()
	return get_parent()


func _assemblers(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	if root.has_signal(&"assembled"):
		out.append(root)
	for c: Node in root.find_children("*", "Node3D", true, false):
		if c.has_signal(&"assembled"):
			out.append(c)
	return out


func _clear() -> void:
	for n: EngineNozzleFx in nozzles:
		if is_instance_valid(n):
			n.queue_free()
	nozzles.clear()


func _on_rebuilt(_a: Variant = null, _b: Variant = null) -> void:
	_attach_again.call_deferred()


func _attach_again() -> void:
	attach(_root)


func _on_part_upgraded(part: StringName, _level: int) -> void:
	if part == &"engine" or part == &"body":
		_attach_again.call_deferred()
