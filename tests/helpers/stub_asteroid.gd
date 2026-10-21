class_name StubAsteroid
extends StaticBody3D
## Test double for the Engineer's asteroid.gd (MVP API: apply_mining_damage,
## is_broken, size). Built from one entry of data/balance/mvp_economy_proposal.json.
## On break it records the ore it would drop (pickups are the Engineer's system).

signal broken(asteroid: StubAsteroid)

var size: StringName = &"S"
var radius: float = 1.0
var max_hp: float = 30.0
var hp: float = 30.0
var ore: StringName = &"ore_common_solid"
var ore_units: int = 3
var is_broken: bool = false
var damage_taken: float = 0.0


static func from_proposal(entry: Dictionary) -> StubAsteroid:
	var a := StubAsteroid.new()
	a.size = StringName(str(entry["size"]))
	a.max_hp = _f(entry["max_hp"])
	a.hp = a.max_hp
	a.ore = StringName(str(entry["ore"]))
	a.ore_units = _i(entry["ore_units"])
	a.collision_layer = 1 << 2 # asteroid
	a.collision_mask = 0
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	a.radius = _f(entry["radius"])
	sphere.radius = a.radius
	shape.shape = sphere
	a.add_child(shape)
	return a


func apply_mining_damage(amount: float, _hit_point: Vector3) -> bool:
	if is_broken:
		return false
	hp -= amount
	damage_taken += amount
	if hp <= 0.0:
		is_broken = true
		collision_layer = 0
		EventBus.asteroid_destroyed.emit(global_position, radius)
		broken.emit(self)
	return true


static func _f(v: Variant) -> float:
	var f: float = v
	return f


static func _i(v: Variant) -> int:
	var f: float = v
	return roundi(f)
