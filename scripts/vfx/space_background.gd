class_name SpaceBackground
extends Node3D
## Camera-following space backdrop for the near top-down camera.
## A single unshaded quad (nebula + 2 star layers, parallax in the shader) sits
## `depth` metres below the play plane and always fills the view; an optional
## planet impostor drifts with its own parallax factor.
## Cost: one full-screen opaque quad + one small alpha quad.

@export var palette: SpacePalette:
	set(value):
		palette = value
		if is_node_ready():
			apply_palette()
## Metres below the play plane (Y = 0). Must be inside the camera far plane.
@export var depth: float = 120.0
## Extra coverage so a tilted camera never sees the quad edge.
@export var coverage_margin: float = 1.8
## Cheaper nebula (3 noise octaves, no dust lanes) for low-end GPUs.
@export var low_quality: bool = false:
	set(value):
		low_quality = value
		if is_node_ready():
			_apply_quality()
@export var planet_enabled: bool = true:
	set(value):
		planet_enabled = value
		if is_node_ready():
			_planet.visible = value
## Planet position on the backdrop (world XZ at camera origin).
@export var planet_offset: Vector2 = Vector2(34.0, -20.0)
## Planet diameter in metres at `depth` (screen size grows as depth shrinks).
@export var planet_size: float = 32.0
## 0 = fixed in the world, 1 = fixed on screen.
@export_range(0.0, 1.0) var planet_parallax: float = 0.9

@onready var _sky: MeshInstance3D = $Sky
@onready var _planet: MeshInstance3D = $Planet


func _ready() -> void:
	apply_palette()
	_apply_quality()
	_planet.visible = planet_enabled
	_update(get_viewport().get_camera_3d())


func _process(_delta: float) -> void:
	_update(get_viewport().get_camera_3d())


func apply_palette() -> void:
	if palette == null:
		return
	palette.apply_to_background(_sky.material_override as ShaderMaterial)
	palette.apply_to_planet(_planet.material_override as ShaderMaterial)


func _apply_quality() -> void:
	var mat := _sky.material_override as ShaderMaterial
	mat.set_shader_parameter(&"fbm_octaves", 3 if low_quality else 4)
	mat.set_shader_parameter(&"dust_lanes", not low_quality)


func _update(cam: Camera3D) -> void:
	if cam == null:
		return
	var cp := cam.global_position
	var dist := cp.y + depth
	var h: float
	if cam.projection == Camera3D.PROJECTION_ORTHOGONAL:
		h = cam.size
	else:
		h = 2.0 * dist * tan(deg_to_rad(cam.fov) * 0.5)
	var vp := get_viewport().get_visible_rect().size
	var aspect := vp.x / maxf(vp.y, 1.0)
	var w := h * aspect
	var s := maxf(w, h) * coverage_margin
	# Centre the quad under the point the camera looks at on the backdrop.
	var fwd := -cam.global_basis.z
	var center := Vector3(cp.x, -depth, cp.z)
	if fwd.y < -0.01:
		var t := (-depth - cp.y) / fwd.y
		center = cp + fwd * t
	_sky.global_transform = Transform3D(Basis().scaled(Vector3(s, 1.0, s)), Vector3(center.x, -depth, center.z))
	var sky_mat := _sky.material_override as ShaderMaterial
	sky_mat.set_shader_parameter(&"camera_xz", Vector2(cp.x, cp.z))
	if planet_enabled:
		var pxz := Vector2(cp.x, cp.z) * planet_parallax + planet_offset
		_planet.global_transform = Transform3D(Basis().scaled(Vector3(planet_size, 1.0, planet_size)), Vector3(pxz.x, -depth * 0.8, pxz.y))
