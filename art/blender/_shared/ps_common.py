"""Shared helpers for Project Space environment assets (asteroids, pickups, stations).

- One shared 64x64 palette (4x4 cells, 16 px each). Cells 0-10 are identical to the starter
  ship palette (starter_shuttle_01.py), and cells 11-15 add the rock/ore colours. Two materials:
  M_ps_palette (opaque) and M_ps_glow (same base texture plus the emission map).
- Faces are UV'd to the centre of their palette cell. Flat shading uses "soft" custom normals
  (face normal blended with the smooth vertex normal) to fake soft bevels without extra tris.
- glTF export: +Y up (Godot), transforms applied, one root node per asset.
"""
import bpy, bmesh, os, math, random
from mathutils import Vector, Matrix

PAL = {  # cell: (base sRGB, emit sRGB or None)
 0:((0.93,0.91,0.88),None),  1:((0.66,0.69,0.75),None),  2:((0.93,0.50,0.18),None),
 3:((0.60,0.33,0.18),None),  4:((0.11,0.12,0.17),None),  5:((0.30,0.32,0.38),None),
 6:((0.30,0.88,0.97),(0.10,0.55,0.70)), 7:((0.45,0.80,1.00),(0.45,0.80,1.00)),
 8:((0.55,1.00,1.00),(0.55,1.00,1.00)), 9:((0.20,0.40,0.56),None), 10:((0.22,0.24,0.30),None),
 11:((0.62,0.50,0.47),None),  # rock light (warm taupe)
 12:((0.47,0.37,0.37),None),  # rock mid (brown-mauve)
 13:((0.30,0.24,0.27),None),  # rock dark / crater
 14:((0.42,0.33,0.40),None),  # rock mauve (purple tint)
 15:((1.00,0.52,0.14),(1.00,0.38,0.06)),  # ore glow orange
}
WHITE,GREY,ORANGE,BROWN,DARK,METAL,GLASS,GLOW,LIGHT,SPINE,GUN,ROCK_L,ROCK_M,ROCK_D,ROCK_P,ORE = range(16)
EMISSIVE = {GLASS,GLOW,LIGHT,ORE}
CELLS=4; CPX=16
def cell_uv(c): return ((c%CELLS)+0.5)/CELLS, 1-((c//CELLS)+0.5)/CELLS

def make_materials(srcdir):
    os.makedirs(srcdir,exist_ok=True); n=CELLS*CPX; imgs={}
    for key in ("base","emit"):
        im=bpy.data.images.new(f"ps_palette_{key}",n,n,alpha=False); px=[0.0]*(n*n*4)
        for c,(b,e) in PAL.items():
            col=b if key=="base" else (e or (0,0,0)); cx,cy=c%CELLS,CELLS-1-(c//CELLS)
            for y in range(cy*CPX,(cy+1)*CPX):
                for x in range(cx*CPX,(cx+1)*CPX):
                    i=(y*n+x)*4; px[i:i+4]=[*col,1.0]
        im.pixels=px; im.filepath_raw=f"{srcdir}/ps_palette_{key}.png"; im.file_format="PNG"; im.save(); imgs[key]=im
    mats=[]
    for name,glow in (("M_ps_palette",False),("M_ps_glow",True)):
        m=bpy.data.materials.new(name); m.use_nodes=True; nt=m.node_tree; b=nt.nodes["Principled BSDF"]
        b.inputs["Roughness"].default_value=0.6
        t=nt.nodes.new("ShaderNodeTexImage"); t.image=imgs["base"]; t.interpolation="Closest"; nt.links.new(t.outputs["Color"],b.inputs["Base Color"])
        if glow:
            te=nt.nodes.new("ShaderNodeTexImage"); te.image=imgs["emit"]; te.interpolation="Closest"
            nt.links.new(te.outputs["Color"],b.inputs["Emission Color"]); b.inputs["Emission Strength"].default_value=2.5
        mats.append(m)
    return mats

def mesh_from_bm(bm, name, meshname, mats, cells, soft=0.35):
    """bm faces -> object; cells: list per face (same order as bm.faces). soft: normal blend."""
    me=bpy.data.meshes.new(meshname); bm.to_mesh(me); me.update()
    uv=me.uv_layers.new(name="UVMap")
    for m in mats: me.materials.append(m)
    for p,c in zip(me.polygons,cells):
        p.material_index=1 if c in EMISSIVE else 0
        for li in p.loop_indices: uv.data[li].uv=cell_uv(c)
    set_soft_normals(me,soft)
    ob=bpy.data.objects.new(name,me); bpy.context.scene.collection.objects.link(ob); return ob

def set_soft_normals(me, soft, keep_hard=None):
    """per-loop normal = normalize(face*(1-soft) + vertexsmooth*soft). keep_hard: set of poly idx kept flat."""
    me.shade_smooth()
    vn=[Vector() for _ in me.vertices]
    for p in me.polygons:
        for v in p.vertices: vn[v]+=p.normal*p.area
    vn=[v.normalized() if v.length else Vector((0,0,1)) for v in vn]
    ln=[None]*len(me.loops)
    for p in me.polygons:
        s=0 if (keep_hard and p.index in keep_hard) else soft
        for li,v in zip(p.loop_indices,p.vertices): ln[li]=tuple((p.normal*(1-s)+vn[v]*s).normalized())
    me.normals_split_custom_set(ln)

def empty(name, loc, parent=None, normal=None, size=0.25):
    e=bpy.data.objects.new(name,None); e.empty_display_type="SINGLE_ARROW" if normal else "PLAIN_AXES"; e.empty_display_size=size
    bpy.context.scene.collection.objects.link(e)
    if parent: e.parent=parent; e.matrix_parent_inverse=Matrix.Identity(4)
    e.location=loc
    if normal is not None:   # local +Z (Blender) = Godot +Y points along the outward normal
        e.rotation_euler=Vector(normal).to_track_quat("Z","Y").to_euler()
    return e

def tri_count(ob):
    dg=bpy.context.evaluated_depsgraph_get(); ev=ob.evaluated_get(dg); m=ev.to_mesh(); m.calc_loop_triangles()
    n=len(m.loop_triangles); ev.to_mesh_clear(); return n

def world_verts(ob):
    dg=bpy.context.evaluated_depsgraph_get(); ev=ob.evaluated_get(dg); m=ev.to_mesh()
    V=[ob.matrix_world@v.co for v in m.vertices]; ev.to_mesh_clear(); return V

def convex_collision(objs, name, max_angle=6):
    bm=bmesh.new()
    for o in objs:
        for v in world_verts(o): bm.verts.new(v)
    bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=0.002)
    r=bmesh.ops.convex_hull(bm,input=bm.verts)
    dead={g for g in r["geom_interior"]+r["geom_unused"] if isinstance(g,bmesh.types.BMVert)}
    bmesh.ops.delete(bm,geom=list(dead),context="VERTS")
    bmesh.ops.dissolve_limit(bm,angle_limit=math.radians(max_angle),verts=bm.verts,edges=bm.edges); bmesh.ops.triangulate(bm,faces=bm.faces)
    me=bpy.data.meshes.new(name+"_mesh"); bm.to_mesh(me); bm.free()
    co=bpy.data.objects.new(name,me); bpy.context.scene.collection.objects.link(co); return co

def export_glb(objs, path, materials=True):
    os.makedirs(os.path.dirname(path),exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    kw=dict(export_format="GLB",use_selection=True,export_apply=True,export_yup=True,export_cameras=False,export_lights=False,export_extras=False)
    if not materials: kw["export_materials"]="NONE"
    bpy.ops.export_scene.gltf(filepath=path,**kw); print("EXPORTED",path)

def with_children(o):
    out=[o]
    for c in o.children: out+=with_children(c)
    return out

# ---------------- rendering ----------------
def setup_render(res=1024, freestyle=True):
    s=bpy.context.scene; s.render.engine="BLENDER_EEVEE"; s.eevee.taa_render_samples=32
    s.view_settings.view_transform="Standard"
    w=bpy.data.worlds.new("space"); s.world=w; w.use_nodes=True; nt=w.node_tree; bg=nt.nodes["Background"]
    tc=nt.nodes.new("ShaderNodeTexCoord"); vor=nt.nodes.new("ShaderNodeTexVoronoi"); vor.inputs["Scale"].default_value=140
    nt.links.new(tc.outputs["Generated"],vor.inputs["Vector"])
    cr=nt.nodes.new("ShaderNodeValToRGB"); cr.color_ramp.elements[0].color=(1,1,1,1); cr.color_ramp.elements[1].position=0.035; cr.color_ramp.elements[1].color=(0,0,0,1)
    nt.links.new(vor.outputs["Distance"],cr.inputs[0])
    mix=nt.nodes.new("ShaderNodeMix"); mix.data_type="RGBA"; mix.inputs["A"].default_value=(0.016,0.018,0.050,1); mix.inputs["B"].default_value=(0.6,0.65,0.9,1)
    mul=nt.nodes.new("ShaderNodeMath"); mul.operation="MULTIPLY"; mul.inputs[1].default_value=0.6
    nt.links.new(cr.outputs["Color"],mul.inputs[0]); nt.links.new(mul.outputs[0],mix.inputs["Factor"])
    lp=nt.nodes.new("ShaderNodeLightPath"); mx2=nt.nodes.new("ShaderNodeMix"); mx2.data_type="RGBA"; mx2.inputs["A"].default_value=(0.020,0.020,0.045,1)
    nt.links.new(lp.outputs["Is Camera Ray"],mx2.inputs["Factor"]); nt.links.new(mix.outputs["Result"],mx2.inputs["B"]); nt.links.new(mx2.outputs["Result"],bg.inputs[0])
    def sun(name,rot,col,en):
        l=bpy.data.lights.new(name,"SUN"); l.color=col; l.energy=en; l.angle=math.radians(10)
        o=bpy.data.objects.new(name,l); o.rotation_euler=[math.radians(a) for a in rot]; s.collection.objects.link(o)
    sun("Key",(35,-20,30),(1,0.94,0.86),3.0); sun("Rim",(-115,0,170),(0.55,0.75,1.0),2.6); sun("Fill",(60,40,-140),(0.75,0.6,1.0),1.0)
    s.render.use_freestyle=freestyle
    fs=s.view_layers[0].freestyle_settings
    ls=fs.linesets[0] if len(fs.linesets) else fs.linesets.new("Outline")
    if ls.linestyle is None: ls.linestyle=bpy.data.linestyles.new("Outline")
    ls.select_by_visibility=True; ls.select_silhouette=True; ls.select_border=False; ls.select_crease=True
    ls.linestyle.color=(0.06,0.05,0.10); fs.crease_angle=math.radians(120)
    s.render.line_thickness_mode="ABSOLUTE"; set_res(res)

def set_res(res, rx=None):
    s=bpy.context.scene; s.render.resolution_x=rx or res; s.render.resolution_y=res
    s.render.line_thickness=1.4*res/1024; s.view_layers[0].freestyle_settings.linesets[0].linestyle.thickness=1.4*res/1024

def cam(name,loc,target,ortho=None,lens=60):
    c=bpy.data.cameras.new(name); c.clip_end=500
    if ortho: c.type="ORTHO"; c.ortho_scale=ortho
    else: c.lens=lens
    o=bpy.data.objects.new(name,c); bpy.context.scene.collection.objects.link(o); o.location=loc
    o.rotation_euler=(Vector(target)-Vector(loc)).to_track_quat("-Z","Y").to_euler(); return o

def render(camobj,path):
    os.makedirs(os.path.dirname(path),exist_ok=True)
    s=bpy.context.scene; s.camera=camobj; s.render.filepath=path; bpy.ops.render.render(write_still=True); print("RENDERED",path)

def import_ship(path, loc=(0,0,0), rotz=0.0):
    before=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new=[o for o in bpy.data.objects if o not in before]
    roots=[o for o in new if o.parent is None]
    for r in roots: r.location=loc; r.rotation_euler=(0,0,rotz)   # glTF importer converts back to Blender Z-up
    return roots
