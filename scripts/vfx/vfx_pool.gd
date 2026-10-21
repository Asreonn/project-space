class_name VfxPool
extends Node3D
## Fixed-size round-robin pool for one-shot effects. No runtime spawning:
## all instances are created in _ready(); when every instance is busy the
## oldest one is restarted, so the particle count is always bounded.
##   pool.play(&"asteroid_break", pos, asteroid_radius)
##   pool.play(&"ore_collect", pos, -1.0, ore_color)
## Used inside VfxDirector; effects only need play()/finished.

@export var effects: Dictionary[StringName, PackedScene] = {
	&"asteroid_break": preload("res://scenes/vfx/asteroid_break.tscn"),
	&"ore_collect": preload("res://scenes/vfx/ore_collect_pop.tscn"),
}
## Instances per effect (MVP: 4 breaks / 6 pops on screen at once is plenty).
@export var sizes: Dictionary[StringName, int] = {
	&"asteroid_break": 4,
	&"ore_collect": 6,
}

var _items: Dictionary[StringName, Array] = {}
var _next: Dictionary[StringName, int] = {}


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	for key: StringName in effects.keys():
		var n: int = sizes.get(key, 4)
		var list: Array[VfxOneShot] = []
		for i in n:
			var fx := effects[key].instantiate() as VfxOneShot
			fx.name = "%s_%d" % [key, i]
			add_child(fx)
			list.append(fx)
		_items[key] = list
		_next[key] = 0


func play(key: StringName, at: Vector3, size: float = -1.0, color: Color = Color(0, 0, 0, 0)) -> VfxOneShot:
	var list: Array = _items.get(key, [])
	if list.is_empty():
		push_warning("VfxPool: unknown effect '%s'" % key)
		return null
	var start: int = _next[key]
	var pick: VfxOneShot = null
	for i in list.size():
		var fx: VfxOneShot = list[(start + i) % list.size()]
		if not fx.playing:
			pick = fx
			_next[key] = (start + i + 1) % list.size()
			break
	if pick == null:
		pick = list[start]
		_next[key] = (start + 1) % list.size()
	pick.play(at, size, color)
	return pick


func active_count(key: StringName) -> int:
	var c := 0
	for fx: VfxOneShot in _items.get(key, []):
		if fx.playing:
			c += 1
	return c
