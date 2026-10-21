extends Node
## Session state, autoload "GameState" (docs/briefs/mvp.md §4-§5). Holds
## credits, cargo and the player's ShipInstanceState, and owns the sell /
## upgrade API. UI only calls the public methods below and listens to EventBus;
## it keeps no game logic of its own. MVP: no save, everything resets per run.
##
## Public API (mvp.md §5):
##   sell_all_cargo() -> int
##   get_upgrade_cost(part) -> int          (-1 at max level)
##   try_upgrade(part) -> bool
##   get_part_level(part) -> int
##   get_stats() -> Dictionary[StringName, float]
##   preview_stats(part) -> Dictionary[StringName, float]
##
## No class_name on purpose: autoload name and class_name must not collide.

const PARTS: Array[StringName] = [&"head", &"body", &"wings", &"engine"]
const CREDITS := &"credits"

var hull: ShipHullDefinition
var ship_state: ShipInstanceState
var credits: int = 0
## Upgrades only while docked (D-011). Tests may switch this off.
var require_dock: bool = true
var docked: bool = false

var _stats: Dictionary[StringName, float] = {}
var _cargo: Dictionary[StringName, int] = {}
var _resources: Dictionary[StringName, ResourceDefinition] = {}


func _ready() -> void:
	EventBus.dock_entered.connect(_on_dock_entered)
	EventBus.dock_exited.connect(_on_dock_exited)


# --- Session -----------------------------------------------------------------

## Starts a fresh session for a hull. resources = every item cargo / market knows.
func start_session(p_hull: ShipHullDefinition, resources: Array[ResourceDefinition], starting_credits: int = 0, state: ShipInstanceState = null) -> void:
	hull = p_hull
	ship_state = state if state != null else ShipInstanceState.create_for(p_hull)
	_resources.clear()
	for def: ResourceDefinition in resources:
		if def != null:
			_resources[def.id] = def
	_cargo.clear()
	docked = false
	credits = maxi(starting_credits, 0)
	_recalculate_stats()
	EventBus.credits_changed.emit(credits)
	_emit_cargo_changed()


func get_resource(item_id: StringName) -> ResourceDefinition:
	return _resources.get(item_id, null)


# --- Stats -------------------------------------------------------------------

func get_stats() -> Dictionary[StringName, float]:
	return _stats.duplicate()


func get_stat(stat: StringName, fallback: float = 0.0) -> float:
	return _stats.get(stat, fallback)


## Resolved stats if part were one level higher (current stats at max level).
func preview_stats(part: StringName) -> Dictionary[StringName, float]:
	if hull == null or ship_state == null:
		return {}
	var level := get_part_level(part)
	if level >= _max_level(part):
		return get_stats()
	var preview := ship_state.duplicate(true) as ShipInstanceState
	preview.part_levels[part] = level + 1
	return ShipStatsResolver.resolve(hull, preview)


# --- Parts / upgrades --------------------------------------------------------

func get_part_level(part: StringName) -> int:
	if ship_state == null:
		return 1
	return ship_state.part_levels.get(part, 1)


## Credits needed for the next level of part; -1 when it is at max level.
func get_upgrade_cost(part: StringName) -> int:
	var next := _next_level(part)
	if next == null:
		return -1
	var total := 0
	for entry: CostEntry in next.cost:
		if entry.item_id == CREDITS:
			total += entry.amount
	return total


## &"" when part can be upgraded right now, else an EventBus.UPGRADE_* reason.
func get_upgrade_block_reason(part: StringName) -> StringName:
	if _next_level(part) == null:
		return EventBus.UPGRADE_MAX_LEVEL
	if require_dock and not docked:
		return EventBus.UPGRADE_NOT_DOCKED
	if credits < get_upgrade_cost(part):
		return EventBus.UPGRADE_NOT_ENOUGH_CREDITS
	return &""


## Pays the credits and raises part by one level (D-011: credits only, +1, no downgrade).
## Emits part_upgraded + ship_stats_changed, or upgrade_failed(reason, part).
func try_upgrade(part: StringName) -> bool:
	if not PARTS.has(part):
		push_warning("GameState.try_upgrade: unknown part '%s'" % part)
		return false
	var reason := get_upgrade_block_reason(part)
	if reason != &"":
		EventBus.upgrade_failed.emit(reason, part)
		return false
	_set_credits(credits - get_upgrade_cost(part))
	var level := get_part_level(part) + 1
	ship_state.part_levels[part] = level
	_recalculate_stats()
	EventBus.part_upgraded.emit(part, level)
	return true


# --- Credits -----------------------------------------------------------------

func add_credits(amount: int) -> void:
	if amount > 0:
		_set_credits(credits + amount)


# --- Cargo -------------------------------------------------------------------

func get_cargo() -> Dictionary[StringName, int]:
	return _cargo.duplicate()


func get_cargo_amount(item_id: StringName) -> int:
	return _cargo.get(item_id, 0)


func get_cargo_capacity() -> int:
	return floori(get_stat(ShipStat.CARRY_CAPACITY) + 0.0001)


## Used volume (u), rounded down.
func get_cargo_used() -> int:
	return floori(_used_volume() + 0.0001)


func get_cargo_units() -> int:
	var total := 0
	for id: StringName in _cargo:
		total += _cargo[id]
	return total


## t, for ShipController.cargo_mass.
func get_cargo_mass() -> float:
	var mass := 0.0
	for id: StringName in _cargo:
		var def := get_resource(id)
		mass += _cargo[id] * (def.mass_per_unit if def != null else 0.0)
	return mass


## Units of item_id that still fit (phase storage and total carry capacity).
func free_units_for(item_id: StringName) -> int:
	var def := get_resource(item_id)
	if def == null or def.volume_per_unit <= 0.0:
		return 0
	var phase := ResourceDefinition.phase_key(def.phase)
	var phase_free := get_stat(phase) - _phase_volume(phase)
	var total_free := get_stat(ShipStat.CARRY_CAPACITY) - _used_volume()
	return maxi(0, floori(minf(phase_free, total_free) / def.volume_per_unit + 0.0001))


func has_room_for(item_id: StringName) -> bool:
	return free_units_for(item_id) > 0


## Stores what fits (partial accept) and returns the accepted units.
## Emits cargo_added / cargo_rejected / cargo_changed.
func add_cargo(item_id: StringName, amount: int) -> int:
	if amount <= 0:
		return 0
	var accepted := mini(amount, free_units_for(item_id))
	if accepted > 0:
		_cargo[item_id] = get_cargo_amount(item_id) + accepted
		EventBus.cargo_added.emit(item_id, accepted)
	if accepted < amount:
		EventBus.cargo_rejected.emit(item_id, amount - accepted, _reject_reason(item_id))
	if accepted > 0:
		_emit_cargo_changed()
	return accepted


## Sells all cargo for ResourceDefinition.sell_price. Returns credits earned.
func sell_all_cargo() -> int:
	var units := 0
	var earned := 0
	for id: StringName in _cargo.keys():
		var def := get_resource(id)
		if def == null or def.sell_price <= 0:
			continue
		units += _cargo[id]
		earned += _cargo[id] * def.sell_price
		_cargo.erase(id)
	if units == 0:
		return 0
	_set_credits(credits + earned)
	_emit_cargo_changed()
	EventBus.cargo_sold.emit(units, earned)
	return earned


## Credits sell_all_cargo() would pay now.
func get_cargo_value() -> int:
	var total := 0
	for id: StringName in _cargo:
		var def := get_resource(id)
		if def != null:
			total += _cargo[id] * def.sell_price
	return total


# --- Internals ---------------------------------------------------------------

func _next_level(part: StringName) -> ShipPartLevel:
	if hull == null or not PARTS.has(part):
		return null
	var level := get_part_level(part)
	if level >= _max_level(part):
		return null
	var def := hull.get_part(PARTS.find(part) as ShipPartDefinition.Slot)
	return def.levels[level]


func _max_level(part: StringName) -> int:
	if hull == null or not PARTS.has(part):
		return 1
	var def := hull.get_part(PARTS.find(part) as ShipPartDefinition.Slot)
	if def == null:
		return 1
	return mini(def.levels.size(), ShipHullDefinition.MAX_PART_LEVEL)


func _recalculate_stats() -> void:
	_stats = ShipStatsResolver.resolve(hull, ship_state) if hull != null else {}
	EventBus.ship_stats_changed.emit(_stats.duplicate())
	_emit_cargo_changed()


func _set_credits(value: int) -> void:
	credits = maxi(value, 0)
	EventBus.credits_changed.emit(credits)


func _used_volume() -> float:
	var used := 0.0
	for id: StringName in _cargo:
		var def := get_resource(id)
		used += _cargo[id] * (def.volume_per_unit if def != null else 1.0)
	return used


func _phase_volume(phase: StringName) -> float:
	var used := 0.0
	for id: StringName in _cargo:
		var def := get_resource(id)
		if def == null or ResourceDefinition.phase_key(def.phase) == phase:
			used += _cargo[id] * (def.volume_per_unit if def != null else 1.0)
	return used


func _reject_reason(item_id: StringName) -> StringName:
	var def := get_resource(item_id)
	if def == null:
		return EventBus.REJECT_NO_STORAGE_FOR_PHASE
	var phase := ResourceDefinition.phase_key(def.phase)
	if get_stat(phase) <= 0.0:
		return EventBus.REJECT_NO_STORAGE_FOR_PHASE
	if _used_volume() + def.volume_per_unit > get_stat(ShipStat.CARRY_CAPACITY) + 0.0001:
		return EventBus.REJECT_TOTAL_FULL
	return EventBus.REJECT_PHASE_FULL


func _emit_cargo_changed() -> void:
	EventBus.cargo_changed.emit(get_cargo_used(), get_cargo_capacity())


func _on_dock_entered() -> void:
	docked = true


func _on_dock_exited() -> void:
	docked = false
