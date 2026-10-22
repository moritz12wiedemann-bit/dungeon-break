extends Node3D
## Kleine Lebensanzeige, die über einer Figur schwebt und immer zur Kamera zeigt.
## Besteht aus zwei flachen Rechtecken: dunkler Hintergrund und farbiger Balken.
## Wird über set_value() von der Figur aktualisiert.

## Breite und Höhe des Balkens in Metern.
@export var size: Vector2 = Vector2(1.0, 0.12)
## Farbe des gefüllten Teils.
@export var fill_color: Color = Color(0.85, 0.15, 0.15)
## Balken erst zeigen, wenn die Figur verletzt ist.
@export var hide_when_full: bool = true

var _fill: MeshInstance3D
var _ratio: float = 1.0


func _ready() -> void:
	_add_quad(Color(0.05, 0.05, 0.05, 0.85), 0)
	_fill = _add_quad(fill_color, 1)
	_fill.position.z = 0.001
	set_value(1, 1)


func _process(_delta: float) -> void:
	# Immer genauso ausrichten wie die Kamera, dann sieht man den Balken von vorn.
	var camera := get_viewport().get_camera_3d()
	if camera:
		global_basis = camera.global_basis


## Zeigt current von maximum Lebenspunkten an.
func set_value(current: int, maximum: int) -> void:
	_ratio = clampf(float(current) / float(maxi(maximum, 1)), 0.0, 1.0)
	_fill.scale.x = maxf(_ratio, 0.001)
	# Balken links festhalten, damit er nach links "schrumpft".
	_fill.position.x = -size.x * (1.0 - _ratio) * 0.5
	visible = not (hide_when_full and _ratio >= 1.0)


func _add_quad(color: Color, priority: int) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	material.render_priority = priority
	var quad := QuadMesh.new()
	quad.size = size
	quad.material = material
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = quad
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_instance)
	return mesh_instance
