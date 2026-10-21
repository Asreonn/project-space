# station_01 (MVP batch 3)

Generator: `stations.py`, headless: `blender -b -P stations.py`. It writes `assets/models/stations/station_01.glb`, `station_01_collision.glb` and `stations.blend`.
Renders: `blender -b -P ../_shared/env_renders.py -- stations`.

- Size: 13.6 x 14.2 m footprint (outer ring ~13.7 m diameter; the entrance apron sticks out to 7.3 m on -Z), 3.95 m tall. 1354 tris, 2 surfaces.
- Materials: `M_ps_palette` / `M_ps_glow`. Same colours as the starter ship: white, grey, orange, metal, cyan glass and lights.
- Play plane is Y = 0. Only the hub drum and tower rise above it. The deck (top Y -0.5), ring (top Y -0.25), pad and apron are all below it, so the ship flies over them into the dock.
- Dock entrance faces Godot -Z (screen-up at the default camera). It is a 64 deg gap in the outer ring with lit gate posts and two orange chevrons pointing inward. Rotate the node to aim it.
- Dock zone: blue-grey deck with a dashed cyan rim at r 5.0 m. This matches the brief's dock radius of ~5 m.

Empties (children of the mesh, Godot coordinates):

| node | position | meaning |
|---|---|---|
| `Dock_Center` | (0, 0, 0) | dock area centre; use it for the ~5 m dock Area3D |
| `Dock_Pad_0` | (0, 0, -3) | parking spot; -Z = docked ship nose, pointing out of the entrance |
| `Dock_Entrance` | (0, 0, -6.5) | entrance mouth (approach guide / HUD marker) |
| `Beacon_Light` | (0, 2.45, 0) | top lamp (OmniLight / blink) |

Collision: `station_01_collision.glb` is one convex hull of the hub and cargo shoulder, 94 tris, r 1.84 m, Y -1.3..1.7. The deck, ring and pad have no collision because they sit below the play plane.
