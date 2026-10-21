extends Node
## Global signal hub, autoload "EventBus" (D-012; autoloads live in
## scripts/core/ per AGENTS.md §2). Publishers emit, listeners only connect.
## Signal list = M1_draft 0.1 + docs/briefs/mvp.md §6 (exact names and args).
## Adding a signal is fine; renaming one or changing its arguments is a
## contract change (Godot Engineer + Game Designer).
## Values are absolute (not deltas); positions are world space.
##
## No class_name on purpose: autoload name and class_name must not collide.

# --- Ship vitals (M1; not emitted in the MVP) --------------------------------

## Player hull (HP) changed.
signal hull_changed(current: float, maximum: float)
## Player fuel changed.
signal fuel_changed(current: float, maximum: float)
## Active energy pool changed (not electronic/passive capacity).
signal energy_changed(current: float, maximum: float)
## Shared heat pool changed. Overheat lock is current >= maximum.
signal heat_changed(current: float, maximum: float)

# --- Active slots (M1; not emitted in the MVP) -------------------------------

## Player selected an active slot. slot_number is 1..4 (slot_1..slot_4 actions).
signal slot_selected(slot_number: int)

# --- Mining (MVP) ------------------------------------------------------------

## Beam switched on. origin = the head's FX_MiningOrigin node, target = the asteroid.
## Publisher: Gameplay (mining beam). Listener: VFX.
signal mining_beam_started(origin: Node3D, target: Node3D)
## Beam switched off. Publisher: Gameplay. Listener: VFX.
signal mining_beam_stopped()
## Every physics frame while the beam is on (added for VFX: the beam end moves
## even without a hit). origin = FX_MiningOrigin node, end = hit point or max range.
## Publisher: Gameplay (mining beam). Listener: VFX.
signal mining_beam_updated(origin: Node3D, end: Vector3)
## Emitted every physics frame the beam touches an asteroid. hp_ratio = hp / max_hp.
## Publisher: Engineer (asteroid.gd). Listener: VFX.
signal asteroid_damaged(asteroid: Node3D, hit_position: Vector3, hp_ratio: float)
## Asteroid broke. radius = its XZ radius in metres (VFX scales the break by it).
## Publisher: Engineer (asteroid.gd). Listeners: VFX, Engineer (respawn), Gameplay (cut beam).
signal asteroid_destroyed(position: Vector3, radius: float)
## Ore pickup spawned. Publisher: Engineer (pickup system). Listener: VFX.
signal ore_spawned(position: Vector3, item_id: StringName, amount: int)
## Ore pickup accepted into cargo. Publisher: Engineer (pickup system). Listeners: VFX, UI.
signal ore_collected(item_id: StringName, amount: int, position: Vector3)

# --- Cargo / economy ---------------------------------------------------------

## Cargo accepted. item_id is a ResourceDefinition id. Publisher: GameState.
signal cargo_added(item_id: StringName, amount: int)
## Cargo refused. reason is one of the REJECT_* constants. Publisher: GameState.
signal cargo_rejected(item_id: StringName, amount: int, reason: StringName)
## Cargo fill changed (volume units). Publisher: GameState. Listeners: UI, Gameplay (mass).
signal cargo_changed(used: int, capacity: int)
## Cargo sold at the station. Publisher: GameState.
signal cargo_sold(units: int, credits_earned: int)
## Credit balance changed. Publisher: GameState.
signal credits_changed(credits: int)

# --- Station (MVP) -----------------------------------------------------------

## Player ship entered the dock area. Publisher: Engineer (station_dock.gd).
signal dock_entered()
## Player ship left the dock area. Publisher: Engineer (station_dock.gd).
signal dock_exited()
## Station panel opened / closed (E while docked). Publisher: UI (station panel).
## Listeners: Gameplay (stops ship input), Engineer.
signal station_panel_toggled(is_open: bool)

# --- Upgrades / stats (MVP) --------------------------------------------------

## Part reached a new level. part is &"head", &"body", &"wings" or &"engine".
## Publisher: GameState.try_upgrade. Listeners: ShipAssembler (model swap), UI, VFX.
signal part_upgraded(part: StringName, level: int)
## Upgrade refused. reason is one of the UPGRADE_* constants. Publisher: GameState.
signal upgrade_failed(reason: StringName, part: StringName)
## Resolved ship stats (at session start and after every upgrade). Publisher: GameState.
## Listeners: Gameplay (flight, beam), UI (preview).
signal ship_stats_changed(stats: Dictionary)

# --- Death / respawn (M1; not emitted in the MVP) ----------------------------

## Player ship destroyed.
signal player_died()
## Player ship respawned (M1: free respawn, fuel refilled).
signal player_respawned()

## cargo_rejected reasons (Docs/design/m1_mining_tools.md §5).
const REJECT_NO_STORAGE_FOR_PHASE := &"NO_STORAGE_FOR_PHASE"
const REJECT_PHASE_FULL := &"PHASE_FULL"
const REJECT_TOTAL_FULL := &"TOTAL_FULL" ## carry_capacity reached (docs: CARRY_FULL / CARGO_FULL).

## upgrade_failed reasons (mvp.md §6).
const UPGRADE_NOT_ENOUGH_CREDITS := &"NOT_ENOUGH_CREDITS"
const UPGRADE_MAX_LEVEL := &"MAX_LEVEL"
const UPGRADE_NOT_DOCKED := &"NOT_DOCKED"
