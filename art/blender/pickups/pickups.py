"""Project Space - ore pickups (floating loot dropped by mining).

Headless:  blender -b -P pickups.py
Output:    <ROOT>/assets/models/pickups/<name>.glb + <name>_collision.glb, pickups.blend
  ore_pickup_01     - stubby orange ore crystals on a dark rock chip (resource ore_common_solid; mild glow)
  crystal_pickup_01 - three tall glowing blue crystal points        (resource crystal_blue_solid; strong glow)
Names per docs/briefs/mvp.md §5. Colour = ore type, matching the asteroid seams (orange) / veins (blue).
Pivot = visual centre (so a spin/bob tween looks right), 1u = 1 m, ~0.55-0.7 m across
(readable next to the 1.84 m ship; collect radius 1.2 m lives in gameplay, not in the mesh).
"""
import bpy, bmesh, sys, os, math, random
from mathutils import Vector, Matrix
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,os.path.join(HERE,"..","_shared"))
import ps_common as C
ROOT=os.environ.get("PS_ROOT") or os.path.abspath(os.path.join(HERE,"..","..",".."))
OUT=f"{ROOT}/assets/models/pickups"
PICKUP_SCALE=1.6   # iteration 2: 0.35 m read too small at the ~30 m gameplay camera -> ~0.6 m

def crystal(bm, cells, base, direc, r, h, tip, side_cell, tip_cell, sides=6, twist=0.0):
    d=Vector(direc).normalized(); q=d.to_track_quat("Z","Y")
    def P(x,y,z): return Vector(base)+q@Vector((x,y,z))
    bot=[bm.verts.new(P(r*0.8*math.cos(2*math.pi*i/sides+twist),r*0.8*math.sin(2*math.pi*i/sides+twist),0)) for i in range(sides)]
    top=[bm.verts.new(P(r*math.cos(2*math.pi*i/sides+twist),r*math.sin(2*math.pi*i/sides+twist),h)) for i in range(sides)]
    apex=bm.verts.new(P(0,0,h+tip))
    for i in range(sides):
        j=(i+1)%sides
        bm.faces.new((bot[i],bot[j],top[j],top[i])); cells.append(side_cell)
        bm.faces.new((top[i],top[j],apex)); cells.append(tip_cell)
    bm.faces.new(list(reversed(bot))); cells.append(side_cell)

def nugget(bm, cells, R, seed, cell_choices):
    rnd=random.Random(seed); vs=[]
    for _ in range(10):
        d=Vector((rnd.gauss(0,1),rnd.gauss(0,1),rnd.gauss(0,1))).normalized()
        vs.append(Vector((d.x*1.15,d.y,d.z*0.8))*R*rnd.uniform(0.85,1.05))
    tb=bmesh.new(); [tb.verts.new(v) for v in vs]
    r=bmesh.ops.convex_hull(tb,input=tb.verts)
    bmesh.ops.delete(tb,geom=[g for g in set(r["geom_interior"]+r["geom_unused"]) if isinstance(g,bmesh.types.BMVert)],context="VERTS")
    bmesh.ops.triangulate(tb,faces=tb.faces)
    m=bpy.data.meshes.new("t"); tb.to_mesh(m); tb.free(); bm.from_mesh(m); bpy.data.meshes.remove(m)
    while len(cells)<len(bm.faces): cells.append(rnd.choice(cell_choices))

def centre(bm):
    xs=[v.co for v in bm.verts]; mn=Vector((min(v.x for v in xs),min(v.y for v in xs),min(v.z for v in xs))); mx=Vector((max(v.x for v in xs),max(v.y for v in xs),max(v.z for v in xs)))
    c=(mn+mx)/2
    for v in bm.verts: v.co-=c

def build(name, mats):
    bm=bmesh.new(); cells=[]
    if name=="ore_pickup_01":     # ore_common_solid: stubby orange ore crystals on a small rock chip
        nugget(bm,cells,0.10,7,[C.ROCK_D,C.ROCK_M])
        crystal(bm,cells,(0.0,0.0,0.02),(0.1,0.05,1),0.085,0.09,0.07,C.ORANGE,C.ORE,sides=5)
        crystal(bm,cells,(0.07,0.03,0.0),(0.8,0.35,0.55),0.065,0.06,0.06,C.ORANGE,C.ORE,sides=5,twist=0.4)
        crystal(bm,cells,(-0.06,-0.05,0.0),(-0.7,-0.5,0.5),0.06,0.05,0.05,C.ORANGE,C.ORE,sides=5,twist=0.9)
        crystal(bm,cells,(-0.03,0.07,0.0),(-0.3,0.85,0.45),0.05,0.04,0.05,C.ORANGE,C.ORE,sides=5,twist=0.2)
    else:                         # crystal_blue_solid: tall slender blue crystal points
        nugget(bm,cells,0.10,9,[C.ROCK_D,C.ROCK_P])
        crystal(bm,cells,(0,0,0.0),(0.05,0.0,1),0.07,0.22,0.11,C.GLASS,C.LIGHT,twist=0.2)
        crystal(bm,cells,(0.05,0.03,-0.01),(0.75,0.3,0.6),0.05,0.14,0.08,C.GLASS,C.LIGHT,twist=0.5)
        crystal(bm,cells,(-0.05,-0.02,-0.01),(-0.65,-0.45,0.55),0.05,0.12,0.07,C.GLASS,C.LIGHT,twist=0.9)
    centre(bm)
    for v in bm.verts: v.co*=PICKUP_SCALE
    bm.normal_update()
    ob=C.mesh_from_bm(bm,name,f"{name}_mesh",mats,cells,soft=0.2); bm.free(); return ob

def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mats=C.make_materials(os.path.join(HERE,"..","_shared")); x=0
    for name in ("ore_pickup_01","crystal_pickup_01"):
        ob=build(name,mats)
        print(f"TRIS {ob.name}: {C.tri_count(ob)} dims={tuple(round(d,2) for d in ob.dimensions)}")
        C.export_glb([ob],f"{OUT}/{name}.glb")
        co=C.convex_collision([ob],f"{name}_collision",max_angle=12); print(f"COLLISION {name}: {len(co.data.polygons)} tris")
        C.export_glb([co],f"{OUT}/{name}_collision.glb",materials=False); bpy.data.objects.remove(co)
        ob.location.x=x; x+=1.0
    bpy.ops.file.pack_all(); bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE,"pickups.blend"))
main()
