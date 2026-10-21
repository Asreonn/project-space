class_name EngineNozzleFx
extends Node3D
## Soft blue engine flame + world-space puff trail for ONE nozzle.
## Parent it to an `FX_EngineTrail_<n>` empty (engine_trail.tscn does this);
## the flame points along the empty's +Z (= backwards, per model_anchors.md).
## Budget: 1 flame quad + max 28 particles.

## 0..1 throttle or normalised speed.
@export_range(0.0, 1.0) var throttle: float = 0.0
## Boost flag: longer, brighter flame and denser trail.
@export var boost: bool = false
## Scale for bigger nozzles / ships (1.0 = starter shuttle, ~0.11 m nozzle).
@export var size_scale: float = 1.0
@export var flame_length_idle: float = 0.18
@export var flame_length_full: float = 0.55
@export var flame_length_boost: float = 0.95
@export var flame_width: float = 0.16
## Response time (s) for throttle/boost changes.
@export var smoothing: float = 0.12

var _t: float = 0.0
var _b: float = 0.0

@onready var _flame: MeshInstance3D = $Flame
@onready var _puffs: GPUParticles3D = $Puffs
@onready var _flame_mat: ShaderMaterial = _flame.material_override as ShaderMaterial
@onready var _puff_pm: ParticleProcessMaterial = _puffs.process_material as ParticleProcessMaterial


func set_throttle(value: float) -> void:
	throttle = clampf(value, 0.0, 1.0)


func set_boost(on: bool) -> void:
	boost = on


func _process(delta: float) -> void:
	var k := 1.0 - exp(-delta / maxf(smoothing, 0.001))
	_t = lerpf(_t, throttle, k)
	_b = lerpf(_b, 1.0 if boost else 0.0, k)
	var length := lerpf(flame_length_idle, flame_length_full, _t)
	length = lerpf(length, flame_length_boost, _b)
	length *= size_scale
	var width := flame_width * size_scale * (1.0 + 0.25 * _b)
	_flame.transform = Transform3D(Basis().scaled(Vector3(width, 1.0, length)), Vector3(0.0, 0.0, length * 0.5))
	_flame_mat.set_shader_parameter(&"intensity", _t)
	_flame_mat.set_shader_parameter(&"boost", _b)
	_puffs.amount_ratio = clampf(0.25 + 0.55 * _t + 0.2 * _b, 0.0, 1.0)
	_puff_pm.scale_min = 0.7 * size_scale * (1.0 + 0.5 * _b)
	_puff_pm.scale_max = 1.0 * size_scale * (1.0 + 0.6 * _b)
	_puff_pm.initial_velocity_min = 0.4 + 1.2 * _b
	_puff_pm.initial_velocity_max = 0.8 + 2.0 * _b
