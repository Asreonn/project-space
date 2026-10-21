"""Preview renders for the MVP environment assets. Imports the EXPORTED GLBs (so renders double as
an export check) plus the starter ship L1 preview GLB for scale.

blender -b -P env_renders.py -- asteroids|sockets|pickups|stations|mock|all [--res 1600] [--tag v2]
Output: <ROOT>/renders/<category>/*.png and *_labels.json (pixel positions for annotate step)
"""
import bpy, sys, os, math, json
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
HERE=os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0,HERE)
import ps_common as C
ARGS=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
ROOT=os.environ.get("PS_ROOT") or os.path.abspath(os.path.join(HERE,"..","..",".."))
A=f"{ROOT}/assets/models"; RND=os.environ.get("PS_RENDERS") or f"{ROOT}/renders"
SHIP=f"{ROOT}/previews/starter_shuttle_01_L1_preview.glb"
RES=int(ARGS[ARGS.index("--res")+1]) if "--res" in ARGS else 1600
TAG=("_"+ARGS[ARGS.index("--tag")+1]) if "--tag" in ARGS else ""

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True); C.setup_render(RES)

def imp(path, loc=(0,0,0), rotz=0.0, scale=1.0):
    before=set(bpy.data.objects); bpy.ops.import_scene.gltf(filepath=path)
    new=[o for o in bpy.data.objects if o not in before]
    for o in new:
        if o.type=="EMPTY": o.hide_render=True
    roots=[o for o in new if o.parent is None]
    for r in roots: r.location=loc; r.rotation_euler=(0,0,rotz); r.scale=(scale,)*3
    return roots[0]

def ship(loc=(0,0,0), rotz=0.0):
    r=imp(SHIP,loc,rotz); return r

def labels(camobj, items, path):
    s=bpy.context.scene; bpy.context.view_layer.update(); out=[]
    for text,co in items:
        p=world_to_camera_view(s,camobj,Vector(co)); out.append([text,p.x,1-p.y])
    json.dump({"res":[s.render.resolution_x,s.render.resolution_y],"labels":out},open(path.replace(".png","_labels.json"),"w"))

def shot(camobj, path, items=None):
    if items: labels(camobj,items,path)
    C.render(camobj,path)

ROCKS=[f"asteroid_{s}_{n:02d}" for s in "lms" for n in (1,2,3)]
ALL_AST=ROCKS+["asteroid_ore_m_01","asteroid_ore_l_01","asteroid_chunk_01","asteroid_chunk_02","asteroid_chunk_03"]
HALF={"l":4.6,"m":3.0,"s":1.4}
def lineup():
    """rows: L (y=0), M (y=-9.5), S (y=-15) with ship, ore + chunks (y=-22.5)"""
    rows=[("l",0.0,10.0),("m",-9.5,6.4),("s",-15.0,3.2)]; items=[]
    for s,y,dx in rows:
        for i,n in enumerate((1,2,3)):
            name=f"asteroid_{s}_{n:02d}"; x=(i-1)*dx; imp(f"{A}/asteroids/{name}.glb",(x,y,0))
            items.append((name,(x,y-HALF[s]-0.2-(0.9 if s=="s" and i==1 else 0),0)))
    ship((6.6,-15.0,0)); items.append(("ship L1 (1.84 m)",(6.6,-16.4,0)))
    imp(f"{A}/asteroids/asteroid_ore_l_01.glb",(-6.5,-22.5,0)); items.append(("asteroid_ore_l_01",(-6.5,-26.6,0)))
    imp(f"{A}/asteroids/asteroid_ore_m_01.glb",(1.0,-22.5,0)); items.append(("asteroid_ore_m_01",(1.0,-25.6,0)))
    for i,n in enumerate((1,2,3)):
        x=5.2+i*1.6; imp(f"{A}/asteroids/asteroid_chunk_{n:02d}.glb",(x,-22.5,0),rotz=0.6*i)
    items.append(("chunk_01..03",(6.8,-23.8,0)))
    return items

def r_asteroids():
    reset(); items=lineup(); d=f"{RND}/asteroids"; c=Vector((0,-11.3,0))
    C.set_res(RES,int(RES*0.86))
    shot(C.cam("Top",c+Vector((0,0,60)),c,ortho=33),f"{d}/asteroids_lineup_top{TAG}.png",items)
    shot(C.cam("Game",c+Vector((0,-24,58)),c,lens=50),f"{d}/asteroids_lineup_ingame{TAG}.png",items)
    shot(C.cam("Q34",c+Vector((24,-34,24)),c+Vector((0,-1.5,-1)),lens=50),f"{d}/asteroids_lineup_34{TAG}.png",items)

def r_each():
    """per asset: asset + ship L1 side by side, top-down and in-game angle (scale check)."""
    d=f"{RND}/asteroids/each"
    for n in ALL_AST:
        reset(); root=imp(f"{A}/asteroids/{n}.glb"); bpy.context.view_layer.update()
        hx=max(root.dimensions.x,root.dimensions.y)/2 if root.type=="MESH" else 1.0
        sx=hx+1.6; ship((sx,0,0)); c=Vector(((sx+1.0-hx)/2,0,0)); w=hx+sx+1.0+1.2
        C.set_res(int(RES*0.42),int(RES*0.6))
        it=[(n,(0,-hx*0.75-0.35,0)),("ship 1.84 m",(sx,-1.25,0))]
        shot(C.cam("Top",c+Vector((0,0,40)),c,ortho=w*1.12),f"{d}/{n}_top{TAG}.png",it)
        dist=w*1.15; shot(C.cam("Game",c+Vector((0,-dist*0.38,dist*0.94)),c,lens=35),f"{d}/{n}_ingame{TAG}.png",it)

def r_scale():
    """side elevation: ship next to S / M / L / ore / chunks on one ground line, 1 m grid."""
    reset(); d=f"{RND}/asteroids"; items=[]; x=0.0
    seq=[("ship",None),("asteroid_chunk_03",0.65),("asteroid_s_02",1.05),("asteroid_m_02",2.5),("asteroid_l_02",4.0),("asteroid_ore_l_01",4.0)]
    for n,r in seq:
        if n=="ship": ship((x,0,0)); items.append(("ship 1.84 m",(x+0.3,0,1.3))); x+=1.0+1.2; continue
        x+=r; root=imp(f"{A}/asteroids/{n}.glb",(x,0,0)); bpy.context.view_layer.update()
        items.append((f"{n}  {root.dimensions.x:.1f} m",(x,0,(-r-0.8) if len(items)%2 else (r+0.9)))); x+=r+1.2
    C.set_res(int(RES*0.42),RES); c=Vector((x/2,0,-0.5))
    shot(C.cam("Side",c+Vector((0,-80,0)),c,ortho=x+2),f"{d}/asteroids_scale_vs_ship{TAG}.png",items)

def r_sockets():
    """L/M rocks with a blue crystal pickup placed on every OreSocket / VeinSocket (node placement preview)."""
    reset(); items=[]
    for i,name in enumerate(["asteroid_l_01","asteroid_l_02","asteroid_l_03","asteroid_ore_l_01"]):
        x=(i-1.5)*10.5; root=imp(f"{A}/asteroids/{name}.glb",(x,0,0)); bpy.context.view_layer.update()
        items.append((name,(x,-4.8,0)))
        for e in root.children:
            if e.name.split(".")[0].startswith(("OreSocket","VeinSocket")):
                p=imp(f"{A}/pickups/pickup_ore_common_solid.glb" if e.name.startswith("Ore") else f"{A}/pickups/pickup_crystal_blue_solid.glb",scale=3.0)
                p.matrix_world=e.matrix_world@__import__("mathutils").Matrix.Scale(3.0,4)
    C.set_res(int(RES*0.45),RES); d=f"{RND}/asteroids"; c=Vector((0,0,0))
    shot(C.cam("Top",(0,0,60),c,ortho=44),f"{d}/asteroids_sockets_top{TAG}.png",items)
    shot(C.cam("Q34",(14,-46,26),(0,0,-0.5),lens=45),f"{d}/asteroids_sockets_34{TAG}.png",items)

def r_pickups():
    reset(); items=[]; d=f"{RND}/pickups"
    ship((0,0,0),rotz=0.0); items.append(("ship L1",(0,-1.15,0)))
    imp(f"{A}/pickups/pickup_ore_common_solid.glb",(1.6,0.3,0)); items.append(("pickup_ore_common_solid",(1.6,-0.15,0)))
    imp(f"{A}/pickups/pickup_crystal_blue_solid.glb",(2.6,-0.4,0)); items.append(("pickup_crystal_blue_solid",(2.6,-0.85,0)))
    for i,n in enumerate((1,2)):
        imp(f"{A}/asteroids/asteroid_chunk_{n:02d}.glb",(-1.9+i*0.2,-0.2+i*1.0,0),rotz=i)
    C.set_res(int(RES*0.62),RES); c=Vector((0.6,0,0))
    shot(C.cam("Top",c+Vector((0,0,20)),c,ortho=6.2),f"{d}/pickups_top{TAG}.png",items)
    shot(C.cam("Game",c+Vector((0,-2.6,6.4)),c,lens=40),f"{d}/pickups_ingame{TAG}.png",items)
    C.set_res(RES//2)
    for n in ("pickup_ore_common_solid","pickup_crystal_blue_solid"):
        for o in list(bpy.data.objects):
            if o.type!="LIGHT" and o.type!="CAMERA": o.hide_render=True
        root=imp(f"{A}/pickups/{n}.glb",(20,0,0))
        shot(C.cam("Close",(21.0,-1.1,0.75),(20,0,0),lens=60),f"{d}/{n}_closeup{TAG}.png")
        root.hide_render=True

def r_stations():
    reset(); d=f"{RND}/stations"
    imp(f"{A}/stations/beacon_transfer_01.glb"); ship((0,3.9,0))
    ship((-4.0,-9.0,0),rotz=math.radians(-25))
    C.set_res(RES)
    shot(C.cam("Top",(0,0,60),(0,0,0),ortho=17),f"{d}/beacon_transfer_01_top{TAG}.png",[("Dock_0 (ship docked)",(0,5.3,0)),("Dock_1",(0,-5.6,0))])
    shot(C.cam("Game",(0,-9.5,23),(0,-0.8,0),lens=40),f"{d}/beacon_transfer_01_ingame{TAG}.png")
    shot(C.cam("Q34",(13,-15,9),(0,0,-0.3),lens=40),f"{d}/beacon_transfer_01_34{TAG}.png")

def r_mock():
    """gameplay mock: camera ~30 m up, ~22 deg tilt like the ship ingame cam."""
    reset(); d=f"{RND}/mock"
    imp(f"{A}/stations/beacon_transfer_01.glb",(-11,7,0))
    S=ship((0.5,-1.0,0),rotz=math.radians(35))
    rocks=[("asteroid_l_02",(9,6,0),0.4),("asteroid_ore_l_01",(12,-7,0),2.0),("asteroid_m_01",(-4,-9,0),1.0),("asteroid_m_03",(3,9.5,0),2.5),
           ("asteroid_s_01",(6,-1,0),0.0),("asteroid_s_02",(-6,1.5,0),1.2),("asteroid_s_03",(15.5,1.5,0),0.7),("asteroid_l_03",(-15,-8,0),0.3),
           ("asteroid_m_02",(18,9,0),1.7),("asteroid_ore_m_01",(-1,15,0),0.5),("asteroid_s_02",(-18,15,0),2.2)]
    for n,p,r in rocks: imp(f"{A}/asteroids/{n}.glb",p,rotz=r)
    for i,(n,p) in enumerate([("asteroid_chunk_01",(8.3,-3.6)),("asteroid_chunk_02",(9.4,-5.2)),("asteroid_chunk_03",(7.2,-5.6)),("asteroid_chunk_01",(10.2,-3.4))]):
        imp(f"{A}/asteroids/{n}.glb",(*p,0),rotz=i*1.3)
    for i,p in enumerate([(4.6,-3.2),(5.8,-4.4),(3.6,-4.6),(7.0,-2.6)]):
        imp(f"{A}/pickups/pickup_ore_common_solid.glb",(*p,0),rotz=i*0.9)
    for i,p in enumerate([(2.6,-2.4),(-1.8,10.5)]):
        imp(f"{A}/pickups/pickup_crystal_blue_solid.glb",(*p,0),rotz=i)
    C.set_res(RES,int(RES*16/9))
    tgt=Vector((1.5,1.0,0))
    shot(C.cam("Game",tgt+Vector((0,-11.5,28.5)),tgt,lens=24),f"{d}/mock_ingame{TAG}.png")
    shot(C.cam("Top",tgt+Vector((0,0,60)),tgt,ortho=40),f"{d}/mock_top{TAG}.png")
    t2=Vector((2.5,-1.5,0))   # closer framing matching the reference gameplay shot (ship ~1/8 of the width)
    shot(C.cam("GameClose",t2+Vector((0,-6.0,14.5)),t2,lens=24),f"{d}/mock_ingame_close{TAG}.png")

mode=ARGS[0] if ARGS else "all"
for m in (["asteroids","each","scale","sockets","pickups","stations","mock"] if mode=="all" else mode.split(",")):
    globals()["r_"+m]()
