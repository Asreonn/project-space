class_name MiningLaserDefinition
extends Resource
## Mining laser module numbers (m1_mining.json "modules" -> laser_mk1).
## Only the fields the MVP beam uses; energy / heat are out of MVP scope.

@export var id: StringName = &"laser_mk1"
@export var display_name: String = "Mining Laser"
@export var beam_range: float = 14.0 ## m
@export var beam_radius: float = 0.3 ## m (VFX width hint)
@export var firing_arc_deg: float = 25.0 ## half-angle from the nose the beam may aim
@export var spin_up: float = 0.15 ## s before damage starts
## HP/s at mining_power 10 (stat units: 10 = x1.0).
@export var node_damage_per_s: float = 14.0
@export var uses_stat: StringName = &"mining_power"
@export var balance_prototype: bool = true


func damage_per_second(mining_power: float) -> float:
	return node_damage_per_s * mining_power / 10.0
