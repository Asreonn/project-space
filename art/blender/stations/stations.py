"""Project Space - station_01 (MVP sell / upgrade station).

Headless:  blender -b -P stations.py
Output:    <ROOT>/assets/models/stations/station_01.glb + station_01_collision.glb, stations.blend
Brief (docs/briefs/mvp.md): 12-16 m diameter, dock area radius ~5 m, Dock_Center empty at the centre,
same palette as the starter ship (cells 0-10 of the shared palette), dock entrance readable top-down.
Layout (Blender Z up -> Godot Y up; Z=0 = play plane; Blender +Y = Godot -Z = screen-up):
  hub        chamfered 12-sided drum r 1.9 m, Z -1.3..+1.2, tower to Z 2.6 with a glowing beacon (only collision)
  deck       dark dock deck r 1.8..5.3 m, top Z -0.5, cyan dashed rim at r 5.0 = dock radius
  ring       structural ring r 6.5 m (outer diameter ~13.7 m), top Z -0.25, with a 64 deg ENTRANCE GAP on +Y
  entrance   apron with orange inward chevrons + two lit gate posts
  pad        landing pad at (0, 3.0), between hub and entrance
Everything except hub + tower sits below the play plane, so the ship flies over it into the dock.
Empties (children of the root mesh):
  Dock_Center  (0,0,0)          dock area centre (gameplay dock radius ~5 m around it)
  Dock_Pad_0   Blender (0,3,0) = Godot (0,0,-3)   parking spot, docked nose points out of the entrance (Godot -Z)
  Dock_Entrance Blender (0,6.5,0) = Godot (0,0,-6.5)  entrance mouth, for approach guidance / HUD
  Beacon_Light  top lamp (OmniLight / blink)
"""
import bpy, bmesh, sys, os, math
from mathutils import Vector, Matrix
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,os.path.join(HERE,"..","_shared"))
import ps_common as C
ROOT=os.environ.get("PS_ROOT") or os.path.abspath(os.path.join(HERE,"..","..",".."))
OUT=f"{ROOT}/assets/models/stations"
NAME="station_01"

def lathe(bm, cells, prof, band_cells, segs, centre=(0,0,0), rot=0.0, seg_cell=None):
    """prof: [(r,z)] bottom->top; band_cells[i] for band prof[i]->prof[i+1]; r==0 -> pole vertex."""
    cx,cy,cz=centre; rings=[]
    for r,z in prof:
        if r<1e-6: rings.append([bm.verts.new((cx,cy,cz+z))]*segs)
        else: rings.append([bm.verts.new((cx+r*math.cos(rot+2*math.pi*i/segs),cy+r*math.sin(rot+2*math.pi*i/segs),cz+z)) for i in range(segs)])
    for b in range(len(prof)-1):
        A,B=rings[b],rings[b+1]
        for i in range(segs):
            j=(i+1)%segs; vs=[A[i],A[j],B[j],B[i]]; u=[]
            for v in vs:
                if v not in u: u.append(v)
            if len(u)>=3: bm.faces.new(u); cells.append(seg_cell(b,i) if seg_cell else band_cells[b])

def torus(bm, cells, R, r, segs, sides, z, cellf):
    vs=[[bm.verts.new(((R+r*math.cos(2*math.pi*k/sides))*math.cos(2*math.pi*i/segs),(R+r*math.cos(2*math.pi*k/sides))*math.sin(2*math.pi*i/segs),z+r*math.sin(2*math.pi*k/sides))) for k in range(sides)] for i in range(segs)]
    for i in range(segs):
        for k in range(sides):
            a,b=vs[i],vs[(i+1)%segs]; bm.faces.new((a[k],b[k],b[(k+1)%sides],a[(k+1)%sides])); cells.append(cellf(i,k))

def box(bm, cells, c, size, cell, rotz=0.0):
    m=Matrix.Translation(c)@Matrix.Rotation(rotz,4,"Z")@Matrix.Diagonal((*size,1))
    r=bmesh.ops.create_cube(bm,size=1.0,matrix=m); n=len({f for v in r["verts"] for f in v.link_faces}); cells+= [cell]*n

def arc_tube(bm, cells, R, r, a0, a1, segs, sides, z, cellf):
    """partial torus from angle a0 to a1 with capped ends."""
    vs=[]
    for i in range(segs+1):
        t=a0+(a1-a0)*i/segs
        vs.append([bm.verts.new(((R+r*math.cos(2*math.pi*k/sides))*math.cos(t),(R+r*math.cos(2*math.pi*k/sides))*math.sin(t),z+r*math.sin(2*math.pi*k/sides))) for k in range(sides)])
    for i in range(segs):
        for k in range(sides):
            a,b=vs[i],vs[i+1]; bm.faces.new((a[k],b[k],b[(k+1)%sides],a[(k+1)%sides])); cells.append(cellf(i,k))
    bm.faces.new(list(reversed(vs[0]))); cells.append(C.ORANGE); bm.faces.new(vs[-1]); cells.append(C.ORANGE)

def chevron(bm, cells, y, z, w, cell):
    """flat V pointing to -Y (into the station)."""
    for sx in (1,-1):
        box(bm,cells,Vector((sx*w*0.35,y+w*0.25,z)),(w*0.8,0.22,0.06),cell,rotz=sx*math.radians(35))

def build(mats):
    bm=bmesh.new(); cells=[]
    W,G,O,D,M,GL,LI,SP=C.WHITE,C.GREY,C.ORANGE,C.DARK,C.METAL,C.GLASS,C.LIGHT,C.SPINE
    hub=[(0,-1.3),(1.1,-1.3),(1.6,-0.9),(1.9,-0.4),(1.9,-0.1),(1.65,0.3),(1.2,0.6),(1.2,0.8),(0.8,1.05),(0.4,1.2),(0,1.2)]
    hb=[M,G,W,O,W,G,GL,W,G,G]
    lathe(bm,cells,hub,hb,12,rot=math.pi/12,seg_cell=lambda b,i: (O if i%3==0 else W) if b==2 else (D if (b==6 and i%2) else hb[b]))
    mast=[(0.4,1.19),(0.2,1.3),(0.13,2.25),(0.24,2.33),(0.24,2.55),(0.1,2.65),(0,2.65)]
    lathe(bm,cells,mast,[G,M,G,LI,LI,G],6)
    box(bm,cells,Vector((0,0,1.9)),(1.3,0.1,0.1),M)
    box(bm,cells,Vector((0.7,0,1.9)),(0.1,0.42,0.42),W); box(bm,cells,Vector((-0.7,0,1.9)),(0.1,0.42,0.42),W)
    for k in range(5):   # cargo containers on the shoulder (sell-point read), none on the entrance side
        ang=math.radians(150+k*60) if k<4 else math.radians(30)
        box(bm,cells,Vector((1.42*math.cos(ang),1.42*math.sin(ang),0.5)),(0.46,0.32,0.28),O if k%2 else W,rotz=ang+math.pi/2)
    # dock deck (annulus) with a light rim
    deck=[(1.8,-0.78),(5.2,-0.78),(5.35,-0.62),(5.2,-0.5),(1.8,-0.5)]
    lathe(bm,cells,deck,[M,G,W,SP],24)   # iteration 2: blue-grey deck reads as the dock zone (dark read as a hole)
    for k in range(20):  # cyan dashes on the deck at r 5.0 = dock radius
        ang=2*math.pi*(k+0.5)/20
        box(bm,cells,Vector((4.95*math.cos(ang),4.95*math.sin(ang),-0.47)),(0.12,0.75,0.04),GL,rotz=ang)
    # structural ring with entrance gap centred on +Y
    gap=math.radians(32); a0=math.pi/2+gap; a1=math.pi/2-gap+2*math.pi
    arc_tube(bm,cells,6.5,0.34,a0,a1,22,6,-0.6,lambda i,k: (O if i%5==2 else (D if k in (3,4) else W)))
    for t in (a0,a1):    # lit gate posts at both sides of the entrance
        p=Vector((6.5*math.cos(t),6.5*math.sin(t),0))
        box(bm,cells,p+Vector((0,0,-0.55)),(0.55,0.55,0.75),O,rotz=t)
        box(bm,cells,p+Vector((0,0,-0.12)),(0.36,0.36,0.14),LI,rotz=t)
    for k in range(3):   # spokes deck -> ring, away from the entrance
        ang=math.radians(210+k*60); c=Vector((math.cos(ang),math.sin(ang),0))
        box(bm,cells,c*5.9+Vector((0,0,-0.62)),(1.3,0.42,0.26),G,rotz=ang)
    # entrance apron + inward chevrons
    box(bm,cells,Vector((0,6.2,-0.66)),(2.6,1.9,0.18),M)
    chevron(bm,cells,6.55,-0.55,1.4,O); chevron(bm,cells,5.85,-0.55,1.1,O)
    # landing pad between hub and entrance
    pad=[(0,-0.62),(1.15,-0.62),(1.25,-0.48),(1.15,-0.36),(0.85,-0.36),(0.65,-0.36),(0,-0.36)]
    lathe(bm,cells,pad,[M,G,W,W,O,W],8,centre=(0,3.0,0),rot=math.pi/8)
    for k in range(4):
        ang=math.pi/4+k*math.pi/2; box(bm,cells,Vector((1.0*math.cos(ang),3.0+1.0*math.sin(ang),-0.33)),(0.12,0.12,0.06),GL)
    bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=1e-4); bm.normal_update()
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
    ob=C.mesh_from_bm(bm,NAME,f"{NAME}_mesh",mats,cells,soft=0.25); bm.free()
    C.empty("Dock_Center",(0,0,0),ob,None,1.0)
    C.empty("Dock_Pad_0",(0,3.0,0),ob,None,0.6)
    C.empty("Dock_Entrance",(0,6.5,0),ob,None,0.6)
    C.empty("Beacon_Light",(0,0,2.45),ob,None,0.3)
    return ob

def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mats=C.make_materials(os.path.join(HERE,"..","_shared"))
    ob=build(mats)
    print(f"TRIS {NAME}: {C.tri_count(ob)} dims={tuple(round(d,2) for d in ob.dimensions)} children={[c.name for c in ob.children]}")
    C.export_glb(C.with_children(ob),f"{OUT}/{NAME}.glb")
    # collision: hub drum + cargo shoulder only (deck / ring / pad are below the play plane)
    tmp=bpy.data.objects.new("tmp",None)
    hubpts=[Vector((r*math.cos(math.pi/12+2*math.pi*i/12),r*math.sin(math.pi/12+2*math.pi*i/12),z)) for r,z in [(1.1,-1.3),(1.9,-0.4),(1.9,-0.1),(1.65,0.6),(1.2,0.8),(0.4,1.2)] for i in range(12)]+[Vector((0,0,1.7))]
    bmc=bmesh.new(); [bmc.verts.new(p) for p in hubpts]
    me=bpy.data.meshes.new("h"); bmc.to_mesh(me); bmc.free(); h=bpy.data.objects.new("h",me); bpy.context.scene.collection.objects.link(h)
    co=C.convex_collision([h],f"{NAME}_collision",max_angle=2); bpy.data.objects.remove(h)
    print(f"COLLISION {NAME}: {len(co.data.polygons)} tris")
    C.export_glb([co],f"{OUT}/{NAME}_collision.glb",materials=False); co.hide_render=True
    bpy.ops.file.pack_all(); bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE,"stations.blend"))
main()
