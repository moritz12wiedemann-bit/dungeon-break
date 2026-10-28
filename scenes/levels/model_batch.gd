class_name ModelBatch
extends RefCounted
## Sammelt viele Kopien derselben 3D-Modelle (z. B. Hunderte Bodenplatten und Wandstücke)
## und zeichnet sie am Ende gebündelt mit MultiMeshInstance3D.
## Das ist viel schneller, als jede Platte als eigenes Objekt in die Szene zu hängen.
## Nur zum Anschauen: Kollision und Navigation kommen weiterhin von den unsichtbaren Kästen.

## Modell-Pfad → Liste aus [Mesh, Transform3D relativ zum Modell-Ursprung].
var _parts: Dictionary = {}
## Modell-Pfad → alle Stellen (Transform3D), an denen es stehen soll.
var _instances: Dictionary = {}
## Modell-Pfad → Farbe pro Kopie (nur wenn mit Farbe hinzugefügt).
var _colors: Dictionary = {}
## Modell-Pfad → Material, das statt des Original-Materials benutzt wird.
var _materials: Dictionary = {}


## Merkt sich eine Kopie des Modells `path` (z. B. "res://.../wall.gltf") an der Stelle `where`.
## `color` färbt diese eine Kopie ein; das klappt nur, wenn mit set_material() ein Material
## mit `vertex_color_use_as_albedo` gesetzt ist.
func add(path: String, where: Transform3D, color := Color.WHITE) -> void:
	if not _instances.has(path):
		_instances[path] = []
		_colors[path] = []
		_parts[path] = _load_parts(path)
	_instances[path].append(where)
	_colors[path].append(color)


## Zeichnet alle Kopien von `path` mit diesem Material statt dem aus der Modell-Datei.
func set_material(path: String, material: Material) -> void:
	_materials[path] = material


## Kopie des Original-Materials von `path` (z. B. um es einzufärben und mit set_material() zu setzen).
func copy_model_material(path: String) -> StandardMaterial3D:
	if not _parts.has(path):
		_parts[path] = _load_parts(path)
	var mesh: Mesh = _parts[path][0][0]
	return mesh.surface_get_material(0).duplicate()


## Wie add(), aber für ein selbst gebautes Mesh (z. B. eine einfache Bodenplatte).
## `key` unterscheidet verschiedene Meshes, `offset` verschiebt das Mesh innerhalb des Modells.
func add_mesh(key: String, mesh: Mesh, where: Transform3D, offset := Transform3D.IDENTITY) -> void:
	if not _instances.has(key):
		_instances[key] = []
		_colors[key] = []
		_parts[key] = [[mesh, offset]]
	_instances[key].append(where)
	_colors[key].append(Color.WHITE)


## Ändert die Farbe der zuletzt hinzugefügten Kopie von `path` (siehe add()).
func set_last_color(path: String, color: Color) -> void:
	_colors[path][-1] = color


## Hängt alle gesammelten Modelle als MultiMeshInstance3D unter `parent`.
func build(parent: Node3D) -> void:
	for path in _instances:
		var where_list: Array = _instances[path]
		for part in _parts[path]:
			var multimesh := MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			var colors: Array = _colors.get(path, [])
			multimesh.use_colors = _materials.has(path) and not colors.is_empty()
			multimesh.mesh = part[0]
			multimesh.instance_count = where_list.size()
			for i in where_list.size():
				multimesh.set_instance_transform(i, where_list[i] * part[1])
				if multimesh.use_colors:
					multimesh.set_instance_color(i, colors[i])
			var instance := MultiMeshInstance3D.new()
			instance.name = path.get_file().get_basename()
			instance.multimesh = multimesh
			if _materials.has(path):
				instance.material_override = _materials[path]
			parent.add_child(instance)


## Lädt das Modell einmal und merkt sich alle Meshes darin samt ihrer Lage.
func _load_parts(path: String) -> Array:
	var result: Array = []
	var root: Node = load(path).instantiate()
	_collect(root, Transform3D.IDENTITY, result)
	root.free()
	return result


func _collect(node: Node, parent_transform: Transform3D, result: Array) -> void:
	var node_transform := parent_transform
	if node is Node3D:
		node_transform = parent_transform * node.transform
	if node is MeshInstance3D and node.mesh:
		result.append([node.mesh, node_transform])
	for child in node.get_children():
		_collect(child, node_transform, result)
