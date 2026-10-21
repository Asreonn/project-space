class_name SpacePalette
extends Resource
## Colour preset for the space background (nebula, stars, planet).
## One .tres per region/biome under res://assets/vfx/palettes/.

@export var color_void: Color = Color(0.035, 0.025, 0.08)
@export var color_deep: Color = Color(0.24, 0.1, 0.4)
@export var color_mid: Color = Color(0.7, 0.26, 0.58)
@export var color_warm: Color = Color(1.0, 0.55, 0.38)
@export var color_hot: Color = Color(1.0, 0.72, 0.42)
@export var star_tint: Color = Color(1.0, 0.93, 0.86)
@export_range(0.0, 2.0) var nebula_density: float = 1.0
@export_range(0.0, 2.0) var nebula_brightness: float = 0.8
@export_range(0.0, 1.0) var star_density: float = 0.22

@export_group("Planet")
@export var planet_color_a: Color = Color(1.0, 0.62, 0.4)
@export var planet_color_b: Color = Color(0.85, 0.42, 0.38)
@export var planet_shadow: Color = Color(0.16, 0.08, 0.22)
@export var planet_atmosphere: Color = Color(1.0, 0.72, 0.55)
@export var planet_ring: bool = true


func apply_to_background(mat: ShaderMaterial) -> void:
	if mat == null:
		return
	mat.set_shader_parameter(&"color_void", _rgb(color_void))
	mat.set_shader_parameter(&"color_deep", _rgb(color_deep))
	mat.set_shader_parameter(&"color_mid", _rgb(color_mid))
	mat.set_shader_parameter(&"color_warm", _rgb(color_warm))
	mat.set_shader_parameter(&"color_hot", _rgb(color_hot))
	mat.set_shader_parameter(&"star_tint", _rgb(star_tint))
	mat.set_shader_parameter(&"nebula_density", nebula_density)
	mat.set_shader_parameter(&"nebula_brightness", nebula_brightness)
	mat.set_shader_parameter(&"star_density", star_density)


func apply_to_planet(mat: ShaderMaterial) -> void:
	if mat == null:
		return
	mat.set_shader_parameter(&"color_a", _rgb(planet_color_a))
	mat.set_shader_parameter(&"color_b", _rgb(planet_color_b))
	mat.set_shader_parameter(&"color_shadow", _rgb(planet_shadow))
	mat.set_shader_parameter(&"atmosphere_color", _rgb(planet_atmosphere))
	mat.set_shader_parameter(&"ring_enabled", planet_ring)


static func _rgb(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)
