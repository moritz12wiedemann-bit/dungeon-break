class_name GroundItem
extends StaticBody3D
## Ein Gegenstand, der am Boden liegt. Zeigt seinen Namen in der Farbe der Seltenheit.
## Der Spieler klickt darauf, läuft hin und hebt ihn auf.

const SCENE_PATH := "res://scenes/items/ground_item.tscn"
## Waffen liegen als echte Waffe am Boden (Fantasy Props MegaKit), alles andere als Beutel.
const WEAPON_MODELS := [
	"res://assets/models/quaternius/props/Sword_Bronze.gltf",
	"res://assets/models/quaternius/props/Axe_Bronze.gltf",
	"res://assets/models/quaternius/props/Pickaxe_Bronze.gltf",
]
const BAG_MODEL := "res://assets/models/quaternius/props/Bag.gltf"

var item: ItemData

@onready var label: Label3D = $Label
@onready var model: Node3D = $Model
@onready var glow: MeshInstance3D = $Glow
@onready var beam: MeshInstance3D = $Beam


## Legt `item` an der Stelle `position` in die aktuelle Szene.
static func drop(item_to_drop: ItemData, where: Vector3, tree: SceneTree) -> GroundItem:
	var ground_item: GroundItem = load(SCENE_PATH).instantiate()
	ground_item.item = item_to_drop
	tree.current_scene.add_child(ground_item)
	ground_item.global_position = where
	return ground_item


func _ready() -> void:
	add_to_group("ground_items")
	var color := item.get_color()
	label.text = item.item_name
	label.modulate = color
	_add_model()
	# Leuchtender Fleck am Boden in der Farbe der Seltenheit.
	var glow_material := StandardMaterial3D.new()
	glow_material.albedo_color = Color(color, 0.45)
	glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.material_override = glow_material
	# Lichtstrahl nur ab "Selten", damit gute Beute auffällt.
	beam.visible = item.rarity >= ItemData.Rarity.RARE
	if beam.visible:
		var beam_material := StandardMaterial3D.new()
		beam_material.albedo_color = Color(color, 0.35)
		beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		beam_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		beam.material_override = beam_material
	# Kleiner Hüpfer beim Fallen.
	var rest_height := model.position.y
	model.position.y = rest_height + 1.0
	create_tween().tween_property(model, "position:y", rest_height, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)


## Setzt das passende 3D-Modell ein: Waffe flach auf den Boden gelegt, sonst ein Beutel.
func _add_model() -> void:
	var path: String = BAG_MODEL
	if item.slot == ItemData.Slot.WEAPON:
		# Gleicher Name = gleiches Modell, auch wenn man den Gegenstand wieder fallen lässt.
		path = WEAPON_MODELS[absi(item.item_name.hash()) % WEAPON_MODELS.size()]
		model.rotation = Vector3(0, randf() * TAU, PI / 2.0)
		model.scale = Vector3.ONE * 0.8
		model.position.y = 0.1
	else:
		model.rotation.y = randf() * TAU
		model.scale = Vector3.ONE * 0.6
	model.add_child(load(path).instantiate())
