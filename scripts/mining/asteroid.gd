class_name Asteroid
extends StaticBody3D
## Minable asteroid, root of scenes/world/asteroid.tscn (MVP exception path,
## Godot Engineer). One HP pool from AsteroidDefinition. The mining beam only
## calls apply_mining_damage(); at 0 HP the asteroid breaks: ore pickups scatter
## through the PickupPool, EventBus.asteroid_destroyed fires and the node frees.
## Visual: modeler GLB variant when present, else a primitive placeholder.

signal broken(asteroid: Asteroid)

const PHYSICS_LAYER_ASTEROID := 4 ## layer 3 "asteroid"

@export var definition: AsteroidDefinition
## &"S", &"M" or &"L" (mvp.md §5).
var size: StringName = &"M"
var hp: float = 0.0
var radius: float = 2.5
var is_broken: bool = false
var model_path: String = "" ## "" = placeholder
var pickup_pool: PickupPool
var rng: RandomNumberGenerator

var _spin: Vector3 = Vector3.ZERO


func setup(def: AsteroidDefinition, p_rng: RandomNumberGenerator, pool: PickupPool) -> void:
	definition = def
	rng = p_rng
	pickup_pool = pool


func _ready() -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
	if definition == null:
		definition = AsteroidDefinition.new()
	size = definition.get_size_name()
	hp = definition.max_hp
	radius = definition.radius
	collision_layer = PHYSICS_LAYER_ASTEROID
	collision_mask = 0
	add_to_group(&"asteroids")
	_add_visual()
	var shape := SphereShape3D.new()
	shape.radius = radius * 0.85
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	col.shape = shape
	add_child(col)
	var spin_rad := deg_to_rad(definition.spin_speed_deg) * rng.randf_range(0.3, 1.0)
	_spin = Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)).normalized() * spin_rad


func _process(dt: float) -> void:
	var visual := get_node_or_null(^"Visual") as Node3D
	if visual != null and _spin.length_squared() > 0.0:
		visual.rotate(_spin.normalized(), _spin.length() * dt)


func get_hp_ratio() -> float:
	return hp / maxf(definition.max_hp, 0.001)


## Called by the mining beam every physics frame it touches this asteroid.
## Returns true when damage was applied (false once broken).
func apply_mining_damage(amount: float, hit_position: Vector3) -> bool:
	if is_broken or amount <= 0.0:
		return false
	hp = maxf(0.0, hp - amount)
	EventBus.asteroid_damaged.emit(self, hit_position, get_hp_ratio())
	if hp <= 0.0:
		break_apart()
	return true


func break_apart() -> void:
	if is_broken:
		return
	is_broken = true
	collision_layer = 0 # leave the asteroid layer so the beam re-targets this frame
	var pos := global_position if is_inside_tree() else position
	_spawn_ore(pos)
	EventBus.asteroid_destroyed.emit(pos, size)
	broken.emit(self)
	queue_free()


## Rolls the drop: [[item_id, units], ...] split into pickup-sized pieces.
func plan_drops() -> Array[Array]:
	var out: Array[Array] = []
	var total := rng.randi_range(definition.ore_units_min, maxi(definition.ore_units_min, definition.ore_units_max))
	var secondary := 0
	if definition.secondary_ore != null and definition.secondary_fraction > 0.0:
		secondary = roundi(total * definition.secondary_fraction)
	if definition.ore != null:
		_split(out, definition.ore.id, total - secondary)
	if secondary > 0:
		_split(out, definition.secondary_ore.id, secondary)
	return out


func _split(out: Array[Array], item_id: StringName, units: int) -> void:
	var lo := maxi(1, definition.units_per_pickup_min)
	var hi := maxi(lo, definition.units_per_pickup_max)
	while units > 0:
		var n := mini(units, rng.randi_range(lo, hi))
		out.append([item_id, n])
		units -= n


func _spawn_ore(center: Vector3) -> void:
	var pool := pickup_pool
	if pool == null and is_inside_tree():
		pool = get_tree().get_first_node_in_group(PickupPool.GROUP) as PickupPool
	if pool == null:
		push_warning("Asteroid: no PickupPool, ore lost")
		return
	for drop: Array in plan_drops():
		var item_id: StringName = drop[0]
		var units: int = drop[1]
		var angle := rng.randf() * TAU
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		var speed := rng.randf_range(pool.tuning.scatter_speed_min, pool.tuning.scatter_speed_max)
		pool.spawn(pool.to_local(center + dir * radius * 0.6), item_id, units, dir * speed)


func _add_visual() -> void:
	var node: Node3D = null
	var paths := definition.model_scene_paths
	if not paths.is_empty():
		var i := rng.randi_range(0, paths.size() - 1)
		if ResourceLoader.exists(paths[i]):
			var packed := load(paths[i]) as PackedScene
			node = packed.instantiate() as Node3D if packed != null else null
			if node != null:
				model_path = paths[i]
				if i < definition.model_radii.size():
					radius = definition.model_radii[i]
	if node == null:
		node = Node3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 1.6
		mesh.radial_segments = 10
		mesh.rings = 5
		var mat := StandardMaterial3D.new()
		mat.albedo_color = definition.placeholder_color
		mat.roughness = 0.95
		mesh.material = mat
		var mi := MeshInstance3D.new()
		mi.name = "PlaceholderMesh"
		mi.mesh = mesh
		node.add_child(mi)
	node.name = "Visual"
	node.rotation = Vector3(0.0, rng.randf() * TAU, 0.0)
	add_child(node)
