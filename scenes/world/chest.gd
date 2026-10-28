class_name Chest
extends Interactable
## Schatzkiste im Dungeon. Anklicken: der Deckel klappt auf und Gold, Gegenstände
## und vielleicht ein Orb fallen heraus (siehe Loot.drop_chest). Danach bleibt sie offen.
## Wird von dungeon.gd mit Chest.create() erzeugt.

const MODEL := "res://assets/models/kaykit/dungeon/chest.gltf"
const GOLD_MODEL := "res://assets/models/kaykit/dungeon/chest_gold.gltf"

## Stufe der Beute (meist die Dungeon-Stufe).
var loot_level: int = 1
## Goldene Kiste: doppelte Beute.
var is_golden: bool = false

var _opened := false
var _lid: Node3D
var _label: Label3D


static func create(level: int, golden: bool) -> Chest:
	var chest := Chest.new()
	chest.loot_level = level
	chest.is_golden = golden
	return chest


func _ready() -> void:
	# Welt (damit niemand durchläuft) + Objekte (damit man sie anklicken kann).
	collision_layer = 1 | 8
	collision_mask = 0
	interact_range = 2.2
	var model: Node3D = load(GOLD_MODEL if is_golden else MODEL).instantiate()
	add_child(model)
	_lid = model.find_child("chest*lid", true, false)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.6, 1.2, 1.2)
	shape.shape = box
	shape.position.y = 0.6
	add_child(shape)
	_label = Label3D.new()
	_label.text = "Goldene Truhe" if is_golden else "Truhe"
	_label.modulate = Color(1.0, 0.85, 0.3) if is_golden else Color(0.9, 0.8, 0.6)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.pixel_size = 0.006
	_label.font_size = 40
	_label.outline_size = 10
	_label.position.y = 1.6
	add_child(_label)


func interact(_player: Node) -> void:
	if _opened:
		return
	_opened = true
	_label.hide()
	if _lid:
		create_tween().tween_property(_lid, "rotation:x", -1.9, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Beute vor die Kiste werfen (vom Deckel weg).
	var front := global_position + global_basis.z * 1.2
	for i in (2 if is_golden else 1):
		Loot.drop_chest(loot_level, front, get_tree())
	# Offene Kisten kann man nicht mehr anklicken.
	collision_layer = 1
