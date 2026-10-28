@tool
class_name Monster
extends Node3D
## Ein Monster aus dem Quaternius-Pack "Bestiary - Dungeon Monsters Kit" (Imp, Puglin).
## Die Monster haben dasselbe Skelett wie die Menschen, deshalb laufen alle Animationen
## aus Animations.gltf auch bei ihnen (siehe tools/build_quaternius_monsters.py).
##
## Eine Vorlage ist eine Szene in scenes/characters/, die nur aus diesem Knoten besteht,
## z. B. imp.tscn oder puglin.tscn. Alles lässt sich im Inspektor umstellen.

const MONSTER_DIR := "res://assets/models/quaternius/monsters/"
## Die Modell-Dateien sind vergrößert (Hüfte auf Menschenhöhe, damit die Animationen passen).
## Mit diesem Faktor bekommen sie wieder ihre Originalgröße.
const MONSTER_SCALE := {"Imp": 0.85, "Puglin": 0.415}

@export_enum("Puglin", "Imp") var kind: String = "Puglin":
	set(value):
		kind = value
		_queue_rebuild()
## Eine der drei Farbvarianten aus dem Pack.
@export_range(1, 3) var color_variant: int = 1:
	set(value):
		color_variant = value
		_queue_rebuild()
## Wird über die Farben gelegt. Weiß = Originalfarben.
@export var tint: Color = Color.WHITE:
	set(value):
		tint = value
		_queue_rebuild()
## Leuchtende Augen (und was sonst im Pack leuchtet). 0 = aus.
@export_range(0.0, 4.0, 0.1) var glow: float = 1.0:
	set(value):
		glow = value
		_queue_rebuild()
## Größe (1 = Originalgröße aus dem Pack).
@export_range(0.3, 4.0, 0.05) var size: float = 1.0:
	set(value):
		size = value
		_queue_rebuild()
## Läuft, solange niemand anderes (z. B. das Animator-Skript) etwas abspielt.
@export var start_animation: String = "Idle"

static var _materials: Dictionary = {}

var _model: Node3D
var _rebuild_queued := false


func _ready() -> void:
	_rebuild()


## Der AnimationPlayer des Monsters (für Skripte, die selbst Animationen abspielen).
func get_animation_player() -> AnimationPlayer:
	return _model.get_node_or_null("AnimationPlayer") if _model else null


func _queue_rebuild() -> void:
	if not is_inside_tree() or _rebuild_queued:
		return
	_rebuild_queued = true
	_rebuild.call_deferred()


func _rebuild() -> void:
	_rebuild_queued = false
	if _model:
		_model.free()
	_model = load(MONSTER_DIR + kind + ".gltf").instantiate()
	_model.name = "Model"
	_model.scale = Vector3.ONE * MONSTER_SCALE[kind] * size
	add_child(_model)
	var material := _material()
	for mesh: MeshInstance3D in _model.find_children("*", "MeshInstance3D", true, false):
		for i in mesh.mesh.get_surface_count():
			mesh.set_surface_override_material(i, material)
	ModularCharacter.attach_animations(_model, start_animation)


func _material() -> BaseMaterial3D:
	var key := "%s|%d|%s|%.1f" % [kind, color_variant, tint.to_html(), glow]
	if not _materials.has(key):
		var original: Node3D = load(MONSTER_DIR + kind + ".gltf").instantiate()
		var mesh: MeshInstance3D = original.find_children("*", "MeshInstance3D", true, false)[0]
		var material: BaseMaterial3D = mesh.mesh.surface_get_material(0).duplicate()
		original.free()
		material.albedo_texture = load(MONSTER_DIR + "T_%s_BaseColor_%d.png" % [kind, color_variant])
		material.albedo_color = tint
		material.emission_enabled = glow > 0.0
		material.emission_energy_multiplier = glow
		_materials[key] = material
	return _materials[key]
