class_name ShipStat
## Ship stat keys (ship_data_model.md §3, GAME_PLAN §4.2).
## Renaming any key is a contract change (Designer + Godot Eng. approval).

const DAMAGE := &"damage"
const MINING_POWER := &"mining_power"
const FLYING_SPEED := &"flying_speed"
const MANEUVER_SPEED := &"maneuver_speed"
const CARRY_CAPACITY := &"carry_capacity"
const STORAGE_SOLID := &"storage_solid"
const STORAGE_LIQUID := &"storage_liquid"
const STORAGE_GAS := &"storage_gas"
const FUEL_CAPACITY := &"fuel_capacity"
const FUEL_RATE := &"fuel_rate"
const ENERGY_CAPACITY := &"energy_capacity"
const ELECTRONIC_CAPACITY := &"electronic_capacity"
const MODULE_CAPACITY := &"module_capacity"
const RADAR_RANGE := &"radar_range"
const HULL := &"hull"
const HEAT_CAPACITY := &"heat_capacity"
const MASS := &"mass"
const SHIELD := &"shield"

const ALL: Array[StringName] = [
	DAMAGE, MINING_POWER, FLYING_SPEED, MANEUVER_SPEED, CARRY_CAPACITY,
	STORAGE_SOLID, STORAGE_LIQUID, STORAGE_GAS, FUEL_CAPACITY, FUEL_RATE,
	ENERGY_CAPACITY, ELECTRONIC_CAPACITY, MODULE_CAPACITY, RADAR_RANGE,
	HULL, HEAT_CAPACITY, MASS, SHIELD,
]


static func is_valid(stat: StringName) -> bool:
	return ALL.has(stat)
