extends Node
## Global signal hub, autoload "EventBus" (repo convention: autoloads live in
## scripts/core/). Gameplay emits, UI / VFX only listen. Signal list follows
## M1_draft 0.1 (hull/fuel/energy/heat changed, slot selected, cargo
## added/rejected, died/respawn) plus the MVP list from the PS Game Designer
## (mining beam, asteroid, ore, cargo/credits, dock, upgrade). Adding a signal is fine; renaming one or
## changing its arguments is a contract change (Godot Engineer + Game Designer).
##
## No class_name on purpose: autoload name and class_name must not collide.

# --- Ship vitals (values are absolute, not deltas) ---------------------------

## Player hull (HP) changed.
signal hull_changed(current: float, maximum: float)
## Player fuel changed.
signal fuel_changed(current: float, maximum: float)
## Active energy pool changed (not electronic/passive capacity).
signal energy_changed(current: float, maximum: float)
## Shared heat pool changed. Overheat lock is current >= maximum.
signal heat_changed(current: float, maximum: float)

# --- Active slots ------------------------------------------------------------

## Player selected an active slot. slot_number is 1..4, matching the slot_1..slot_4
## input actions (M1: 1 Laser; 2-4 locked or empty).
signal slot_selected(slot_number: int)

# --- Cargo -------------------------------------------------------------------

## Cargo accepted. item_id is a ResourceDefinition id.
signal cargo_added(item_id: StringName, amount: int)
## Cargo refused. reason is one of the REJECT_* constants below.
signal cargo_rejected(item_id: StringName, amount: int, reason: StringName)

## Cargo contents changed (add, sell, clear). used / capacity in volume units (u).
signal cargo_changed(used: float, capacity: float)

# --- Mining (MVP) ------------------------------------------------------------

## Mining beam switched on. origin = FX_MiningOrigin world position,
## target = beam end point (hit point or max range).
signal mining_beam_started(origin: Vector3, target: Vector3)
## Beam end points moved this physics frame while the beam is on (VFX follow hook).
signal mining_beam_updated(origin: Vector3, target: Vector3)
## Mining beam switched off.
signal mining_beam_stopped()
## An asteroid lost HP. asteroid is the Asteroid node; hit_point in world space.
signal asteroid_damaged(asteroid: Node3D, current_hp: float, max_hp: float, hit_point: Vector3)
## An asteroid broke. size = its radius in metres (VFX scales the break FX).
signal asteroid_destroyed(position: Vector3, size: float)
## An ore pickup was spawned into the world.
signal ore_spawned(pickup: Node3D, item_id: StringName, amount: int)
## An ore pickup reached the ship and was stored. type = ResourceDefinition id.
signal ore_collected(type: StringName, amount: int)

# --- Economy / station (MVP) -------------------------------------------------

## Credit balance changed. delta is signed (+ sell, - upgrade).
signal credits_changed(credits: int, delta: int)
## Cargo sold at the station.
signal cargo_sold(units: int, credits_earned: int)
## Player ship entered the station dock area (interact prompt can show).
signal dock_entered()
## Player ship left the dock area. The dock panel closes too.
signal dock_exited()
## Dock / upgrade panel opened (true) or closed (false). Gameplay emits on interact (E).
signal dock_panel_toggled(open: bool)
## A ship part reached a new level (model already swapped, stats re-resolved).
## part = slot key: head, body, wings, engine.
signal part_upgraded(part: StringName, level: int)
## An upgrade request was refused. reason is one of the UPGRADE_* constants.
signal upgrade_failed(reason: StringName)

# --- Death / respawn ---------------------------------------------------------

## Player ship destroyed.
signal player_died()
## Player ship respawned (M1: free respawn, fuel refilled).
signal player_respawned()

## cargo_rejected reasons (Docs/design/m1_mining_tools.md §5).
const REJECT_NO_STORAGE_FOR_PHASE := &"NO_STORAGE_FOR_PHASE"
const REJECT_PHASE_FULL := &"PHASE_FULL"
const REJECT_CARRY_FULL := &"CARRY_FULL" ## carry_capacity (total volume) reached.

## upgrade_failed reasons.
const UPGRADE_NOT_DOCKED := &"NOT_DOCKED"
const UPGRADE_MAX_LEVEL := &"MAX_LEVEL"
const UPGRADE_NOT_ENOUGH_CREDITS := &"NOT_ENOUGH_CREDITS"
const UPGRADE_NOT_ENOUGH_ITEMS := &"NOT_ENOUGH_ITEMS"
const UPGRADE_NO_LEVEL_DATA := &"NO_LEVEL_DATA"
