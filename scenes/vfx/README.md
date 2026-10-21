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
| `ore_pickup_visual.tscn` | Godot Engineer (pickup owner) | `Visual` child of `ore_pickup.tscn` | export `item_id` (else read from parent) |

Other scenes (`mining_beam`, `engine_nozzle`, `asteroid_break`, `ore_glow`,
`ore_collect_pop`) are used **inside** the director / trail; do not instance them directly.

## 1. VfxDirector (`vfx_director.tscn`)

Connects only to signals that exist on `/root/EventBus` (missing ones are skipped).
Contract = `scripts/core/event_bus.gd` on `eng/mvp-integration` / `gameplay/mvp-loop`:

| EventBus signal | Effect |
|---|---|
| `mining_beam_started(origin: Node3D, target: Node3D)` | beam on. `origin` = the head's `FX_MiningOrigin` (nose, −Z), followed every frame. `target` = asteroid or `null`; emitted again on retarget |
| `mining_beam_stopped()` | beam fades out (0.08 s) |
| `asteroid_damaged(asteroid, hit_position: Vector3, hp_ratio: float)` | exact contact point; heat glow (grows as hp drops) with a short flash when contact starts; sparks + embers while hits keep coming (0.2 s hold) |
| `asteroid_destroyed(position: Vector3, radius: float)` | pooled break: flash + 16 rock chunks + 10 ore streaks + 10 dust puffs. Radius 2.5 m = scale 1 (clamped 0.45–2.0). `&"S"/&"M"/&"L"` still accepted as fallback (1.2 / 2.5 / 4.0 m) |
| `ore_spawned(position: Vector3, item_id, amount)` | next frame the director finds the pickup node at that point (node with `item_id` + `velocity`) and, if it still has the placeholder box `Visual`, swaps in `ore_pickup_visual.tscn`; otherwise adds an `OreGlow` (cap 48) |
| `ore_collected(item_id, amount, position: Vector3)` | pooled collect pop (ring + 12 sparkles) |

**Beam end, no own length:** the beam is drawn exactly from `FX_MiningOrigin` to the end point
gameplay uses. Priority: the shooter's `beam_end` (the director finds the node with
`beam_origin`/`beam_end` near the origin, i.e. `MiningLaser`), then the last `hit_position`,
then the target's surface (`get_radius()`), else origin −Z × `fallback_range` (10 m). Range is gameplay's.
Older Vector3 forms (`mining_beam_updated`, 4-arg `asteroid_damaged`, `ore_spawned(node, …)`) still work.
Ore colours: `VfxDirector.ore_colors` (`ore_common_solid` orange, `crystal_blue_solid` cyan).
Direct calls (tests/cutscenes): `play_asteroid_break(pos, radius)`, `play_collect(pos, item_id)`, `add_ore_glow(node, item_id)`.

### Ore pickup visual (`ore_pickup_visual.tscn`)

Modeler's `ore_pickup_01.glb` / `crystal_pickup_01.glb` (chosen from `item_id`, crystal ids →
crystal model) at 1.25× + 1.5 m soft glow halo + 6 sparkles + 0.12 m bob in world up, so pickups
read at ortho 18–32. Best integration: make it the `Visual` child of `scenes/pickups/ore_pickup.tscn`
(OrePickup then skips its placeholder box) and set `VfxDirector.upgrade_placeholder_pickups = false`.
Until then the director swaps it in at runtime.

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

Nebula is kept below the ship/pickup contrast (brightness 0.68, saturation 0.78 in the palette).
One camera-following unshaded quad 120 m under the play plane (nebula fbm + 2 star layers,
parallax 5–20 % of camera motion, slow drift, twinkle) + one planet impostor quad (fresnel
atmosphere, optional ring). Works with perspective and orthographic cameras (ortho: sampling is scaled so stars and
clouds keep the same on-screen size as a 35° perspective view, `reference_fov`); camera `far`
must be > camera height + 120 m. Palettes: `assets/vfx/palettes/space_palette_starter.tres`
(purple–peach–orange, default) and `space_palette_crystal.tres`. New region = new palette `.tres`.

## 4. Budgets (max live particles, per instance)

| Effect | Particles | Other draws |
|---|---|---|
| Engine trail (per nozzle; starter = 2) | 28 (scaled by thrust via `amount_ratio`) | 1 flame quad |
| Mining beam | 24 sparks + 10 embers | 3 quads (beam, hot spot, muzzle) |
| Asteroid break (pool 4) | 1 + 16 + 10 + 10 = 37 | — |
| Ore glow / pickup visual (per pickup, cap 48) | 6 | 1 halo quad (+ model ≤ 90 tris) |
| Collect pop (pool 6) | 1 + 12 = 13 | — |
| Background | 0 | 2 quads |

Worst case seen in the look-dev overview (ortho 18): ~115–140 live particles, ≤ 90 draw calls.
Nothing spawns unbounded: one-shots come from a fixed round-robin pool (`VfxPool`), the
oldest instance is reused when all are busy.

## 5. Post / environment knobs

`environment_space.tres`: AgX tonemap, glow (screen blend, HDR threshold 1.05 → only HDR /
emissive > ~1 blooms), mild contrast 1.06 / saturation 1.1, SSR/SSAO/SSIL/SDFGI/fog off.
`post_fx.tscn`: vignette 0.32, chromatic aberration 0.0012 (edge only), grain 0.
Emissive values for other roles: keep albedo ≤ 1; use emission energy > 1 only for things
that should glow (nozzles, canopy lights, ore veins).
