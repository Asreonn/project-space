extends Node
## Global signal hub, autoload "EventBus" (repo convention: autoloads live in
## scripts/core/). Gameplay emits, UI / VFX only listen. Signal list follows
## M1_draft 0.1: hull/fuel/energy/heat changed, slot selected, cargo
## added/rejected, died/respawn. Adding a signal is fine; renaming one or
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

# --- Death / respawn ---------------------------------------------------------

## Player ship destroyed.
signal player_died()
## Player ship respawned (M1: free respawn, fuel refilled).
signal player_respawned()

## cargo_rejected reasons (Docs/design/m1_mining_tools.md §5).
const REJECT_NO_STORAGE_FOR_PHASE := &"NO_STORAGE_FOR_PHASE"
const REJECT_PHASE_FULL := &"PHASE_FULL"
const REJECT_TOTAL_FULL := &"TOTAL_FULL" ## carry_capacity (total volume) reached.
