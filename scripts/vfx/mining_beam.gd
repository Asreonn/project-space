class_name MiningBeam
extends Node3D
## Mining laser beam: HDR scrolling core + soft sheath from an origin to a
## target point, a hot spot and sparks at the hit point, a small muzzle glow.
## Lives in world space (top_level) so it can sit anywhere in the tree.
##   beam.start(origin_node_or_vector3, target_point)
##   beam.set_target(point)            # every frame while mining
##   beam.stop()                       # fades out in fade_time
## Budget: 3 quads + max 24 spark particles + 10 ember particles.

signal started
signal stopped

@export var width: float = 0.32
@export var fade_time: float = 0.08
@export var color_core: Color = Color(1.0, 0.95, 0.85)
@export var color_glow: Color = Color(1.0, 0.55, 0.25)
## Optional: follow this node as the origin (e.g. FX_MiningOrigin).
@export var origin_node: Node3D

var active: bool = false
var origin_point: Vector3 = Vector3.ZERO
var target_point: Vector3 = Vector3.ZERO
## Set false when the beam misses (no asteroid hit): no sparks, no hot spot.
var hitting: bool = true

var _fade: float = 0.0
var _time: float = 0.0

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


## origin: a Node3D to follow or a fixed Vector3. target: world point.
func start(origin: Variant, target: Vector3) -> void:
	if origin is Node3D:
		origin_node = origin
	elif origin is Vector3:
		origin_node = null
		origin_point = origin
	target_point = target
	if not active:
		active = true
		started.emit()
	_set_visible(true)
	_sparks.emitting = hitting
	_embers.emitting = hitting


func set_target(target: Vector3, is_hitting: bool = true) -> void:
	target_point = target
	if is_hitting != hitting:
		hitting = is_hitting
		_sparks.emitting = active and hitting
		_embers.emitting = active and hitting


func set_origin(origin: Variant) -> void:
	if origin is Node3D:
		origin_node = origin
	elif origin is Vector3:
		origin_node = null
		origin_point = origin


func stop() -> void:
	if not active:
		return
	active = false
	_sparks.emitting = false
	_embers.emitting = false
	stopped.emit()


func apply_colors() -> void:
	_beam_mat.set_shader_parameter(&"color_core", Vector3(color_core.r, color_core.g, color_core.b))
	_beam_mat.set_shader_parameter(&"color_glow", Vector3(color_glow.r, color_glow.g, color_glow.b))


func _process(delta: float) -> void:
	var goal := 1.0 if active else 0.0
	_fade = move_toward(_fade, goal, delta / maxf(fade_time, 0.001))
	_time += delta
	if _fade <= 0.0 and not active:
		_set_visible(false)
		return
	if origin_node != null and is_instance_valid(origin_node):
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
	var impact_scale := (0.55 + 0.1 * sin(_time * 25.0)) * _fade * (1.0 if hitting else 0.0)
	_impact.global_transform = Transform3D(Basis().scaled(Vector3.ONE * maxf(impact_scale, 0.001)), b - dir * 0.03)
	_muzzle.global_transform = Transform3D(Basis().scaled(Vector3.ONE * maxf(0.3 * _fade, 0.001)), a)
	# Sparks spray back towards the shooter, embers drift off the surface.
	var back := -dir
	var sb := Basis.looking_at(back, Vector3.UP if absf(back.y) < 0.99 else Vector3.FORWARD)
	_sparks.global_transform = Transform3D(sb, b)
	_embers.global_transform = Transform3D(Basis.IDENTITY, b)


func _set_visible(on: bool) -> void:
	_beam.visible = on
	_impact.visible = on
	_muzzle.visible = on
