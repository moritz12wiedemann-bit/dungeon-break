class_name ClickMarker
extends MeshInstance3D
## Kleiner Ring am Boden, der nach einem Klick zum Laufen kurz aufleuchtet und schrumpft.
## Hält man die Maustaste gedrückt (Ziel folgt der Maus), verschwindet er sofort wieder.

## So lange (Sekunden) dauert die Animation.
const DURATION := 0.45
## Ab dieser Haltedauer gilt der Klick als "Gedrückthalten".
const HOLD_TIME := 0.18

static var _material: StandardMaterial3D
static var _mesh: TorusMesh
static var _current: ClickMarker

var _age: float = 0.0


## Setzt eine Markierung an die Stelle `where`. Eine noch sichtbare alte Markierung verschwindet.
static func spawn(tree: SceneTree, where: Vector3) -> void:
	if is_instance_valid(_current):
		_current.queue_free()
	var marker := ClickMarker.new()
	tree.current_scene.add_child(marker)
	marker.global_position = where + Vector3(0, 0.05, 0)
	_current = marker


func _ready() -> void:
	if _mesh == null:
		_mesh = TorusMesh.new()
		_mesh.inner_radius = 0.32
		_mesh.outer_radius = 0.42
		_mesh.rings = 24
		_mesh.ring_segments = 6
		_material = StandardMaterial3D.new()
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.albedo_color = Color(1.0, 0.85, 0.35)
		_material.no_depth_test = true
	mesh = _mesh
	# Jede Markierung blendet für sich aus, daher eigene Kopie des Materials.
	material_override = _material.duplicate()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scale = Vector3(1.6, 0.15, 1.6)


func _process(delta: float) -> void:
	_age += delta
	if _age >= HOLD_TIME and Input.is_action_pressed("move"):
		queue_free()
		return
	var t := clampf(_age / DURATION, 0.0, 1.0)
	var size := lerpf(1.6, 0.5, t)
	scale = Vector3(size, 0.15, size)
	material_override.albedo_color.a = 1.0 - t * t
	if t >= 1.0:
		queue_free()
