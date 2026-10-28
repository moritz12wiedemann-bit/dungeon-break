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


## Merkt sich eine Kopie des Modells `path` (z. B. "res://.../wall.gltf") an der Stelle `where`.
func add(path: String, where: Transform3D) -> void:
	if not _instances.has(path):
		_instances[path] = []
		_parts[path] = _load_parts(path)
	_instances[path].append(where)


## Hängt alle gesammelten Modelle als MultiMeshInstance3D unter `parent`.
func build(parent: Node3D) -> void:
	for path in _instances:
		var where_list: Array = _instances[path]
		for part in _parts[path]:
			var multimesh := MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.mesh = part[0]
			multimesh.instance_count = where_list.size()
			for i in where_list.size():
				multimesh.set_instance_transform(i, where_list[i] * part[1])
			var instance := MultiMeshInstance3D.new()
			instance.name = path.get_file().get_basename()
			instance.multimesh = multimesh
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
