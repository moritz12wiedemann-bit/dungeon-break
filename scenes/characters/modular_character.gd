@tool
class_name ModularCharacter
extends Node3D
## Eine Figur aus dem Quaternius-Baukasten (Modular Character Outfits + Universal Base Characters).
## Alle Teile (Kleidung von Bauer und Waldläufer, Köpfe, Frisuren ...) stecken in einer Datei
## pro Körper (assets/models/quaternius/characters/Male.gltf bzw. Female.gltf).
## Dieses Skript blendet nur die gewählten Teile ein, färbt Haut/Haare/Kleidung,
## gibt der Figur Waffen in die Hände und hängt die Animationen an.
##
## Eine fertige Zusammenstellung ("Vorlage") ist einfach eine Szene in scenes/characters/,
## die nur aus diesem Knoten besteht, z. B. hero.tscn oder zombie.tscn.
## Alles lässt sich im Godot-Editor rechts im Inspektor umstellen, die Figur ändert sich sofort.

const CHARACTER_DIR := "res://assets/models/quaternius/characters/"
const PROP_DIR := "res://assets/models/quaternius/props/"
const BODY_FILES := {"Mann": "Male.gltf", "Frau": "Female.gltf"}

## Kleidungsstil -> Vorsilbe der Teile in der Modell-Datei.
const STYLES := {"Bauer": "Peasant", "Waldläufer": "Ranger"}
## Frisur -> Teil in der Modell-Datei.
const HAIR := {
	"Glatze": "",
	"Kurz": "Hair_Buzzed",
	"Kurz (fein)": "Hair_BuzzedFemale",
	"Gescheitelt": "Hair_SimpleParted",
	"Lang": "Hair_Long",
	"Dutt": "Hair_Buns",
}
## Farbvarianten der Kleidung (Texturen).
const PEASANT_COLORS := {"Braun": "T_Peasant_BaseColor.png", "Oliv": "T_Peasant_2_BaseColor.png"}
const RANGER_COLORS := {"Grün": "T_Ranger_BaseColor.png", "Leder": "T_Ranger_3_BaseColor.png"}

## Dinge, die die Figur in der Hand halten kann: Name -> [Modell, Lage in der Hand].
## Die Lage ist relativ zum Handknochen (hand_r/hand_l): Drehung in Grad, dann Verschiebung.
const HELD_ITEMS := {
	"Nichts": [],
	"Schwert": ["Sword_Bronze", Vector3(-90, 0, 0), Vector3(0, 0.09, -0.1)],
	"Axt": ["Axe_Bronze", Vector3(-90, 0, 0), Vector3(0, 0.09, -0.1)],
	"Spitzhacke": ["Pickaxe_Bronze", Vector3(-90, 0, 0), Vector3(0, 0.09, -0.12)],
	"Schild": ["Shield_Wooden", Vector3(0, 0, 0), Vector3(0, 0.05, 0.05)],
	"Buch": ["Book_7", Vector3(0, 0, 90), Vector3(0.04, 0.1, 0)],
	# Krug, Kerzenhalter und Trank stehen aufrecht, wenn der Arm locker herunterhängt.
	"Krug": ["Mug", Vector3(0, 0, 180), Vector3(0, 0.1, 0)],
	"Kerzenhalter": ["CandleStick", Vector3(0, 0, 180), Vector3(0, 0.1, 0)],
	"Trank": ["Potion_2", Vector3(0, 0, 180), Vector3(0, 0.12, 0)],
}

## Diese Animationen wiederholen sich endlos (alle anderen laufen einmal ab).
const LOOPING := [
	"Idle", "Walk", "Jog", "Sprint", "Sword_Idle", "Spell_Idle", "Shield_Idle", "Talk", "Torch_Idle",
	"FoldArms", "Lantern", "Sitting", "Chop", "Dance", "Zombie_Idle", "Zombie_Walk", "Crouch_Walk",
]

@export_group("Körper")
@export_enum("Mann", "Frau") var body: String = "Mann":
	set(value):
		body = value
		_queue_rebuild()
## Hautfarbe. Weiß = Originalfarbe; jede andere Farbe wird darübergelegt (z. B. Grün für Untote).
@export var skin_color: Color = Color.WHITE:
	set(value):
		skin_color = value
		_queue_rebuild()
@export_enum("Glatze", "Kurz", "Kurz (fein)", "Gescheitelt", "Lang", "Dutt") var hair: String = "Kurz":
	set(value):
		hair = value
		_queue_rebuild()
@export var beard: bool = false:
	set(value):
		beard = value
		_queue_rebuild()
@export var hair_color: Color = Color(0.35, 0.22, 0.12):
	set(value):
		hair_color = value
		_queue_rebuild()
## Größe der Figur (1 = etwa 1,80 m).
@export_range(0.5, 3.0, 0.05) var size: float = 1.0:
	set(value):
		size = value
		_queue_rebuild()

@export_group("Kleidung")
## Kapuze des Waldläufers (Haare werden darunter ausgeblendet).
@export var hood: bool = false:
	set(value):
		hood = value
		_queue_rebuild()
@export_enum("Bauer", "Waldläufer") var torso: String = "Bauer":
	set(value):
		torso = value
		_queue_rebuild()
## Die zwei Gürtel des Waldläufers (passen nur zum Waldläufer-Oberteil).
@export var belts: bool = false:
	set(value):
		belts = value
		_queue_rebuild()
@export var pauldrons: bool = false:
	set(value):
		pauldrons = value
		_queue_rebuild()
@export_enum("Bauer", "Waldläufer") var arms: String = "Bauer":
	set(value):
		arms = value
		_queue_rebuild()
@export var bracers: bool = false:
	set(value):
		bracers = value
		_queue_rebuild()
@export_enum("Bauer", "Waldläufer") var legs: String = "Bauer":
	set(value):
		legs = value
		_queue_rebuild()
@export_enum("Bauer", "Waldläufer") var feet: String = "Bauer":
	set(value):
		feet = value
		_queue_rebuild()
@export_enum("Braun", "Oliv") var peasant_color: String = "Braun":
	set(value):
		peasant_color = value
		_queue_rebuild()
@export_enum("Grün", "Leder") var ranger_color: String = "Grün":
	set(value):
		ranger_color = value
		_queue_rebuild()
## Wird über die ganze Kleidung gelegt. Weiß = Originalfarben.
@export var clothes_tint: Color = Color.WHITE:
	set(value):
		clothes_tint = value
		_queue_rebuild()

@export_group("In den Händen")
@export_enum("Nichts", "Schwert", "Axt", "Spitzhacke", "Schild", "Buch", "Krug", "Kerzenhalter", "Trank")
var right_hand: String = "Nichts":
	set(value):
		right_hand = value
		_queue_rebuild()
@export_enum("Nichts", "Schwert", "Axt", "Spitzhacke", "Schild", "Buch", "Krug", "Kerzenhalter", "Trank")
var left_hand: String = "Nichts":
	set(value):
		left_hand = value
		_queue_rebuild()

@export_group("Animation")
## Läuft, solange niemand anderes (z. B. das Animator-Skript) etwas abspielt.
@export var start_animation: String = "Idle"

## Gemeinsam für alle Figuren: Materialien (gleiche Farbe = gleiches Material, schneller)
## und die Animations-Bibliothek.
static var _materials: Dictionary = {}
static var _animations: AnimationLibrary

var _model: Node3D
var _rebuild_queued := false


func _ready() -> void:
	_rebuild()


## Der AnimationPlayer der Figur (für Skripte, die selbst Animationen abspielen).
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
	_model = load(CHARACTER_DIR + BODY_FILES[body]).instantiate()
	_model.name = "Model"
	_model.scale = Vector3.ONE * size
	add_child(_model)
	var wanted := _wanted_parts()
	for mesh: MeshInstance3D in _model.find_children("*", "MeshInstance3D", true, false):
		mesh.visible = mesh.name in wanted
		if mesh.visible:
			_apply_materials(mesh)
	var skeleton: Skeleton3D = _model.find_child("Skeleton3D", true, false)
	if skeleton:
		_hold(skeleton, "hand_r", right_hand)
		_hold(skeleton, "hand_l", left_hand)
	_add_animations()


func _wanted_parts() -> Array[String]:
	var parts: Array[String] = ["Head", "Eyes"]
	parts.append("Eyebrows_Female" if body == "Frau" else "Eyebrows_Regular")
	if hood:
		parts.append("Ranger_Hood")
	elif HAIR[hair] != "":
		parts.append(HAIR[hair])
	if beard:
		parts.append("Beard")
	parts.append(STYLES[torso] + "_Body")
	parts.append(STYLES[arms] + "_Arms")
	parts.append(STYLES[legs] + "_Legs")
	parts.append("Ranger_Boots" if feet == "Waldläufer" else "Peasant_Feet")
	if belts:
		parts.append_array(["Ranger_Belt_1", "Ranger_Belt_2"])
	if pauldrons:
		parts.append("Ranger_Pauldrons")
	if bracers:
		parts.append("Ranger_Bracers")
	return parts


## Ersetzt die Materialien eines Teils durch eingefärbte Kopien (pro Farbe nur einmal angelegt).
func _apply_materials(mesh: MeshInstance3D) -> void:
	for i in mesh.mesh.get_surface_count():
		var original := mesh.mesh.surface_get_material(i) as BaseMaterial3D
		if original == null:
			continue
		var kind := original.resource_name
		var color := Color.WHITE
		var texture := ""
		match kind:
			"Skin", "Skin_Head":
				color = skin_color
			"Hair", "Hair_Long":
				color = hair_color
			"Peasant":
				color = clothes_tint
				texture = PEASANT_COLORS[peasant_color]
			"Ranger":
				color = clothes_tint
				texture = RANGER_COLORS[ranger_color]
		var key := "%s|%s|%s|%s" % [body, kind, color.to_html(), texture]
		if not _materials.has(key):
			var material: BaseMaterial3D = original.duplicate()
			material.albedo_color = color
			if texture != "":
				material.albedo_texture = load(CHARACTER_DIR + texture)
			_materials[key] = material
		mesh.set_surface_override_material(i, _materials[key])


func _hold(skeleton: Skeleton3D, bone: String, item: String) -> void:
	var entry: Array = HELD_ITEMS.get(item, [])
	if entry.is_empty():
		return
	var attachment := BoneAttachment3D.new()
	attachment.name = "Hand_" + bone.right(1).to_upper()
	skeleton.add_child(attachment)
	attachment.bone_name = bone
	var prop: Node3D = load(PROP_DIR + entry[0] + ".gltf").instantiate()
	var degrees: Vector3 = entry[1]
	prop.rotation = Vector3(deg_to_rad(degrees.x), deg_to_rad(degrees.y), deg_to_rad(degrees.z))
	prop.position = entry[2]
	attachment.add_child(prop)


func _add_animations() -> void:
	if _animations == null:
		var source: Node = load(CHARACTER_DIR + "Animations.gltf").instantiate()
		var player: AnimationPlayer = source.find_child("AnimationPlayer", true, false)
		_animations = player.get_animation_library("")
		source.free()
		for anim_name in LOOPING:
			if _animations.has_animation(anim_name):
				_animations.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	var animation_player := AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	_model.add_child(animation_player)
	animation_player.root_node = NodePath("..")
	animation_player.add_animation_library("", _animations)
	if start_animation != "" and animation_player.has_animation(start_animation):
		animation_player.play(start_animation)
		# Nicht alle Figuren im Gleichtakt.
		animation_player.seek(randf() * animation_player.current_animation_length)
