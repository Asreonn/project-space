class_name ModelUtil
## Helpers for modeler GLBs: load with a null fallback, build collision from a
## <name>_collision.glb convex hull, find empties by name or prefix.


## Instanced model, or null when the path is empty / missing / not a scene.
static func instance_model(path: String) -> Node3D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var packed := load(path) as PackedScene
	return packed.instantiate() as Node3D if packed != null else null


## "<dir>/<name>.glb" -> "<dir>/<name>_collision.glb".
static func collision_path_for(model_path: String) -> String:
	if model_path == "":
		return ""
	return model_path.get_basename() + "_collision.glb"


## CollisionShape3D with a convex hull of the first mesh in the collision GLB
## (placed like that mesh relative to the GLB root), or null when missing.
static func convex_collision(collision_glb: String) -> CollisionShape3D:
	var root := instance_model(collision_glb)
	if root == null:
		return null
	var out: CollisionShape3D = null
	for n: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		var shape := mi.mesh.create_convex_shape(true, false)
		if shape == null:
			continue
		out = CollisionShape3D.new()
		out.name = "CollisionShape3D"
		out.shape = shape
		out.transform = relative_transform(mi, root)
		break
	root.free()
	return out


## Empties below root whose name starts with prefix, sorted by name.
static func find_markers(root: Node, prefix: String) -> Array[Node3D]:
	var out: Array[Node3D] = []
	if root == null:
		return out
	for n: Node in root.find_children(prefix + "*", "Node3D", true, false):
		out.append(n as Node3D)
	out.sort_custom(func(a: Node3D, b: Node3D) -> bool: return String(a.name).naturalnocasecmp_to(String(b.name)) < 0)
	return out


## Transform of node relative to root (works before entering the tree).
static func relative_transform(node: Node3D, root: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != root:
		if n is Node3D:
			xf = (n as Node3D).transform * xf
		n = n.get_parent()
	return xf
