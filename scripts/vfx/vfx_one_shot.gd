class_name VfxOneShot
extends Node3D
## Base for pool-friendly one-shot effects (asteroid break, ore collect pop).
## play() restarts every GPUParticles3D child; `finished` fires after `duration`.
## Nothing is spawned at runtime: the scene owns a fixed set of emitters, so a
## pool of N instances caps the particle count at N x scene budget.

signal finished(effect: VfxOneShot)

## Seconds until the effect is considered done (>= longest particle lifetime).
@export var duration: float = 1.6
## Size reference: play(size = reference_size) plays at scale 1.
@export var reference_size: float = 1.0
@export var min_scale: float = 0.5
@export var max_scale: float = 3.0
## Nodes whose material `tint` parameter follows play(color). Paths relative to this node.
@export var tint_targets: Array[NodePath] = []

var playing: bool = false
var _time_left: float = 0.0


func _ready() -> void:
	visible = false
	set_process(false)
	for p: GPUParticles3D in _emitters():
		p.emitting = false


## position: world point. size: same unit as reference_size (e.g. asteroid radius m).
## color: alpha 0 keeps the authored colours.
func play(at: Vector3, size: float = -1.0, color: Color = Color(0, 0, 0, 0)) -> void:
	var s := 1.0
	if size > 0.0:
		s = clampf(size / maxf(reference_size, 0.001), min_scale, max_scale)
	global_position = at
	scale = Vector3.ONE * s
	if color.a > 0.0:
		set_tint(color)
	visible = true
	playing = true
	_time_left = duration
	for p: GPUParticles3D in _emitters():
		p.restart()
		p.emitting = true
	set_process(true)


func set_tint(color: Color) -> void:
	for np: NodePath in tint_targets:
		var n := get_node_or_null(np)
		var mat: Material = null
		if n is GPUParticles3D:
			var mesh := (n as GPUParticles3D).draw_pass_1
			mat = mesh.surface_get_material(0) if mesh != null else null
		elif n is MeshInstance3D:
			mat = (n as MeshInstance3D).material_override
		if mat is ShaderMaterial:
			(mat as ShaderMaterial).set_shader_parameter(&"tint", color)
		elif mat is StandardMaterial3D:
			(mat as StandardMaterial3D).albedo_color = color


func stop() -> void:
	for p: GPUParticles3D in _emitters():
		p.emitting = false
	visible = false
	playing = false
	set_process(false)


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		stop()
		finished.emit(self)


func _emitters() -> Array[GPUParticles3D]:
	var out: Array[GPUParticles3D] = []
	for c: Node in find_children("*", "GPUParticles3D", true, false):
		out.append(c as GPUParticles3D)
	return out
