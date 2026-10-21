"""Project Space - starter_shuttle_01: head/body/wings/engine, levels L1..L3.

Headless (one Blender process at a time, keep RAM low):
  blender -b -P starter_shuttle_01.py -- --export                 # 12 part GLBs + collision + previews + .blend per level
  blender -b -P starter_shuttle_01.py -- --render-level 2         # top / 34 / ingame for an all-L2 ship
  blender -b -P starter_shuttle_01.py -- --parts-table            # each part x level, isolated
  blender -b -P starter_shuttle_01.py -- --combo 3,1,2,1 --tag mixA   # head,body,wings,engine levels
  (--clip-report prints triangle overlap counts between parts for the built combo)

Naming standard: object <Part>_starter_shuttle_01 (glTF root node), mesh <part>_L<n>_mesh.
Body = root, origin = ship center. Body children: Socket_Head/Wings/Engine, Hardpoint_L/R/Nose
(fixed across levels). Engine: FX_EngineTrail_<n>. Head: FX_MiningOrigin. Reserved: Hardpoint_Top.
Axes: 1u=1m, nose +Y, up +Z (glTF +Y-up -> Godot nose -Z). Play plane Z=0.

Method: the hull is one loft of shared cross-section rings sampled from a smooth Hermite
station curve. Seam rings and seam slopes are fixed, so any level of a part fits any level
of its neighbour. Hull normals come from the whole loft (custom split normals), so shading
is continuous across seams. Every part is a half mesh (x>=0) + Mirror. Upgrades are additive
features on top of a level-independent core (fins, panels, lights, bigger nozzles).
"""
import bpy, bmesh, sys, os, math
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree

ARGS = sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
def arg(name, default=None):
    return ARGS[ARGS.index(name)+1] if name in ARGS else default
HULL = "starter_shuttle_01"
# ROOT = repo (or mirror) root, derived from this file: <ROOT>/art/blender/ships/<hull>/<this>.py
ROOT = os.environ.get("PS_ROOT") or os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)),"..","..","..",".."))
OUT  = f"{ROOT}/assets/models/ships/{HULL}"
SRC  = f"{ROOT}/art/blender/ships/{HULL}"
PRV  = os.environ.get("PS_PREVIEWS", f"{ROOT}/previews")     # preview GLBs: keep OUT of the repo
RND  = os.environ.get("PS_RENDERS", f"{ROOT}/renders")
PARTS = ("head","body","wings","engine")
PART_OBJ = {k: f"{k.capitalize()}_{HULL}" for k in PARTS}

# ---------------- palette ----------------
PAL = {
 0:((0.93,0.91,0.88),None),   # hull off-white
 1:((0.66,0.69,0.75),None),   # underside light grey
 2:((0.93,0.50,0.18),None),   # accent orange
 3:((0.60,0.33,0.18),None),   # accent brown
 4:((0.11,0.12,0.17),None),   # dark panel
 5:((0.30,0.32,0.38),None),   # metal grey
 6:((0.30,0.88,0.97),(0.10,0.55,0.70)),  # canopy glass cyan
 7:((0.45,0.80,1.00),(0.45,0.80,1.00)),  # engine glow blue
 8:((0.55,1.00,1.00),(0.55,1.00,1.00)),  # cyan light
 9:((0.20,0.40,0.56),None),   # spine tech blue
 10:((0.22,0.24,0.30),None),  # gunmetal
}
WHITE,GREY,ORANGE,BROWN,DARK,METAL,GLASS,GLOW,LIGHT,SPINE,GUN = range(11)
EMISSIVE = {GLASS,GLOW,LIGHT}
CELLS = 4; CPX = 16
def cell_uv(c): return ((c % CELLS)+0.5)/CELLS, 1-((c//CELLS)+0.5)/CELLS

def make_materials():
    n = CELLS*CPX; imgs = {}
    for key in ("base","emit"):
        im = bpy.data.images.new(f"ps_palette_{key}", n, n, alpha=False)
        px = [0.0]*(n*n*4)
        for c,(b,e) in PAL.items():
            col = b if key=="base" else (e or (0,0,0))
            cx, cy = c % CELLS, CELLS-1-(c//CELLS)
            for y in range(cy*CPX,(cy+1)*CPX):
                for x in range(cx*CPX,(cx+1)*CPX):
                    i=(y*n+x)*4; px[i:i+4]=[*col,1.0]
        im.pixels = px; im.filepath_raw = f"{SRC}/ps_palette_{key}.png"; im.file_format="PNG"; im.save()
        imgs[key] = im
    mats = []
    for name,glow in (("M_ps_palette",False),("M_ps_glow",True)):
        m = bpy.data.materials.new(name); m.use_nodes=True
        nt=m.node_tree; bsdf=nt.nodes["Principled BSDF"]; bsdf.inputs["Roughness"].default_value=0.5
        t=nt.nodes.new("ShaderNodeTexImage"); t.image=imgs["base"]; t.interpolation="Closest"
        nt.links.new(t.outputs["Color"], bsdf.inputs["Base Color"])
        if glow:
            te=nt.nodes.new("ShaderNodeTexImage"); te.image=imgs["emit"]; te.interpolation="Closest"
            nt.links.new(te.outputs["Color"], bsdf.inputs["Emission Color"])
            bsdf.inputs["Emission Strength"].default_value=2.0
        mats.append(m)
    return mats

# ---------------- hull stations ----------------
KEY_FRONT = [  # (y, half_width, z_top, z_bottom) — head + body, identical for all levels
 (0.86, 0.045, 0.045, -0.020),
 (0.74, 0.110, 0.085, -0.040),
 (0.55, 0.180, 0.130, -0.060),
 (0.30, 0.225, 0.165, -0.075),
 (0.05, 0.265, 0.180, -0.085),   # SEAM head|body   (fixed)
 (-0.20,0.285, 0.180, -0.085),
 (-0.55,0.290, 0.160, -0.085),   # SEAM body|engine (fixed)
]
KEY_ENGINE = {   # engine stations per level (grow heavier with level)
 1: [(-0.66,0.292,0.160,-0.085),(-0.76,0.287,0.152,-0.080),(-0.84,0.270,0.138,-0.072)],
 2: [(-0.66,0.297,0.163,-0.087),(-0.76,0.297,0.158,-0.084),(-0.85,0.283,0.146,-0.078)],
 3: [(-0.66,0.303,0.166,-0.089),(-0.77,0.308,0.164,-0.088),(-0.87,0.296,0.152,-0.083)],
}
SEAM_HEAD, SEAM_ENGINE = 0.05, -0.55
SEAMS = (SEAM_HEAD, SEAM_ENGINE)
NOSE = (0.0, 0.94, 0.020)
Y_HEAD = [0.86,0.80,0.74,0.65,0.55,0.42,0.30,0.17,0.05]
Y_BODY = [0.05,-0.075,-0.20,-0.375,-0.55]
def y_engine(lv): return [-0.55]+[k[0] for k in KEY_ENGINE[lv]][:1]+[ (KEY_ENGINE[lv][0][0]+KEY_ENGINE[lv][1][0])/2 ]+[k[0] for k in KEY_ENGINE[lv]][1:]
def y_all(lv): return Y_HEAD + Y_BODY[1:] + y_engine(lv)[1:]

def keys(lv): return KEY_FRONT + KEY_ENGINE[lv]

def station(y, lv=1):
    """Hermite through key stations; slopes at seam keys use L1 data so neighbouring parts
    never depend on each other's level."""
    K=keys(lv); ys=[k[0] for k in K]
    if y>=ys[0]: return K[0][1:]
    if y<=ys[-1]: return K[-1][1:]
    for j in range(len(K)-1):
        if ys[j] >= y >= ys[j+1]: break
    def slope(k,c):
        KK = keys(1) if ys[k] in SEAMS else K
        yy=[q[0] for q in KK]; kk=yy.index(ys[k]) if ys[k] in yy else k
        a=max(kk-1,0); b=min(kk+1,len(KK)-1)
        return (KK[b][c]-KK[a][c])/(yy[b]-yy[a])
    h=ys[j+1]-ys[j]; t=(y-ys[j])/h
    h00=2*t**3-3*t**2+1; h10=t**3-2*t**2+t; h01=-2*t**3+3*t**2; h11=t**3-t**2
    return tuple(h00*K[j][c]+h10*h*slope(j,c)+h01*K[j+1][c]+h11*h*slope(j+1,c) for c in (1,2,3))

PROF = [(0,1,"t"),(0.35,0.97,"t"),(0.72,0.78,"t"),(1.0,0.25,"t"),(0.86,0.70,"b"),(0.45,1.0,"b"),(0,1.0,"b")]
CHINE = 3
def ring(y, lv=1):
    w,zt,zb = station(y,lv)
    return [Vector((fx*w, y, fz*(zt if s=="t" else zb))) for fx,fz,s in PROF]
def zt_at(y, lv=1): return station(y,lv)[1]
def w_at(y, lv=1): return station(y,lv)[0]

def hull_normal(Y, k, i, side, lv):
    y=Y[k]; r=ring(y,lv)
    lvn = 1 if y in SEAMS else lv          # seam rings: level-independent normals
    YN = y_all(lvn); kk = YN.index(y)
    pa = ring(YN[kk-1],lvn)[i] if kk>0 else Vector(NOSE)
    pb = ring(YN[kk+1],lvn)[i] if kk<len(YN)-1 else r[i]
    ty = pa-pb
    def P(q):
        if q<0: v=r[1].copy(); v.x=-v.x; return v
        if q>6: v=r[5].copy(); v.x=-v.x; return v
        return r[q]
    tp = ((P(2)-P(3)) if side=="up" else (P(3)-P(4))) if i==CHINE else P(i-1)-P(i+1)
    n = ty.cross(tp).normalized()
    if n.dot(r[i]-Vector((0,y,(r[0].z+r[6].z)*0.5)))<0: n=-n
    return n

# ---------------- mesh builder ----------------
class MB:
    def __init__(s): s.V=[]; s.F=[]; s.C=[]; s.N=[]
    def v(s,p): s.V.append(tuple(p)); return len(s.V)-1
    def face(s,idx,cell,normals=None): s.F.append(tuple(idx)); s.C.append(cell); s.N.append(normals)
    def quad(s,pts,cell): s.face([s.v(p) for p in pts],cell)
    def loft(s,rings,cellfn,normfn=None):
        base=len(s.V); n=len(rings[0])
        for r in rings:
            for p in r: s.v(p)
        for a in range(len(rings)-1):
            for i in range(n-1):
                q=(base+a*n+i, base+a*n+i+1, base+(a+1)*n+i+1, base+(a+1)*n+i)
                nr=[normfn(a,i,i),normfn(a,i+1,i),normfn(a+1,i+1,i),normfn(a+1,i,i)] if normfn else None
                s.face(q,cellfn(a,i),nr)
        return base
    def cap(s, ringpts, center, cell):
        c=s.v(center); b=len(s.V)
        for p in ringpts: s.v(p)
        for i in range(len(ringpts)-1): s.face((b+i,b+i+1,c),cell)
    def plate(s, pts, ztop, zbot, ctop, cbot, cside):
        """extruded 2D polygon pts (x,y); ztop/zbot: f(x,y)->z."""
        n=len(pts); b=len(s.V)
        for x,y in pts: s.v((x,y,ztop(x,y)))
        for x,y in pts: s.v((x,y,zbot(x,y)))
        s.face([b+i for i in range(n)],ctop); s.face([b+n+i for i in reversed(range(n))],cbot)
        for i in range(n):
            j=(i+1)%n; s.face((b+j,b+i,b+n+i,b+n+j), cside(i) if callable(cside) else cside)
    def vfin(s, x, pts_yz, thick, cside, cedge, lean=0.0):
        """vertical fin: polygon in (y,z) at x, thickness in x; lean shifts x outward with z."""
        n=len(pts_yz); b=len(s.V); z0=min(z for _,z in pts_yz)
        for side in (+1,-1):
            for y,z in pts_yz: s.v((x+side*thick/2+lean*(z-z0), y, z))
        s.face([b+i for i in range(n)],cside); s.face([b+n+i for i in reversed(range(n))],cside)
        for i in range(n):
            j=(i+1)%n; s.face((b+j,b+i,b+n+i,b+n+j), cedge(i) if callable(cedge) else cedge)

def surf(y,i,t,lift=0.004,lv=1):
    r=ring(y,lv); p=r[i].lerp(r[i+1],t)
    e=r[i+1]-r[i]; n=Vector((e.z,0,-e.x)).normalized()
    if n.dot(p-Vector((0,y,(r[0].z+r[6].z)/2)))<0: n=-n
    return p+n*lift

def raised_panel(mb, y0, y1, i, t0, t1, h, ctop, cside, lv=1):
    """box panel sitting on hull profile segment i between stations y0..y1."""
    top=[surf(y0,i,t0,h,lv),surf(y0,i,t1,h,lv),surf(y1,i,t1,h,lv),surf(y1,i,t0,h,lv)]
    bot=[surf(y0,i,t0,-0.006,lv),surf(y0,i,t1,-0.006,lv),surf(y1,i,t1,-0.006,lv),surf(y1,i,t0,-0.006,lv)]
    b=len(mb.V)
    for p in top+bot: mb.v(p)
    mb.face((b,b+1,b+2,b+3),ctop)
    for k in range(4):
        j=(k+1)%4; mb.face((b+j,b+k,b+4+k,b+4+j),cside)

def build(name, meshname, mb, mats, origin, bevel=None):
    me = bpy.data.meshes.new(meshname); o = Vector(origin)
    me.from_pydata([Vector(p)-o for p in mb.V], [], mb.F); me.update()
    uv = me.uv_layers.new(name="UVMap")
    for m in mats: me.materials.append(m)
    for p,c in zip(me.polygons, mb.C):
        p.material_index = 1 if c in EMISSIVE else 0
        for li in p.loop_indices: uv.data[li].uv = cell_uv(c)
    bm=bmesh.new(); bm.from_mesh(me); bm.faces.ensure_lookup_table()
    before=[f.normal.copy() for f in bm.faces]
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    flip=[f.normal.dot(b)<0 for f,b in zip(bm.faces,before)]; bm.free()
    for p,fl in zip(me.polygons,flip):
        if fl: p.flip()
    me.update(); me.shade_smooth()
    loopn=[None]*len(me.loops)
    for p,nr in zip(me.polygons,mb.N):
        li=list(p.loop_indices)
        if nr is None:
            for l in li: loopn[l]=tuple(p.normal)
        else:
            orig=list(mb.F[p.index])
            for l,v in zip(li,p.vertices): loopn[l]=tuple(nr[orig.index(v)])
    me.normals_split_custom_set(loopn)
    ob = bpy.data.objects.new(name, me); ob.location = o
    bpy.context.scene.collection.objects.link(ob)
    md=ob.modifiers.new("Mirror","MIRROR"); md.use_clip=True; md.use_mirror_merge=True; md.merge_threshold=0.0005
    if bevel:
        bv=ob.modifiers.new("Bevel","BEVEL"); bv.width=bevel; bv.segments=1; bv.limit_method="ANGLE"; bv.angle_limit=math.radians(35)
    return ob

def empty(name, loc_world, parent, size=0.06, kind="PLAIN_AXES"):
    e=bpy.data.objects.new(name,None); e.empty_display_type=kind; e.empty_display_size=size
    bpy.context.scene.collection.objects.link(e)
    e.parent=parent; e.matrix_parent_inverse=Matrix.Identity(4)
    e.location=Vector(loc_world)-parent.matrix_world.translation
    return e

def hull_section(mb, Y, cellfn, lv=1):
    rings=[ring(y,lv) for y in Y]
    YA=y_all(lv); k0=YA.index(Y[0])
    mb.loft(rings,cellfn,lambda a,i,fi: hull_normal(YA,k0+a,i,"up" if fi<CHINE else "dn",lv))
    return rings

def seam_cap(mb, y, lv=1, cell=DARK):
    r=ring(y,lv); mb.cap(r, (0,y,(r[0].z+r[6].z)/2), cell)

def canopy(mb, cs, cell=GLASS, lv=1):
    cr=[[Vector((0,y,zt_at(y,lv)+h)),Vector((0.6*cw,y,zt_at(y,lv)+0.78*h)),Vector((cw,y,zt_at(y,lv)-0.035))] for y,cw,h in cs]
    return mb.loft(cr,lambda a,i:cell), cr

def frame_bar(mb, y, cw, h, dy=0.014, cell=DARK):
    z0=zt_at(y)+h+0.003; z1=zt_at(y-dy)+h+0.003
    mb.quad([(0,y,z0),(0.62*cw,y,z0-0.24*h),(0.62*cw,y-dy,z1-0.24*h),(0,y-dy,z1)],cell)

# ---------------- anchors ----------------
SOCK = {"head":(0,SEAM_HEAD,0),"wings":(0,-0.20,0),"engine":(0,SEAM_ENGINE,0)}
HP = {"Hardpoint_L":(-0.31,0.30,-0.03),"Hardpoint_R":(0.31,0.30,-0.03),"Hardpoint_Nose":(0.0,1.00,0.02)}
HP_KEEPOUT = 0.05
HP_TOP_RESERVED = (0.0,-0.36,0.205); HP_TOP_KEEPOUT = 0.06

# ---------------- HEAD ----------------
def make_head(mats, lv):
    mb=MB()
    hull_section(mb,Y_HEAD,lambda a,i: ORANGE if a==0 else (GREY if i>=CHINE else WHITE))
    t=mb.v(NOSE)
    for i in range(6):
        nA=hull_normal(y_all(1),0,i,"up" if i<CHINE else "dn",1); nB=hull_normal(y_all(1),0,i+1,"up" if i<CHINE else "dn",1)
        mb.face((i+1,i,t),ORANGE,[nB,nA,(Vector((0,1,0))+(nA+nB)*0.25).normalized()])
    seam_cap(mb, SEAM_HEAD)
    # canopy grows with level (taller, wider, more frames)
    sw={1:1.0,2:1.05,3:1.12}[lv]; sh={1:1.0,2:1.15,3:1.30}[lv]
    cs=[(0.47,0.060,0.040),(0.37,0.100,0.068),(0.25,0.122,0.082),(0.14,0.122,0.080),(0.07,0.110,0.066)]
    cs=[(y,cw*sw,h*sh) for y,cw,h in cs]
    b,cr=canopy(mb,cs)
    tip=mb.v((0,0.57 if lv<3 else 0.59,zt_at(0.57)-0.006))
    mb.face((b,b+1,tip),GLASS); mb.face((b+1,b+2,tip),GLASS)
    l=b+3*(len(cs)-1); c=mb.v((0,0.07,zt_at(0.07)-0.03)); mb.face((l,l+1,l+2,c),DARK)
    bars={1:[0.30],2:[0.34,0.22],3:[0.40,0.30,0.20]}[lv]
    for y in bars:
        cw=0.122*sw; h=0.078*sh; frame_bar(mb,y,cw,h)
    for i in (0,1,2): mb.quad([surf(0.665,i,0),surf(0.665,i,1),surf(0.650,i,1),surf(0.650,i,0)],DARK)
    mb.quad([surf(0.50,2,0.35),surf(0.50,2,0.65),surf(0.47,2,0.65),surf(0.47,2,0.35)],DARK)
    if lv>=2:
        # canards: small swept fins at the cheeks (white with orange tips)
        span={2:0.34,3:0.40}[lv]; zc=lambda x,y: 0.25*zt_at(y)-0.004
        rx=lambda y: 0.85*w_at(y)
        y0,y1=0.68,0.45
        main=[(rx(y0),y0),(span-0.045,0.525),(span-0.045,0.465),(rx(y1),y1)]
        tipp=[(span-0.045,0.525),(span,0.50),(span,0.455),(span-0.045,0.465)]
        th=lambda x,y: 0.010+0.012*max(0,1-(x-0.15)/0.2)
        mb.plate(main,lambda x,y:zc(x,y)+th(x,y),lambda x,y:zc(x,y)-th(x,y),WHITE,GREY,METAL)
        mb.plate(tipp,lambda x,y:zc(x,y)+0.010,lambda x,y:zc(x,y)-0.010,ORANGE,ORANGE,BROWN)
        if lv>=3:   # small cyan light on the canard tip
            mb.quad([(span-0.04,0.505,zc(0,0.5)+0.0115),(span-0.008,0.492,zc(0,0.5)+0.0115),(span-0.008,0.468,zc(0,0.47)+0.0115),(span-0.04,0.475,zc(0,0.47)+0.0115)],LIGHT)
        # cyan cheek light strip
        mb.quad([surf(0.60,1,0.55),surf(0.60,1,0.85),surf(0.44,1,0.85),surf(0.44,1,0.55)],LIGHT)
    if lv>=3:
        # dorsal sensor ridge in front of the canopy (dark, cyan tip light)
        rr=[[Vector((0,y,zt_at(y)+h)),Vector((0.022,y,zt_at(y)+h*0.7)),Vector((0.03,y,zt_at(y)-0.01))] for y,h in ((0.80,0.004),(0.72,0.024),(0.60,0.030))]
        rb=mb.loft(rr,lambda a,i:DARK)
        mb.face((rb,rb+1,rb+2,mb.v((0,0.80,zt_at(0.80)-0.01))),DARK)
        mb.face((rb+8,rb+7,rb+6,mb.v((0,0.60,zt_at(0.60)-0.01))),DARK)
        mb.quad([(0,0.70,zt_at(0.70)+0.0285),(0.014,0.70,zt_at(0.70)+0.025),(0.014,0.64,zt_at(0.64)+0.027),(0,0.64,zt_at(0.64)+0.0305)],LIGHT)
        # orange nose stripes + cyan canopy-side light frames
        mb.quad([surf(0.36,2,0.05),surf(0.36,2,0.25),surf(0.12,2,0.25),surf(0.12,2,0.05)],LIGHT)
    ob=build(PART_OBJ["head"],f"head_L{lv}_mesh",mb,mats,SOCK["head"])
    return ob, {"FX_MiningOrigin":(0,0.945,0.02)}

# ---------------- BODY ----------------
def make_body(mats, lv):
    mb=MB()
    hull_section(mb,Y_BODY,lambda a,i: GREY if i>=CHINE else (ORANGE if (i==2 and a==0) else WHITE))
    seam_cap(mb,SEAM_HEAD); seam_cap(mb,SEAM_ENGINE)
    gs=[(0.045,0.106,0.060),(-0.04,0.100,0.050),(-0.12,0.082,0.032)]
    b,_=canopy(mb,gs)
    mb.face((b,b+1,b+2,mb.v((0,0.045,zt_at(0.045)-0.03))),DARK)
    e=mb.v((0,-0.17,zt_at(-0.17)-0.004)); l=b+6
    mb.face((l,l+1,e),GLASS); mb.face((l+1,l+2,e),GLASS)
    if lv>=2: frame_bar(mb,-0.04,0.10,0.050)
    sp=[[Vector((0,y,zt_at(y)+0.016)),Vector((0.068,y,zt_at(y)+0.012)),Vector((0.083,y,zt_at(y)-0.014))] for y in (-0.15,-0.36,-0.54)]
    b=mb.loft(sp,lambda a,i:SPINE)
    mb.face((b,b+1,b+2,mb.v((0,-0.15,zt_at(-0.15)-0.01))),SPINE)
    for y0 in (-0.21,-0.44):
        y1=y0-0.07; z0=zt_at(y0)+0.0175; z1=zt_at(y1)+0.0175
        mb.quad([(0.014,y0,z0),(0.045,y0,z0-0.002),(0.045,y1,z1-0.002),(0.014,y1,z1)],LIGHT)
    if lv==1:
        for k in range(3):
            ya=-0.24-k*0.065; mb.quad([surf(ya,2,0.2),surf(ya,2,0.8),surf(ya-0.035,2,0.8),surf(ya-0.035,2,0.2)],DARK)
        mb.quad([surf(-0.10,2,0.88),surf(-0.10,2,1.0),surf(-0.53,2,1.0),surf(-0.53,2,0.88)],ORANGE)
    else:
        # raised flank armour plates (bigger at L3) with vents, orange trim and lights
        t0,t1,h = (0.12,0.86,0.016) if lv==2 else (0.04,0.97,0.026)
        raised_panel(mb,-0.06,-0.52,2,t0,t1,h,WHITE,METAL)
        for k in range(3):
            ya=-0.24-k*0.065
            mb.quad([surf(ya,2,t0+0.12,h+0.003),surf(ya,2,t1-0.12,h+0.003),surf(ya-0.035,2,t1-0.12,h+0.003),surf(ya-0.035,2,t0+0.12,h+0.003)],DARK)
        mb.quad([surf(-0.08,2,t0+0.06,h+0.003),surf(-0.08,2,t1-0.06,h+0.003),surf(-0.15,2,t1-0.06,h+0.003),surf(-0.15,2,t0+0.06,h+0.003)],ORANGE)
        mb.quad([surf(-0.10,2,0.90,0.004) if lv==2 else surf(-0.10,3,0.05,0.004),surf(-0.10,2,1.0,0.004) if lv==2 else surf(-0.10,3,0.35,0.004),
                 surf(-0.53,2,1.0,0.004) if lv==2 else surf(-0.53,3,0.35,0.004),surf(-0.53,2,0.90,0.004) if lv==2 else surf(-0.53,3,0.05,0.004)],ORANGE)
        mb.quad([surf(-0.45,2,t0+0.10,h+0.003),surf(-0.45,2,t1-0.10,h+0.003),surf(-0.49,2,t1-0.10,h+0.003),surf(-0.49,2,t0+0.10,h+0.003)],LIGHT)
    if lv>=3:
        # spine rails (outside the Hardpoint_Top keep-out) + side sensor blisters
        for (ya,yb) in ((-0.16,-0.30),(-0.42,-0.54)):
            pts=[(0.084,ya),(0.104,ya),(0.104,yb),(0.084,yb)]
            mb.plate(pts,lambda x,y:zt_at(y)*0.985+0.022,lambda x,y:zt_at(y)*0.96-0.01,DARK,DARK,GUN)
        raised_panel(mb,0.03,-0.04,2,0.25,0.75,0.022,GUN,DARK)
        mb.quad([surf(0.02,2,0.32,0.025),surf(0.02,2,0.68,0.025),surf(-0.03,2,0.68,0.025),surf(-0.03,2,0.32,0.025)],LIGHT)
    return build(PART_OBJ["body"],f"body_L{lv}_mesh",mb,mats,(0,0,0)), {}

# ---------------- ENGINE ----------------
def make_engine(mats, lv):
    mb=MB(); YE=y_engine(lv)
    hull_section(mb,YE,lambda a,i: GUN if i>=CHINE else (DARK,GUN,BROWN)[i],lv)
    seam_cap(mb,SEAM_ENGINE,lv)
    yr=YE[-1]; rr=ring(yr,lv); mb.cap(rr[::-1],(0,yr,0.03),DARK)
    zt=lambda y: zt_at(y,lv)
    ch={1:0.034,2:0.040,3:0.046}[lv]; cwid={1:0.125,2:0.135,3:0.145}[lv]
    cw=[(-0.555,cwid-0.025,0.010),(-0.62,cwid,ch),(yr+0.04,cwid-0.005,ch-0.004),(yr-0.005,cwid-0.025,0.012)]
    cr=[[Vector((0,y,zt(y)+h)),Vector((0.7*w,y,zt(y)+h*0.9)),Vector((w,y,zt(y)-0.02))] for y,w,h in cw]
    b=mb.loft(cr,lambda a,i:GUN if a!=1 else DARK)
    mb.face((b,b+1,b+2,mb.v((0,cw[0][0],zt(cw[0][0])-0.02))),GUN)
    l=b+9; mb.face((l+2,l+1,l,mb.v((0,cw[-1][0],zt(cw[-1][0])-0.02))),DARK)
    for y0 in (-0.66,-0.72) if lv<3 else (-0.65,-0.70,-0.75):
        y1=y0-0.025; z=zt(y0)+ch+0.0005
        mb.quad([(0.0,y0,z),(0.085,y0,z-0.004),(0.085,y1,z-0.004),(0.0,y1,z)],ORANGE)
    # nozzles grow per level
    NX,NZ,SEG = 0.112 if lv==1 else (0.118 if lv==2 else 0.126), 0.028, 10
    R={1:(0.064,0.074,0.080,0.057),2:(0.070,0.082,0.090,0.066),3:(0.076,0.090,0.100,0.074)}[lv]
    Ye={1:(-0.72,-0.85,-0.895,-0.87),2:(-0.72,-0.87,-0.925,-0.895),3:(-0.72,-0.89,-0.955,-0.92)}[lv]
    def circ(y,rad): return [Vector((NX+rad*math.cos(2*math.pi*k/SEG),y,NZ+rad*math.sin(2*math.pi*k/SEG))) for k in range(SEG)]
    nr=[circ(Ye[0],R[0]),circ(Ye[1],R[1]),circ(Ye[2],R[2]),circ(Ye[2],R[3]),circ(Ye[3],R[3])]
    b=len(mb.V)
    for q in nr:
        for p in q: mb.v(p)
    for s,cell in enumerate([GUN,ORANGE,METAL if lv<3 else LIGHT,DARK]):
        for k in range(SEG):
            a=b+s*SEG+k; a2=b+s*SEG+(k+1)%SEG; mb.face((a,a2,a2+SEG,a+SEG),cell)
    mb.face([b+4*SEG+k for k in range(SEG)],GLOW)
    if lv>=2:
        # side intake scoops on the engine flanks
        raised_panel(mb,-0.60,-0.74,2,0.15,0.80,0.022,GUN,DARK,lv)
        mb.quad([surf(-0.605,2,0.22,0.0225,lv),surf(-0.605,2,0.73,0.0225,lv),surf(-0.64,2,0.73,0.0225,lv),surf(-0.64,2,0.22,0.0225,lv)],DARK)
        mb.quad([surf(-0.69,2,0.25,0.023,lv),surf(-0.69,2,0.70,0.023,lv),surf(-0.72,2,0.70,0.023,lv),surf(-0.72,2,0.25,0.023,lv)],LIGHT)
    if lv>=3:
        # twin vertical tail fins on the cowl edges, canted outward
        fx=cwid-0.008; zb=zt(-0.70)+0.02
        fin=[(-0.60,zb),(-0.83,zb),(-0.90,zb+0.20),(-0.80,zb+0.20)]
        mb.vfin(fx,fin,0.022,WHITE,lambda i: ORANGE if i==3 else (DARK if i==2 else WHITE),lean=0.25)
        mb.quad([(fx+0.012+0.25*0.17,-0.81,zb+0.17),(fx+0.012+0.25*0.20,-0.82,zb+0.20),(fx+0.012+0.25*0.20,-0.88,zb+0.20),(fx+0.012+0.25*0.17,-0.865,zb+0.17)],LIGHT)
    fx_y=Ye[2]-0.005
    ob=build(PART_OBJ["engine"],f"engine_L{lv}_mesh",mb,mats,SOCK["engine"])
    return ob, {"FX_EngineTrail_0":(-NX,fx_y,NZ),"FX_EngineTrail_1":(NX,fx_y,NZ)}

# ---------------- WINGS ----------------
WING_L = {
 1: {"A":(0.17,0.42),"L":(0.27,0.21),"B":(0.35,0.07),"C":(0.60,-0.20),"G":(0.68,-0.29),"H":(0.70,-0.58),
     "D":(0.60,-0.62),"I":(0.665,-0.82),"J":(0.55,-0.79),"E":(0.40,-0.66),"F":(0.17,-0.62)},
 2: {"A":(0.17,0.42),"L":(0.27,0.21),"B":(0.355,0.07),"C":(0.615,-0.19),"G":(0.715,-0.28),"H":(0.735,-0.59),
     "D":(0.62,-0.63),"I":(0.70,-0.85),"J":(0.57,-0.81),"E":(0.41,-0.67),"F":(0.17,-0.62)},
 3: {"A":(0.17,0.42),"L":(0.275,0.215),"B":(0.36,0.075),"C":(0.63,-0.17),"G":(0.76,-0.26),"H":(0.785,-0.60),
     "D":(0.645,-0.64),"I":(0.745,-0.90),"J":(0.60,-0.85),"E":(0.42,-0.68),"F":(0.17,-0.62)},
}
WPOLY=[(["A","L","B","C","D","E","F"],WHITE),(["C","G","H","D"],ORANGE),(["D","H","I","J","E"],DARK)]
def wing_t(x): k=min(max((x-0.17)/0.55,0),1); return 0.080+(0.040-0.080)*k
def wing_zc(x): return 0.012*min(max((x-0.17)/0.55,0),1)
def wing_top(x): return wing_zc(x)+wing_t(x)/2

def make_wings(mats, lv):
    mb=MB(); W=WING_L[lv]; keysW=list(W); idx={k:i for i,k in enumerate(keysW)}; n=len(keysW)
    for k in keysW: x,y=W[k]; mb.v((x,y,wing_top(x)))
    for k in keysW: x,y=W[k]; mb.v((x,y,wing_zc(x)-wing_t(x)/2))
    edges={}
    for pts,c in WPOLY:
        ii=[idx[p] for p in pts]
        mb.face(ii,c); mb.face([i+n for i in reversed(ii)],GREY if c==WHITE else c)
        for a,b2 in zip(ii,ii[1:]+ii[:1]): edges.setdefault(tuple(sorted((a,b2))),[]).append((a,b2,c))
    for key,lst in edges.items():
        if len(lst)==1:
            a,b2,c=lst[0]; mb.face((b2,a,a+n,b2+n),BROWN if c==ORANGE else (METAL if c==WHITE else c))
    # shoulder fairings
    ft={1:1.0,2:1.06,3:1.15}[lv]
    hr=[]
    for y,top,x1 in ((0.20,0.060,0.30),(0.08,0.088,0.40),(-0.12,0.082,0.42),(-0.30,0.046,0.36)):
        top*=ft; hr.append([Vector((0.17,y,0.015)),Vector((0.235,y,top)),Vector((0.30,y,top*0.94)),Vector((x1-0.035,y,top*0.62)),Vector((x1,y,wing_top(x1)-0.004))])
    b=mb.loft(hr,lambda a,i:WHITE)
    mb.face((b,b+1,b+2,b+3,b+4),DARK); l=b+15; mb.face((l+4,l+3,l+2,l+1,l),GREY)
    zl=0.088*ft
    mb.quad([(0.245,0.04,zl+0.0015),(0.295,0.04,zl*0.94+0.0015+0.002),(0.295,-0.06,zl*0.94+0.001),(0.245,-0.06,zl+0.001)],LIGHT)
    def wq(pts,c,lift=0.003): mb.quad([(x,y,wing_top(x)+lift) for x,y in pts],c)
    wq([(0.40,-0.16),(0.46,-0.22),(0.46,-0.27),(0.40,-0.21)],ORANGE)
    wq([(0.46,-0.22),(0.53,-0.29),(0.53,-0.34),(0.46,-0.27)],ORANGE)
    xl=W["C"][0]-0.055
    wq([(xl,-0.20),(xl+0.01,-0.20),(xl+0.01,-0.60),(xl,-0.60)],DARK)
    wq([(0.30,-0.50),(xl,-0.53),(xl,-0.54),(0.30,-0.51)],DARK)
    if lv>=2:
        # wingtip fins (vertical, canted out) on the orange band
        hx=W["H"][0]-0.03; zb=wing_top(hx)-0.004; hgt={2:0.13,3:0.19}[lv]; ln={2:0.0,3:0.04}[lv]
        fin=[(-0.30-ln,zb),(-0.62,zb),(-0.68-ln,zb+hgt),(-0.55-ln,zb+hgt)]
        mb.vfin(hx,fin,0.022,WHITE,lambda i: ORANGE if i==3 else (DARK if i==2 else WHITE),lean=0.18)
        tl=hx+0.012+0.18*hgt
        mb.quad([(tl-0.18*0.03,-0.56-ln,zb+hgt-0.03),(tl,-0.555-ln,zb+hgt),(tl,-0.66-ln,zb+hgt),(tl-0.18*0.03,-0.645-ln,zb+hgt-0.03)],LIGHT)
        # leading-edge cyan running light near the tip
        cx,cy=W["C"]; gx,gy=W["G"]
        mb.quad([(cx+0.005,cy-0.01,wing_top(cx)+0.004),(gx-0.01,gy-0.002,wing_top(gx)+0.004),(gx-0.03,gy-0.03,wing_top(gx)+0.004),(cx-0.012,cy-0.035,wing_top(cx)+0.004)],LIGHT)
        # inner orange panel
        wq([(0.36,-0.40),(0.50,-0.40),(0.50,-0.46),(0.36,-0.46)],ORANGE)
    if lv>=3:
        # extra inner fins near the trailing edge + leading-edge light strip
        ix=0.47; zb=wing_top(ix)-0.004
        fin=[(-0.46,zb),(-0.64,zb),(-0.69,zb+0.085),(-0.60,zb+0.085)]
        mb.vfin(ix,fin,0.018,WHITE,lambda i: ORANGE if i==3 else (DARK if i==2 else WHITE),lean=0.0)
        bx,by=W["B"]
        mb.quad([(bx+0.01,by-0.012,wing_top(bx)+0.004),(cx-0.02,cy+0.01,wing_top(cx)+0.004),(cx-0.035,cy-0.012,wing_top(cx)+0.004),(bx-0.006,by-0.034,wing_top(bx)+0.004)],LIGHT)
    return build(PART_OBJ["wings"],f"wings_L{lv}_mesh",mb,mats,SOCK["wings"],bevel=0.010), {}

MAKERS={"head":make_head,"body":make_body,"wings":make_wings,"engine":make_engine}

# ---------------- scene ----------------
def build_ship(levels):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    os.makedirs(SRC,exist_ok=True)
    mats=make_materials(); P={}; EM={}
    for k in ("body","head","wings","engine"):
        P[k],EM[k]=MAKERS[k](mats,levels[k])
    body=P["body"]; bpy.context.view_layer.update()
    for k in ("head","wings","engine"):
        s=empty(f"Socket_{k.capitalize()}",SOCK[k],body,0.08,"ARROWS")
        P[k].parent=s; P[k].matrix_parent_inverse=Matrix.Identity(4); P[k].location=(0,0,0)
    for name,loc in HP.items(): empty(name,loc,body,0.07)
    bpy.context.view_layer.update()
    for k in ("head","engine"):
        for name,loc in EM[k].items(): empty(name,loc,P[k])
    bpy.context.view_layer.update()
    return P

def tri_count(ob):
    dg=bpy.context.evaluated_depsgraph_get(); ev=ob.evaluated_get(dg); m=ev.to_mesh()
    m.calc_loop_triangles(); n=len(m.loop_triangles); ev.to_mesh_clear(); return n

def world_tris(ob):
    dg=bpy.context.evaluated_depsgraph_get(); ev=ob.evaluated_get(dg); m=ev.to_mesh(); m.calc_loop_triangles()
    mw=ob.matrix_world; V=[mw@v.co for v in m.vertices]; T=[tuple(t.vertices) for t in m.loop_triangles]
    ev.to_mesh_clear(); return V,T

def checks(P, label=""):
    G={k:world_tris(o) for k,o in P.items()}
    for name,loc in list(HP.items())+[("Hardpoint_Top(reserved)",HP_TOP_RESERVED)]:
        best=(9,"")
        for k,(V,T) in G.items():
            if name=="Hardpoint_Top(reserved)" and k=="body": continue  # body spine is the mount surface
            for v in V: best=min(best,((v-Vector(loc)).length,k))
        lim=HP_TOP_KEEPOUT if "Top" in name else HP_KEEPOUT
        print(f"KEEPOUT {label} {name}: {best[0]:.3f} m ({best[1]}) {'OK' if best[0]>=lim else 'VIOLATION'}")
    # body's own raised geometry near the reserved top spot
    V,_=G["body"]; d=min((v-Vector(HP_TOP_RESERVED)).length for v in V)
    print(f"KEEPOUT {label} Hardpoint_Top vs body: {d:.3f} m (spine plate surface is the mount)")
    if "--clip-report" in ARGS:
        trees={k:BVHTree.FromPolygons(V,T) for k,(V,T) in G.items()}
        ks=list(P)
        for a in range(len(ks)):
            for b in range(a+1,len(ks)):
                n=len(trees[ks[a]].overlap(trees[ks[b]]))
                print(f"OVERLAP {label} {ks[a]}x{ks[b]}: {n}")

# ---------------- render ----------------
def setup_render(res=1024):
    s=bpy.context.scene; s.render.engine="BLENDER_EEVEE"
    s.render.resolution_x=s.render.resolution_y=res; s.eevee.taa_render_samples=32
    s.view_settings.view_transform="Standard"; s.render.film_transparent=False
    w=bpy.data.worlds.new("space"); s.world=w; w.use_nodes=True; nt=w.node_tree
    bg=nt.nodes["Background"]
    tc=nt.nodes.new("ShaderNodeTexCoord"); vor=nt.nodes.new("ShaderNodeTexVoronoi"); vor.inputs["Scale"].default_value=140
    nt.links.new(tc.outputs["Generated"],vor.inputs["Vector"])
    cr=nt.nodes.new("ShaderNodeValToRGB"); cr.color_ramp.elements[0].color=(1,1,1,1)
    cr.color_ramp.elements[1].position=0.035; cr.color_ramp.elements[1].color=(0,0,0,1)
    nt.links.new(vor.outputs["Distance"],cr.inputs[0])
    mix=nt.nodes.new("ShaderNodeMix"); mix.data_type="RGBA"; mix.inputs["A"].default_value=(0.012,0.018,0.045,1); mix.inputs["B"].default_value=(0.55,0.65,0.9,1)
    mul=nt.nodes.new("ShaderNodeMath"); mul.operation="MULTIPLY"; mul.inputs[1].default_value=0.6
    nt.links.new(cr.outputs["Color"],mul.inputs[0]); nt.links.new(mul.outputs[0],mix.inputs["Factor"])
    lp=nt.nodes.new("ShaderNodeLightPath"); mx2=nt.nodes.new("ShaderNodeMix"); mx2.data_type="RGBA"; mx2.inputs["A"].default_value=(0.012,0.018,0.045,1)
    nt.links.new(lp.outputs["Is Camera Ray"],mx2.inputs["Factor"]); nt.links.new(mix.outputs["Result"],mx2.inputs["B"])
    nt.links.new(mx2.outputs["Result"],bg.inputs[0])
    def sun(name,rot,col,en):
        l=bpy.data.lights.new(name,"SUN"); l.color=col; l.energy=en; l.angle=math.radians(10)
        o=bpy.data.objects.new(name,l); o.rotation_euler=[math.radians(a) for a in rot]; s.collection.objects.link(o)
    sun("Key",(35,-20,30),(1,0.96,0.9),3.0); sun("Rim",(-115,0,170),(0.45,0.8,1.0),3.0); sun("Fill",(60,40,-140),(0.6,0.65,1.0),0.9)
    s.render.use_freestyle=True; s.render.line_thickness_mode="ABSOLUTE"
    fs=s.view_layers[0].freestyle_settings
    ls=fs.linesets[0] if len(fs.linesets) else fs.linesets.new("Outline")
    if ls.linestyle is None: ls.linestyle=bpy.data.linestyles.new("Outline")
    ls.select_by_visibility=True; ls.select_silhouette=True; ls.select_border=False; ls.select_crease=True
    ls.linestyle.color=(0.05,0.06,0.11); fs.crease_angle=math.radians(140)
    set_res(res)

def set_res(res):
    s=bpy.context.scene; s.render.resolution_x=s.render.resolution_y=res
    s.render.line_thickness=1.5*res/1024; s.view_layers[0].freestyle_settings.linesets[0].linestyle.thickness=1.5*res/1024

def cam(name,loc,target,ortho=None,lens=60):
    c=bpy.data.cameras.new(name)
    if ortho: c.type="ORTHO"; c.ortho_scale=ortho
    else: c.lens=lens
    o=bpy.data.objects.new(name,c); bpy.context.scene.collection.objects.link(o); o.location=loc
    o.rotation_euler=(Vector(target)-Vector(loc)).to_track_quat("-Z","Y").to_euler(); return o

def render(camobj,path):
    s=bpy.context.scene; s.camera=camobj; s.render.filepath=path
    bpy.ops.render.render(write_still=True); print("RENDERED",path)

def orbit(az,el,dist,target=(0,-0.05,0)):
    a=math.radians(az); e=math.radians(el)
    return Vector(target)+Vector((-math.sin(a)*math.cos(e), -math.cos(a)*math.cos(e), math.sin(e)))*dist

def ship_views(P, prefix, views=("top","34","ingame"), res=1024):
    set_res(res)
    if "top" in views: render(cam("CamTop",(0,-0.16,6),(0,-0.16,0),ortho=2.6),f"{prefix}_top.png")
    if "34" in views: render(cam("Cam34",orbit(150,36,3.25,(0,-0.10,0)),(0,-0.10,0),lens=58),f"{prefix}_34.png")
    if "ingame" in views:
        P["body"].rotation_euler.z=math.radians(-32)
        render(cam("CamGame",(0,-2.3,5.7),(0,0,0),lens=78),f"{prefix}_ingame.png")
        P["body"].rotation_euler.z=0

def parts_table(res=512):
    for lv in (1,2,3):
        P=build_ship({k:lv for k in PARTS}); setup_render(res)
        for k,ob in P.items():
            for o in P.values(): o.hide_render = (o is not ob)
            bpy.context.view_layer.update()
            V,_=world_tris(ob); lo=Vector((min(v.x for v in V),min(v.y for v in V),min(v.z for v in V)))
            hi=Vector((max(v.x for v in V),max(v.y for v in V),max(v.z for v in V))); c=(lo+hi)/2
            sc=max((hi-lo).x,(hi-lo).y)*1.25
            render(cam(f"C_{k}",orbit(150,40,6,c),c,ortho=sc),f"{RND}/parts/{k}_L{lv}.png")

# ---------------- export ----------------
def export_level(P, lv):
    os.makedirs(OUT,exist_ok=True); os.makedirs(PRV,exist_ok=True)
    def sel(objs):
        bpy.ops.object.select_all(action="DESELECT")
        for o in objs: o.select_set(True)
    kw=dict(export_format="GLB",use_selection=True,export_apply=True,export_yup=True,export_cameras=False,export_lights=False,export_extras=False)
    for key,ob in P.items():
        par=ob.parent; ob.parent=None; ob.location=(0,0,0)
        sel([ob]+[c for c in ob.children if c.type=="EMPTY"])
        p=f"{OUT}/{key}_L{lv}.glb"; bpy.ops.export_scene.gltf(filepath=p,**kw); print("EXPORTED",p)
        if par: ob.parent=par; ob.matrix_parent_inverse=Matrix.Identity(4); ob.location=(0,0,0)
    bpy.context.view_layer.update()
    sel([o for o in bpy.context.scene.objects if o.type in ("MESH","EMPTY")])
    bpy.ops.export_scene.gltf(filepath=f"{PRV}/{HULL}_L{lv}_preview.glb",**kw)

def export_collision(P):
    kw=dict(export_format="GLB",use_selection=True,export_apply=True,export_yup=True,export_cameras=False,export_lights=False,export_materials="NONE")
    bm=bmesh.new()
    for o in P.values():
        V,T=world_tris(o)
        for v in V: bm.verts.new(v)
    bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=0.001)
    r=bmesh.ops.convex_hull(bm,input=bm.verts)
    dead={g for g in r["geom_interior"]+r["geom_unused"] if isinstance(g,bmesh.types.BMVert)}
    bmesh.ops.delete(bm,geom=list(dead),context="VERTS")
    bmesh.ops.dissolve_limit(bm,angle_limit=math.radians(5),verts=bm.verts,edges=bm.edges); bmesh.ops.triangulate(bm,faces=bm.faces)
    me=bpy.data.meshes.new(f"{HULL}_collision_mesh"); bm.to_mesh(me); bm.free()
    co=bpy.data.objects.new(f"{HULL}_collision",me); bpy.context.scene.collection.objects.link(co)
    bpy.ops.object.select_all(action="DESELECT"); co.select_set(True)
    bpy.ops.export_scene.gltf(filepath=f"{OUT}/{HULL}_collision.glb",**kw)
    print("COLLISION tris",len(me.polygons)); bpy.data.objects.remove(co)

def report_tris(P,label):
    tot=0
    for k in PARTS:
        n=tri_count(P[k]); tot+=n; print(f"TRIS {label} {k}: {n}")
    print(f"TRIS {label} total: {tot}")

def main():
    os.makedirs(RND,exist_ok=True)
    if "--export" in ARGS and "PS_PREVIEWS" not in os.environ and os.path.isdir(os.path.join(ROOT,".git")):
        print("NOTE: running inside the repo; set PS_PREVIEWS/PS_RENDERS outside the repo to keep previews out of git")
    if "--export" in ARGS:
        for lv in (1,2,3):
            P=build_ship({k:lv for k in PARTS}); report_tris(P,f"L{lv}"); checks(P,f"L{lv}")
            bpy.ops.file.pack_all()
            bpy.ops.wm.save_as_mainfile(filepath=f"{SRC}/{HULL}_L{lv}.blend"); export_level(P,lv)
        export_collision(P)   # all-L3 = largest envelope (P is the L3 build)
    if "--collision" in ARGS:
        export_collision(build_ship({k:3 for k in PARTS}))
    if arg("--render-level"):
        lv=int(arg("--render-level")); P=build_ship({k:lv for k in PARTS}); setup_render()
        ship_views(P,f"{RND}/{arg('--tag',f'starter_L{lv}')}")
    if arg("--combo"):
        h,b,w,e=[int(x) for x in arg("--combo").split(",")]
        P=build_ship({"head":h,"body":b,"wings":w,"engine":e}); lab=f"H{h}B{b}W{w}E{e}"
        report_tris(P,lab); checks(P,lab)
        if "--norender" not in ARGS:
            setup_render(); ship_views(P,f"{RND}/combos/{arg('--tag',lab)}",views=("top","34"),res=640)
    if "--parts-table" in ARGS: parts_table()
    if arg("--turntable"):
        lv=int(arg("--turntable")); P=build_ship({k:lv for k in PARTS}); setup_render(512)
        os.makedirs(f"{RND}/turntable",exist_ok=True); c=cam("CamTT",(0,0,1),(0,0,0),lens=58)
        for k in range(24):
            c.location=orbit(k*15,32,3.4); c.rotation_euler=(Vector((0,-0.05,0))-c.location).to_track_quat("-Z","Y").to_euler()
            render(c,f"{RND}/turntable/starter_L{lv}_tt_{k:02d}.png")

main()
