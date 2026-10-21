"""Project Space - asteroids S/M/L x 3 variants + ore-bearing variants + break-apart chunks.

Headless:  blender -b -P asteroids.py -- [--only asteroid_m_02] [--no-export]
Output:    <ROOT>/assets/models/asteroids/<name>.glb + <name>_collision.glb
           <ROOT>/art/blender/asteroids/asteroids.blend (all assets, for inspection)

Units 1u = 1 m, pivot = bbox centre (Z=0 = play plane), glTF +Y up.
Empties (children of the rock mesh, local +Z(Blender) = Godot +Y points along the outward normal):
  OreSocket_<n>   surface mount points for surface / crystal nodes (spread over the upper
                  half and the silhouette, so they read top-down)
  VeinSocket_<n>  (ore variants only) on the glowing veins
  CoreSocket      core node centre (= pivot)
Form: icosphere -> archetype deformation (boulder / angular / twin) + fbm lumps + craters
-> collapse-decimate to the tri budget -> palette faces -> soft custom normals.
"""
import bpy, bmesh, sys, os, math, random
from mathutils import Vector, Matrix, noise
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,os.path.join(HERE,"..","_shared"))
import ps_common as C

ARGS=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
ROOT=os.environ.get("PS_ROOT") or os.path.abspath(os.path.join(HERE,"..","..",".."))
OUT=f"{ROOT}/assets/models/asteroids"

# name: (archetype, radius m, target tris, seed, ore)
# radius = horizontal half-extent (gameplay radius). L matches m1_mining.json (rock 3.5 m, crystal 4.5 m).
SPEC = {
 "asteroid_s_01":("boulder",0.9,140,11,False), "asteroid_s_02":("angular",1.1,140,12,False), "asteroid_s_03":("twin",1.2,140,13,False),
 "asteroid_m_01":("boulder",2.2,290,21,False), "asteroid_m_02":("angular",2.5,290,22,False), "asteroid_m_03":("twin",2.8,290,23,False),
 "asteroid_l_01":("boulder",3.5,480,31,False), "asteroid_l_02":("angular",4.0,480,32,False), "asteroid_l_03":("twin",4.5,480,33,False),
 "asteroid_ore_m_01":("boulder",2.5,300,41,True), "asteroid_ore_l_01":("angular",4.0,480,42,True),
}
N_SOCKETS={"s":2,"m":3,"l":4}
CHUNKS={"asteroid_chunk_01":(0.30,51),"asteroid_chunk_02":(0.45,52),"asteroid_chunk_03":(0.65,53)}

def fbm(p,oct=3):
    v=0;a=1;f=1
    for _ in range(oct): v+=a*noise.noise(p*f); a*=0.5; f*=2.1
    return v

def deform(d, arch, rnd, seed):
    off=Vector((seed*1.7,seed*3.1,seed*5.3))
    if arch=="boulder":
        p=Vector((d.x*1.0,d.y*0.93,d.z*0.82))
    elif arch=="angular":
        p=Vector((d.x*1.30,d.y*0.95,d.z*0.80))
    else:  # twin lobes with a waist
        p=Vector((d.x*1.55,d.y*1.0,d.z*0.85))
        pinch=1-0.30*math.exp(-(p.x/0.42)**2); p.y*=pinch; p.z*=pinch
        if p.x>0: p*=1.08
    p*=1+0.13*fbm(d*1.5+off)+0.05*fbm(d*4.0+off*2)
    return p

def make_rock(name, arch, R, target, seed, ore, mats):
    rnd=random.Random(seed)
    craters=[(Vector((rnd.uniform(-1,1),rnd.uniform(-1,1),rnd.uniform(0.0,1))).normalized(),rnd.uniform(0.30,0.45),rnd.uniform(0.09,0.14)) for _ in range(3 if arch!="twin" else 2)]
    cuts=[]
    if arch=="angular":
        for _ in range(4):
            n=Vector((rnd.uniform(-1,1),rnd.uniform(-1,1),rnd.uniform(-0.4,1))).normalized(); cuts.append((n,rnd.uniform(0.62,0.78)))
    def surf(d):
        p=deform(d,arch,rnd,seed)
        for c,cr,dep in craters:
            a=math.acos(max(-1,min(1,d.dot(c))))
            if a<cr*1.25:
                t=a/cr; k=-dep*(1-t*t) if t<1 else dep*0.35*math.sin((t-1)/0.25*math.pi)
                p*=1+k
        for n,o in cuts:   # flatten into fracture planes
            h=p.dot(n)
            if h>o: p-=n*(h-o)*0.95
        return p
    # even, chunky facets: jittered Fibonacci directions -> convex hull (= spherical Delaunay,
    # 2N-4 tris) -> each vertex pushed back onto the deformed surface (restores dents / waist).
    N=int(target*(0.66 if ore else 1.0))//2+2; dirs=[]
    ga=math.pi*(3-math.sqrt(5))
    for i in range(N):
        z=1-2*(i+0.5)/N; r=math.sqrt(1-z*z); th=ga*i
        d=Vector((r*math.cos(th),r*math.sin(th),z))+Vector((rnd.gauss(0,1),rnd.gauss(0,1),rnd.gauss(0,1)))*0.18/math.sqrt(N/40)
        dirs.append(d.normalized())
    bm=bmesh.new(); vs=[bm.verts.new(d) for d in dirs]
    bmesh.ops.convex_hull(bm,input=bm.verts); bmesh.ops.triangulate(bm,faces=bm.faces)
    for v in bm.verts: v.co=surf(v.co.normalized())
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
    # scale to gameplay radius and centre on bbox
    xs=[v.co.x for v in bm.verts]; ys=[v.co.y for v in bm.verts]; zs=[v.co.z for v in bm.verts]
    ctr=Vector(((max(xs)+min(xs))/2,(max(ys)+min(ys))/2,(max(zs)+min(zs))/2))
    s=R/(max(max(xs)-min(xs),max(ys)-min(ys))/2)
    for v in bm.verts: v.co=(v.co-ctr)*s
    bm.faces.ensure_lookup_table(); bm.normal_update()
    # palette per facet
    off=Vector((seed*0.7,seed*1.3,seed*2.9)); cells=[]
    for f in bm.faces:
        c=f.calc_center_median()/R; d=c.normalized()
        in_crater=any(math.acos(max(-1,min(1,d.dot(cc))))<cr*0.8 for cc,cr,_ in craters)
        on_cut=any(abs(f.normal.dot(n))>0.97 for n,_ in cuts)
        nz=fbm(c*1.1+off,2)
        if in_crater: cell=C.ROCK_D if f.normal.dot(d)>0.75 or rnd.random()<0.5 else C.ROCK_M
        elif on_cut: cell=C.ROCK_L
        elif nz>0.12: cell=C.ROCK_L
        elif f.normal.dot(d)<0.55: cell=C.ROCK_D   # steep, inward-facing facets read as crevices (refs)
        elif nz<-0.26: cell=C.ROCK_P
        else: cell=C.ROCK_M
        cells.append(cell)
    vein_faces=set(); vein_centres=[]
    if ore:
        planes=[Vector((rnd.uniform(-1,1),rnd.uniform(-1,1),rnd.uniform(-0.3,0.3))).normalized() for _ in range(2)]
        sel=[f for f in bm.faces if any(abs(f.calc_center_median().dot(n))<0.10*R for n in planes) and f.normal.z>-0.3]
        res=bmesh.ops.inset_region(bm,faces=sel,thickness=0.045*R,depth=-0.02*R,use_even_offset=False)
        bm.faces.ensure_lookup_table()
        selset=set(sel); newside=set(res["faces"])
        # rebuild cell list: original faces keep their cell (bmesh keeps order for old faces, new faces appended)
        cells=cells+[C.ROCK_D]*(len(bm.faces)-len(cells))
        for f in sel: cells[f.index]=C.ORE; vein_faces.add(f.index)
        # vein socket candidates
        vein_centres=[(f.calc_center_median(),f.normal.copy()) for f in sel if f.normal.z>0.0]
    ob=C.mesh_from_bm(bm,name,f"{name}_mesh",mats,cells,soft=0.18); bm.free()
    me=ob.data; size=name.split("_")[-2] if "ore" not in name else name.split("_")[-2]
    # OreSocket_n: farthest point sampling on faces that read from above (upper half + silhouette)
    cand=[(p.center.copy(),p.normal.copy(),p.area) for p in me.polygons if -0.05<p.normal.z<0.92 and p.index not in vein_faces]
    cand.sort(key=lambda c:-c[2]); cand=cand[:max(12,len(cand)//2)]
    k=N_SOCKETS[size[0]]; chosen=[max(cand,key=lambda c:c[1].z*0.5+c[2])]
    while len(chosen)<k:
        chosen.append(max(cand,key=lambda c:min((c[0]-q[0]).length for q in chosen)))
    for i,(p,n,_) in enumerate(chosen): C.empty(f"OreSocket_{i}",p,ob,n,0.3*R/2)
    if ore and vein_centres:
        vc=[vein_centres[len(vein_centres)//4], vein_centres[(3*len(vein_centres))//4]]
        if len(vein_centres)>4: vc=[max(vein_centres,key=lambda c:c[1].z)]; vc.append(max(vein_centres,key=lambda c:(c[0]-vc[0][0]).length))
        for i,(p,n) in enumerate(vc): C.empty(f"VeinSocket_{i}",p,ob,n,0.3*R/2)
    C.empty("CoreSocket",(0,0,0),ob,None,0.3*R/2)
    return ob

def make_chunk(name, R, seed, mats):
    rnd=random.Random(seed); bm=bmesh.new()
    for _ in range(11):
        d=Vector((rnd.gauss(0,1),rnd.gauss(0,1),rnd.gauss(0,1))).normalized()
        bm.verts.new(Vector((d.x*1.25,d.y*0.9,d.z*0.7))*R*rnd.uniform(0.8,1.1))
    r=bmesh.ops.convex_hull(bm,input=bm.verts)
    bmesh.ops.delete(bm,geom=[g for g in set(r["geom_interior"]+r["geom_unused"]) if isinstance(g,bmesh.types.BMVert)],context="VERTS")
    bmesh.ops.dissolve_limit(bm,angle_limit=math.radians(8),verts=bm.verts,edges=bm.edges); bmesh.ops.triangulate(bm,faces=bm.faces)
    xs=[v.co for v in bm.verts]; ctr=sum(xs,Vector())/len(xs)
    for v in bm.verts: v.co-=ctr
    bm.normal_update(); bm.faces.ensure_lookup_table()
    big=max(bm.faces,key=lambda f:f.calc_area())  # largest facet = fresh fracture face (lighter)
    cells=[C.ROCK_L if f is big else (C.ROCK_M if rnd.random()<0.6 else C.ROCK_P) for f in bm.faces]
    return C.mesh_from_bm(bm,name,f"{name}_mesh",mats,cells,soft=0.2)

def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mats=C.make_materials(os.path.join(HERE,"..","_shared"))
    only=ARGS[ARGS.index("--only")+1] if "--only" in ARGS else None
    built=[]
    x=0.0
    for name,(arch,R,tgt,seed,ore) in SPEC.items():
        if only and name!=only: continue
        built.append(make_rock(name,arch,R,tgt,seed,ore,mats)); finish(built[-1])
    for name,(R,seed) in CHUNKS.items():
        if only and name!=only: continue
        built.append(make_chunk(name,R,seed,mats)); finish(built[-1])
    x=0
    for ob in built: ob.location.x=x; x+=ob.dimensions.x+1.0
    bpy.ops.file.pack_all(); bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE,"asteroids.blend"))

def finish(ob):
    for ob in [ob]:
        socks=[c.name for c in ob.children]
        print(f"TRIS {ob.name}: {C.tri_count(ob)}  sockets={socks}  dims={tuple(round(d,2) for d in ob.dimensions)}")
        if "--no-export" not in ARGS:
            C.export_glb(C.with_children(ob),f"{OUT}/{ob.name}.glb")
            co=C.convex_collision([ob],f"{ob.name}_collision"); print(f"COLLISION {ob.name}: {len(co.data.polygons)} tris")
            C.export_glb([co],f"{OUT}/{ob.name}_collision.glb",materials=False); bpy.data.objects.remove(co)
        for c in ob.children: c.name=f"{ob.name}.{c.name}"   # keep socket names unique for the next asset
main()
