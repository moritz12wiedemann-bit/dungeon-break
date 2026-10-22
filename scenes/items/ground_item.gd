class_name GroundItem
extends StaticBody3D
## Ein Gegenstand, der am Boden liegt. Zeigt seinen Namen in der Farbe der Seltenheit.
## Der Spieler klickt darauf, läuft hin und hebt ihn auf.

const SCENE_PATH := "res://scenes/items/ground_item.tscn"

var item: ItemData

@onready var label: Label3D = $Label
@onready var mesh: MeshInstance3D = $Mesh
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
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.6
	mesh.material_override = material
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
	mesh.position.y = 1.0
	create_tween().tween_property(mesh, "position:y", 0.15, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)
