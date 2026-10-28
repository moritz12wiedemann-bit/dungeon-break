@tool
class_name Placeholder
extends Node3D
## Grauer Platzhalter für etwas, für das es (noch) kein passendes Modell gibt
## (Häuser, Bäume, Felsen, Wege, Zäune, Dungeon-Wände ...).
## Alles Graue im Spiel ist also "fehlt noch". Sobald ein passendes Modell da ist,
## ersetzt man den Platzhalter einfach durch das Modell.
## Die Form wird aus einfachen Körpern gebaut, `size` ist die Größe in Metern
## (vor der Skalierung des Knotens), `offset` verschiebt die Mitte.

@export_enum("Kasten", "Haus", "Turm", "Baum", "Bäume", "Fels", "Weg", "Zaun", "Pfahl", "Fahne", "Bogen")
var kind: String = "Kasten":
	set(value):
		kind = value
		_queue_build()
@export var size: Vector3 = Vector3.ONE:
	set(value):
		size = value
		_queue_build()
## Verschiebung der Mitte der Grundfläche (y = Unterkante).
@export var offset: Vector3 = Vector3.ZERO:
	set(value):
		offset = value
		_queue_build()
## Kleines Schild darüber, z. B. "Schmiede" (leer = kein Schild).
@export var label_text: String = "":
	set(value):
		label_text = value
		_queue_build()

const COLORS := {
	"wall": Color(0.62, 0.62, 0.62),
	"roof": Color(0.42, 0.42, 0.45),
	"wood": Color(0.5, 0.48, 0.45),
	"leaf": Color(0.48, 0.55, 0.48),
	"stone": Color(0.55, 0.55, 0.55),
	"path": Color(0.5, 0.48, 0.44),
	"cloth": Color(0.7, 0.66, 0.6),
}

static var _materials: Dictionary = {}

var _queued := false


func _ready() -> void:
	_build()


func _queue_build() -> void:
	if not is_inside_tree() or _queued:
		return
	_queued = true
	_build.call_deferred()


## Gemeinsames Material pro Farbe (für Skripte, die selbst Platzhalter-Meshes bauen, z. B. der Dungeon).
static func material(color_name: String) -> StandardMaterial3D:
	if not _materials.has(color_name):
		var m := StandardMaterial3D.new()
		m.albedo_color = COLORS[color_name]
		m.roughness = 0.95
		_materials[color_name] = m
	return _materials[color_name]


func _build() -> void:
	_queued = false
	for child in get_children():
		if child.has_meta("placeholder_part"):
			child.free()
	var s := size
	match kind:
		"Haus":
			_box(Vector3(s.x, s.y * 0.6, s.z), Vector3(0, 0, 0), "wall")
			_prism(Vector3(s.x * 1.05, s.y * 0.4, s.z * 1.05), Vector3(0, s.y * 0.6, 0), "roof")
		"Turm":
			_cylinder(minf(s.x, s.z) * 0.45, s.y * 0.75, Vector3.ZERO, "wall", 8)
			_cone(minf(s.x, s.z) * 0.55, s.y * 0.25, Vector3(0, s.y * 0.75, 0), "roof")
		"Baum":
			_cylinder(minf(s.x, s.z) * 0.12, s.y * 0.4, Vector3.ZERO, "wood", 6)
			_cone(minf(s.x, s.z) * 0.5, s.y * 0.7, Vector3(0, s.y * 0.3, 0), "leaf")
		"Bäume":
			for p in [Vector3(-0.25, 0, -0.2), Vector3(0.25, 0, -0.1), Vector3(0, 0, 0.28)]:
				var o := Vector3(p.x * s.x, 0, p.z * s.z)
				_cylinder(minf(s.x, s.z) * 0.06, s.y * 0.35, o, "wood", 6)
				_cone(minf(s.x, s.z) * 0.26, s.y * 0.75 * (1.0 - absf(p.x)), o + Vector3(0, s.y * 0.25, 0), "leaf")
		"Fels":
			var rock := SphereMesh.new()
			rock.radius = 0.5
			rock.height = 1.0
			rock.radial_segments = 7
			rock.rings = 4
			_add(rock, Vector3(0, s.y * 0.5, 0), s, "stone")
		"Weg":
			_cylinder(minf(s.x, s.z) * 0.5, s.y, Vector3.ZERO, "path", 6)
		"Zaun":
			# Läuft entlang Z.
			for z in [-0.45, 0.0, 0.45]:
				_box(Vector3(s.x, s.y, s.x), Vector3(0, 0, z * s.z), "wood")
			_box(Vector3(s.x * 0.5, s.y * 0.12, s.z), Vector3(0, s.y * 0.7, 0), "wood")
			_box(Vector3(s.x * 0.5, s.y * 0.12, s.z), Vector3(0, s.y * 0.35, 0), "wood")
		"Pfahl":
			_box(Vector3(s.x, s.y, s.z), Vector3.ZERO, "wood")
		"Fahne":
			_cylinder(0.04 * s.y, s.y, Vector3.ZERO, "wood", 6)
			_box(Vector3(0.02 * s.y, s.y * 0.35, s.z), Vector3(0, s.y * 0.6, -s.z * 0.5), "cloth")
		"Bogen":
			var post := Vector3(s.x * 0.16, s.y, s.z)
			_box(post, Vector3(-s.x * 0.42, 0, 0), "stone")
			_box(post, Vector3(s.x * 0.42, 0, 0), "stone")
			_box(Vector3(s.x, s.y * 0.15, s.z * 1.1), Vector3(0, s.y * 0.85, 0), "stone")
		_:
			_box(s, Vector3.ZERO, "wall")
	if label_text != "":
		var label := Label3D.new()
		label.set_meta("placeholder_part", true)
		label.text = "Platzhalter: " + label_text
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color(0.85, 0.85, 0.85)
		label.outline_size = 8
		label.font_size = 36
		label.pixel_size = 0.006
		add_child(label)
		# Das Schild soll nicht mit dem Platzhalter mitwachsen.
		label.top_level = true
		label.global_position = global_transform * (offset + Vector3(0, size.y + 0.2, 0)) if is_inside_tree() else position


func _box(box_size: Vector3, base: Vector3, color: String) -> void:
	var mesh := BoxMesh.new()
	mesh.size = box_size
	_add(mesh, base + Vector3(0, box_size.y * 0.5, 0), Vector3.ONE, color)


func _prism(prism_size: Vector3, base: Vector3, color: String) -> void:
	var mesh := PrismMesh.new()
	mesh.size = prism_size
	_add(mesh, base + Vector3(0, prism_size.y * 0.5, 0), Vector3.ONE, color)


func _cylinder(radius: float, height: float, base: Vector3, color: String, sides: int) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	_add(mesh, base + Vector3(0, height * 0.5, 0), Vector3.ONE, color)


func _cone(radius: float, height: float, base: Vector3, color: String) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 1
	_add(mesh, base + Vector3(0, height * 0.5, 0), Vector3.ONE, color)


func _add(mesh: Mesh, where: Vector3, scale_by: Vector3, color: String) -> void:
	var instance := MeshInstance3D.new()
	instance.set_meta("placeholder_part", true)
	instance.mesh = mesh
	instance.material_override = material(color)
	instance.position = offset + where
	instance.scale = scale_by
	add_child(instance)
