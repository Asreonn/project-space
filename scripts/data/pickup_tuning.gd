class_name PickupTuning
extends Resource
## Ore pickup magnet / collection numbers (docs/briefs/mvp.md §3, m1_mining.json "pickups").

@export var magnet_radius: float = 5.0 ## m
@export var pull_accel: float = 40.0 ## m/s^2
@export var pull_max_speed: float = 22.0 ## m/s
@export var collect_radius: float = 1.2 ## m
@export var lifetime: float = 0.0 ## s; 0 = never despawn (MVP)
@export var pool_max_active: int = 150 ## past this, new drops merge into existing pickups
@export var merge_radius: float = 1.0 ## m
@export var scatter_speed_min: float = 2.0 ## m/s, spread on asteroid break
@export var scatter_speed_max: float = 5.0
@export var drift_damp: float = 1.5 ## 1/s, free pickups slow down
@export var attract_only_if_room: bool = true
@export var balance_prototype: bool = true
