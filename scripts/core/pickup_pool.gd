class_name PickupPool
extends Node3D
## Owns every ore pickup in the sector (docs/briefs/mvp.md §3 "Toplama").
## spawn() places pickups (max tuning.pool_max_active; past that a drop merges
## into the nearest pickup of the same item, so nothing is lost). Each physics
## frame pickups drift, get pulled toward `target` (the ship) when GameState
## cargo has room, and go into cargo on contact. Full cargo: pickups stay put.
## Emits EventBus.ore_spawned / ore_collected.

const GROUP := &"pickup_pool"
const PICKUP_SCENE := "res://scenes/pickups/ore_pickup.tscn"

@export var tuning: PickupTuning
## Magnet point (the player ship). Null = no collection.
var target: Node3D

var _scene: PackedScene


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	if tuning == null:
		tuning = PickupTuning.new()
	_scene = load(PICKUP_SCENE) as PackedScene


func get_pickups() -> Array[OrePickup]:
	var out: Array[OrePickup] = []
	for c: Node in get_children():
		var p := c as OrePickup
		if p != null and not p.is_queued_for_deletion():
			out.append(p)
	return out


func get_total_units(item_id: StringName = &"") -> int:
	var total := 0
	for p: OrePickup in get_pickups():
		if item_id == &"" or p.item_id == item_id:
			total += p.amount
	return total


func spawn(pos: Vector3, item_id: StringName, amount: int, velocity: Vector3 = Vector3.ZERO) -> OrePickup:
	if amount <= 0:
		return null
	pos.y = 0.0
	var existing := get_pickups()
	if existing.size() >= tuning.pool_max_active:
		var merge := _nearest(existing, pos, item_id)
		if merge != null:
			merge.amount += amount
			return merge
	var pickup: OrePickup = _scene.instantiate() as OrePickup if _scene != null else OrePickup.new()
	var def := GameState.get_resource(item_id)
	if def != null:
		pickup.setup(item_id, amount, velocity, def.pickup_color, def.pickup_scene_path)
	else:
		pickup.setup(item_id, amount, velocity, Color(0.85, 0.7, 0.45))
	pickup.name = "OrePickup"
	pickup.position = pos
	add_child(pickup, true)
	EventBus.ore_spawned.emit(pickup.global_position, item_id, amount)
	return pickup


func _physics_process(dt: float) -> void:
	step(dt)


func step(dt: float) -> void:
	var has_target := target != null and is_instance_valid(target) and target.is_inside_tree()
	var target_pos := to_local(target.global_position) if has_target else Vector3.ZERO
	for p: OrePickup in get_pickups():
		if tuning.lifetime > 0.0 and p.age >= tuning.lifetime:
			p.queue_free()
			continue
		var room := GameState.has_room_for(p.item_id) or not tuning.attract_only_if_room
		if p.step(dt, tuning, target_pos, has_target, room):
			collect(p)


## Moves as much of p as fits into GameState cargo. Returns accepted units.
func collect(p: OrePickup) -> int:
	var accepted := GameState.add_cargo(p.item_id, p.amount)
	if accepted <= 0:
		return 0
	p.amount -= accepted
	EventBus.ore_collected.emit(p.item_id, accepted, p.global_position)
	if p.amount <= 0:
		# Gone right away: no orphan between frames, get_pickups() skips it.
		remove_child(p)
		p.free()
	return accepted


## Pulls every pickup straight into cargo (tests / debug). Returns accepted units.
func collect_all() -> int:
	var total := 0
	for p: OrePickup in get_pickups():
		total += collect(p)
	return total


func _nearest(list: Array[OrePickup], pos: Vector3, item_id: StringName) -> OrePickup:
	var best: OrePickup = null
	var best_d := INF
	for p: OrePickup in list:
		if p.item_id != item_id:
			continue
		var d := p.position.distance_squared_to(pos)
		if d < best_d:
			best_d = d
			best = p
	return best
