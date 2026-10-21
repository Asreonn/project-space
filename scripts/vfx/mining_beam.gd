class_name MiningBeam
extends Node3D
## Mining beam: cyan HDR core + warm sheath drawn EXACTLY from an origin to an
## end point (no length of its own; range is gameplay's), a heat glow at the
## contact point with a short flash when contact starts, sparks + embers while
## hitting, and a small cyan muzzle glow at the origin.
## Lives in world space (top_level). Normally driven by VfxDirector:
##   beam.start(origin_node_or_vector3, end_point)
##   beam.set_end(point, is_hitting, heat)   # every frame while firing
##   beam.stop()                             # fades out in fade_time
## Budget: 3 quads + max 24 spark particles + 10 ember particles.

signal started
signal stopped

## Beam quad width in metres (core is core_width of this, see the shader).
@export var width: float = 0.5
@export var fade_time: float = 0.08
@export var color_core: Color = Color(0.15, 0.75, 1.0)
@export var color_glow: Color = Color(1.0, 0.52, 0.22)
## Heat glow size at the contact point (m) at heat 0 and heat 1.
@export var impact_size_cold: float = 0.55
@export var impact_size_hot: float = 0.85
## Optional: follow this node as the origin (FX_MiningOrigin).
@export var origin_node: Node3D

var active: bool = false
var origin_point: Vector3 = Vector3.ZERO
var target_point: Vector3 = Vector3.ZERO
## False when the beam reaches max range without touching an asteroid.
var hitting: bool = false
## 0..1, e.g. 1 - asteroid hp_ratio: hotter contact glow.
var heat: float = 0.0

var _fade: float = 0.0
var _time: float = 0.0
var _flash: float = 0.0

@onready var _beam: MeshInstance3D = $Beam
@onready var _impact: MeshInstance3D = $Impact
@onready var _muzzle: MeshInstance3D = $Muzzle
@onready var _sparks: GPUParticles3D = $Sparks
@onready var _embers: GPUParticles3D = $Embers
@onready var _beam_mat: ShaderMaterial = _beam.material_override as ShaderMaterial


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	apply_colors()
	_set_visible(false)


## origin: a Node3D to follow (FX_MiningOrigin) or a fixed Vector3. end: world point.
func start(origin: Variant, end: Vector3) -> void:
	set_origin(origin)
	target_point = end
	if not active:
		active = true
		started.emit()
	_set_visible(true)
	_update_emitters()


## end: exact beam end point from gameplay (hit point or range end).
func set_end(end: Vector3, is_hitting: bool, new_heat: float = -1.0) -> void:
	target_point = end
	if new_heat >= 0.0:
		heat = clampf(new_heat, 0.0, 1.0)
	if is_hitting != hitting:
		hitting = is_hitting
		if hitting:
			flash()
		_update_emitters()


## Kept for older callers.
func set_target(target: Vector3, is_hitting: bool = true) -> void:
	set_end(target, is_hitting)


func set_origin(origin: Variant) -> void:
	if origin is Node3D:
		origin_node = origin
		origin_point = origin_node.global_position
	elif origin is Vector3:
		origin_node = null
		origin_point = origin


## Short heat flash on the contact point (contact start, big damage ticks).
func flash(strength: float = 1.0) -> void:
	_flash = maxf(_flash, strength)


func stop() -> void:
	if not active:
		return
	active = false
	hitting = false
	_update_emitters()
	stopped.emit()


func apply_colors() -> void:
	_beam_mat.set_shader_parameter(&"color_core", Vector3(color_core.r, color_core.g, color_core.b))
	_beam_mat.set_shader_parameter(&"color_glow", Vector3(color_glow.r, color_glow.g, color_glow.b))


func _process(delta: float) -> void:
	var goal := 1.0 if active else 0.0
	_fade = move_toward(_fade, goal, delta / maxf(fade_time, 0.001))
	_time += delta
	_flash = move_toward(_flash, 0.0, delta / 0.18)
	if _fade <= 0.0 and not active:
		_set_visible(false)
		return
	if origin_node != null and is_instance_valid(origin_node) and origin_node.is_inside_tree():
		origin_point = origin_node.global_position
	_layout()


func _layout() -> void:
	var a := origin_point
	var b := target_point
	var d := b - a
	var length := d.length()
	if length < 0.01:
		return
	var dir := d / length
	var cam := get_viewport().get_camera_3d()
	var to_cam := Vector3.UP
	if cam != null:
		if cam.projection == Camera3D.PROJECTION_ORTHOGONAL:
			to_cam = cam.global_basis.z
		else:
			to_cam = (cam.global_position - (a + b) * 0.5).normalized()
	var side := dir.cross(to_cam)
	if side.length_squared() < 0.0001:
		side = dir.cross(Vector3.FORWARD)
	side = side.normalized()
	var up := side.cross(dir).normalized()
	# PlaneMesh: X = length (UV.x), Z = width (UV.y), Y = normal.
	var beam_basis := Basis(dir * length, up, side * width)
	_beam.global_transform = Transform3D(beam_basis, (a + b) * 0.5)
	_beam_mat.set_shader_parameter(&"beam_length", length)
	_beam_mat.set_shader_parameter(&"fade", _fade)
	var hot := lerpf(impact_size_cold, impact_size_hot, heat)
	var impact_scale := (hot * (1.0 + 0.06 * sin(_time * 9.0)) + _flash * 0.7) * _fade * (1.0 if hitting else 0.0)
	# Pulled towards the camera so the asteroid's own silhouette never hides it.
	_impact.global_transform = Transform3D(Basis().scaled(Vector3.ONE * maxf(impact_scale, 0.001)), b - dir * 0.04 + to_cam * 0.6)
	var muzzle := (0.32 + 0.04 * sin(_time * 5.0)) * _fade
	_muzzle.global_transform = Transform3D(Basis().scaled(Vector3.ONE * maxf(muzzle, 0.001)), a)
	# Sparks spray back towards the shooter, embers drift off the surface.
	var back := -dir
	var sb := Basis.looking_at(back, Vector3.UP if absf(back.y) < 0.99 else Vector3.FORWARD)
	_sparks.global_transform = Transform3D(sb, b)
	_embers.global_transform = Transform3D(Basis.IDENTITY, b)


func _update_emitters() -> void:
	_sparks.emitting = active and hitting
	_embers.emitting = active and hitting


func _set_visible(on: bool) -> void:
	_beam.visible = on
	_impact.visible = on
	_muzzle.visible = on
