class_name AsteroidField
extends Node3D
## Places the sector's asteroids from a SectorDefinition (seeded clusters of
## 3-5 in the 25-100 m ring) and respawns broken ones after respawn_delay, at
## least respawn_min_player_distance from the player (mvp.md §3).

signal field_ready

const ASTEROID_SCENE := "res://scenes/world/asteroid.tscn"

@export var sector: SectorDefinition
var pickup_pool: PickupPool
## Respawns keep away from this node (the player ship).
var avoid_target: Node3D
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _scene: PackedScene


func _ready() -> void:
	_scene = load(ASTEROID_SCENE) as PackedScene


func spawn_all() -> void:
	if sector == null:
		push_error("AsteroidField: no SectorDefinition")
		return
	rng.seed = sector.rng_seed
	for a: Asteroid in get_asteroids():
		remove_child(a)
		a.free()
	# Shuffle the requested types into one list, then fill clusters from it.
	var queue: Array[AsteroidDefinition] = []
	for i in sector.asteroid_types.size():
		var count: int = sector.asteroid_counts[i] if i < sector.asteroid_counts.size() else 0
		for n in count:
			queue.append(sector.asteroid_types[i])
	_shuffle(queue)
	var guard := 0
	while not queue.is_empty() and guard < 400:
		guard += 1
		var center := _random_ring_point()
		var members := rng.randi_range(sector.cluster_size_min, sector.cluster_size_max)
		for m in members:
			if queue.is_empty():
				break
			var def: AsteroidDefinition = queue.back()
			for attempt in 12:
				var offset := Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0)) * sector.cluster_spread
				if _try_spawn(def, center + offset, false) != null:
					queue.pop_back()
					break
	if not queue.is_empty():
		push_warning("AsteroidField: %d asteroids could not be placed" % queue.size())
	field_ready.emit()


func get_asteroids() -> Array[Asteroid]:
	var out: Array[Asteroid] = []
	for c: Node in get_children():
		var a := c as Asteroid
		if a != null and not a.is_broken and not a.is_queued_for_deletion():
			out.append(a)
	return out


func _random_ring_point() -> Vector3:
	var angle := rng.randf() * TAU
	var r2 := rng.randf_range(sector.ring_min_radius * sector.ring_min_radius, sector.ring_max_radius * sector.ring_max_radius)
	return sector.station_position + Vector3(cos(angle), 0.0, sin(angle)) * sqrt(r2)


func _try_spawn(def: AsteroidDefinition, pos: Vector3, avoid_player: bool) -> Asteroid:
	pos.y = 0.0
	var d := pos.distance_to(sector.station_position)
	if d < sector.ring_min_radius or d > sector.ring_max_radius:
		return null
	var max_r := def.radius
	for r: float in def.model_radii:
		max_r = maxf(max_r, r)
	for other: Asteroid in get_asteroids():
		if other.position.distance_to(pos) < other.radius + max_r + sector.min_gap:
			return null
	if pos.distance_to(sector.player_spawn) < max_r + 8.0:
		return null
	if avoid_player and avoid_target != null and is_instance_valid(avoid_target):
		if avoid_target.global_position.distance_to(pos) < sector.respawn_min_player_distance:
			return null
	var asteroid: Asteroid = _scene.instantiate() as Asteroid if _scene != null else Asteroid.new()
	asteroid.name = "Asteroid_%s" % def.id
	asteroid.setup(def, rng, pickup_pool)
	asteroid.position = pos
	asteroid.broken.connect(_on_asteroid_broken)
	add_child(asteroid, true)
	return asteroid


func _on_asteroid_broken(asteroid: Asteroid) -> void:
	if sector.respawn_delay <= 0.0 or not is_inside_tree():
		return
	var timer := get_tree().create_timer(sector.respawn_delay, false)
	timer.timeout.connect(_respawn.bind(asteroid.definition))


func _respawn(def: AsteroidDefinition) -> void:
	for i in 60:
		if _try_spawn(def, _random_ring_point(), true) != null:
			return
	# Player camps everywhere: try again later instead of dropping the asteroid.
	get_tree().create_timer(5.0, false).timeout.connect(_respawn.bind(def))


func _shuffle(list: Array[AsteroidDefinition]) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := list[i]
		list[i] = list[j]
		list[j] = tmp
