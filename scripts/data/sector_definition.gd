class_name SectorDefinition
extends Resource
## MVP sector layout (docs/briefs/mvp.md §3): one station in the centre, an
## asteroid ring placed in seeded clusters, a soft play-area boundary.

@export var id: StringName = &"mvp_sector_01"
@export var rng_seed: int = 1
@export var station_position: Vector3 = Vector3.ZERO
@export var player_spawn: Vector3 = Vector3(0.0, 0.0, 18.0)
@export var dock_radius: float = 5.0 ## m (station dock Area3D)
## Playable radius around the station; past boundary_radius the ship is pushed back.
@export var play_radius: float = 120.0
@export var boundary_radius: float = 130.0
@export var boundary_push: float = 20.0 ## m/s^2 per metre past the boundary (capped)
## Asteroid types and how many of each (same order). 15-25 total.
@export var asteroid_types: Array[AsteroidDefinition] = []
@export var asteroid_counts: Array[int] = []
@export var ring_min_radius: float = 25.0 ## m from station_position
@export var ring_max_radius: float = 100.0
@export var cluster_size_min: int = 3
@export var cluster_size_max: int = 5
@export var cluster_spread: float = 12.0 ## m, cluster member offset from its centre
@export var min_gap: float = 2.0 ## m of free space between asteroid surfaces
@export var respawn_delay: float = 60.0 ## s; <= 0 disables respawn
@export var respawn_min_player_distance: float = 40.0
@export var starting_credits: int = 0
## Every ResourceDefinition cargo and the station know.
@export var resources: Array[ResourceDefinition] = []
@export var balance_prototype: bool = true


func get_total_asteroids() -> int:
	var total := 0
	for n: int in asteroid_counts:
		total += n
	return total
