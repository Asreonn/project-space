# scenes/vfx — integration guide (MVP)

**Owner:** VFX Engineer. Everything here is self-contained: owners only
**instance** these scenes, no other code changes are needed except the
`set_thrust` call. Contract: `docs/briefs/mvp.md` §5–6 + `scripts/core/event_bus.gd`.
Scale: 1u = 1 m, play plane XZ (Y = 0), ship nose −Z, starter ship 1.84 m.

| Scene | Who instances it | Where | API |
|---|---|---|---|
| `vfx_director.tscn` | Godot Engineer | once per sector (`mvp_sector.tscn`), anywhere | none — listens to EventBus |
| `engine_trail.tscn` | Gameplay | child of the player ship (e.g. under `Visual`) | `set_thrust(amount: float, boosting: bool)` |
| `space_background.tscn` | Godot Engineer | once per sector, anywhere | exports: `palette`, `low_quality`, `planet_*`, `depth` |
| `environment_space.tres` | Godot Engineer | `WorldEnvironment.environment` of the sector | — |
| `post_fx.tscn` | Godot Engineer | once per sector (CanvasLayer, layer −1, under the HUD) | hide the node to disable |
| `vfx_lookdev.tscn` | — | look-dev only, not for the game | keys 1–6 switch shots |

Other scenes (`mining_beam`, `engine_nozzle`, `asteroid_break`, `ore_glow`,
`ore_collect_pop`) are used **inside** the director / trail; do not instance them directly.

## 1. VfxDirector (`vfx_director.tscn`)

Connects only to signals that exist on `/root/EventBus` (missing ones are skipped):

| EventBus signal | Effect |
|---|---|
| `mining_beam_started(origin: Vector3, target: Vector3)` | beam on (0.08 s fade-in) |
| `mining_beam_updated(origin, target)` | beam follows (emit every physics frame while firing) |
| `mining_beam_stopped()` | beam fades out |
| `asteroid_damaged(asteroid, current_hp, max_hp, hit_point)` | hot spot + sparks + embers on while hits keep coming (0.2 s hold); without it the beam shows "no hit" (no sparks) |
| `asteroid_destroyed(position: Vector3, size)` | pooled break: flash + 16 rock chunks + 10 ore streaks + 10 dust puffs. `size` = radius in m (float, 2.5 m = scale 1, clamped 0.45–2.0) **or** `&"S"/&"M"/&"L"` (1.2 / 2.5 / 4.0 m) |
| `ore_spawned(pickup: Node3D, item_id, amount)` | adds an `OreGlow` child to the pickup (freed with it; cap 48) |
| `ore_collected(item_id, amount[, position: Vector3])` | pooled collect pop (ring + 12 sparkles) at `position`; if the signal has no position (current bus), the glow nearest to the `pickup_collector` group node is used |

Signal args are typed `Variant` on the VFX side, so `Node3D` origin/target (mvp.md §6 wording) work too.
Ore colours: `VfxDirector.ore_colors` (item id → Color), default orange.
Direct calls (tests/cutscenes): `play_asteroid_break(pos, size)`, `play_collect(pos, item_id)`, `add_ore_glow(node, item_id)`.

## 2. Engine trail (`engine_trail.tscn`)

```gdscript
# player_ship.tscn: add engine_trail.tscn as a child named EngineTrail, then every frame:
$EngineTrail.set_thrust(clampf(velocity.length() / max_speed, 0.0, 1.0), boosting)
```
It finds every `FX_EngineTrail_<n>` under the ship (nearest ancestor that has them, or the
`ship_root` export), puts one flame + puff trail on each (flame along the empty's +Z), and
re-attaches when the `ShipAssembler` emits `assembled` / `part_level_changed` or EventBus
`part_upgraded(&"engine" | &"body", …)`. `size_scale` export for bigger ships.

## 3. Background (`space_background.tscn`)

One camera-following unshaded quad 120 m under the play plane (nebula fbm + 2 star layers,
parallax 5–20 % of camera motion, slow drift, twinkle) + one planet impostor quad (fresnel
atmosphere, optional ring). Works with perspective and orthographic cameras; camera `far`
must be > camera height + 120 m. Palettes: `assets/vfx/palettes/space_palette_starter.tres`
(purple–peach–orange, default) and `space_palette_crystal.tres`. New region = new palette `.tres`.

## 4. Budgets (max live particles, per instance)

| Effect | Particles | Other draws |
|---|---|---|
| Engine trail (per nozzle; starter = 2) | 28 (scaled by thrust via `amount_ratio`) | 1 flame quad |
| Mining beam | 24 sparks + 10 embers | 3 quads (beam, hot spot, muzzle) |
| Asteroid break (pool 4) | 1 + 16 + 10 + 10 = 37 | — |
| Ore glow (per pickup, cap 48) | 6 | 1 halo quad |
| Collect pop (pool 6) | 1 + 12 = 13 | — |
| Background | 0 | 2 quads |

Worst case seen in the look-dev overview: ~140 live particles, 65 draw calls.
Nothing spawns unbounded: one-shots come from a fixed round-robin pool (`VfxPool`), the
oldest instance is reused when all are busy.

## 5. Post / environment knobs

`environment_space.tres`: AgX tonemap, glow (screen blend, HDR threshold 1.05 → only HDR /
emissive > ~1 blooms), mild contrast 1.06 / saturation 1.1, SSR/SSAO/SSIL/SDFGI/fog off.
`post_fx.tscn`: vignette 0.32, chromatic aberration 0.0012 (edge only), grain 0.
Emissive values for other roles: keep albedo ≤ 1; use emission energy > 1 only for things
that should glow (nozzles, canopy lights, ore veins).
