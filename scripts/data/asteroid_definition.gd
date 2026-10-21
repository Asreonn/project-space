class_name AsteroidDefinition
extends Resource
## One asteroid type (docs/briefs/mvp.md §3). MVP model: a single HP pool; on
## break it scatters ore pickups. The per-node surface/vein/core model from
## m1_mining.json comes after the MVP.

@export var id: StringName ## e.g. asteroid_m
@export var display_name: String
## &"S", &"M" or &"L" (asteroid.tscn root exposes it; VFX scales by it).
@export_enum("S", "M", "L") var size: String = "M"
@export var max_hp: float = 80.0
## Modeler GLB variants (one picked per spawn) and their XZ radius in metres.
## Empty or missing files = primitive placeholder of radius `radius`.
@export var model_scene_paths: Array[String] = []
@export var model_radii: Array[float] = []
@export var radius: float = 2.5 ## m, placeholder / fallback radius
@export var ore: ResourceDefinition
@export var ore_units_min: int = 5 ## total dropped on break (rolled)
@export var ore_units_max: int = 7
## Optional second resource (ore-vein variants): this fraction of the rolled
## units is dropped as secondary_ore instead of ore.
@export var secondary_ore: ResourceDefinition
@export_range(0.0, 1.0) var secondary_fraction: float = 0.0
@export var units_per_pickup_min: int = 1
@export var units_per_pickup_max: int = 2
@export var placeholder_color: Color = Color(0.45, 0.42, 0.4)
@export var spin_speed_deg: float = 6.0 ## max slow idle spin, deg/s
@export var balance_prototype: bool = true


func get_size_name() -> StringName:
	return StringName(size)
