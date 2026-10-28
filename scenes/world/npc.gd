class_name Npc
extends Interactable
## Figur in der Stadt (Schmied, Händler ...). Steht da und spielt ihre Steh-Animation ab.
## Anklicken öffnet das passende Fenster in der Benutzeroberfläche (HUD).

## Welches Fenster sich öffnet (siehe hud.gd, open_window): "smith", "merchant" ...
@export var window_name: String = ""
## Name über dem Kopf.
@export var display_name: String = "Bewohner"
@export var name_color: Color = Color(1.0, 0.9, 0.6)
## Aussehen: eine Figuren-Vorlage aus scenes/characters/ (z. B. smith.tscn).
## Was die Figur in den Händen hält und welche Animation sie im Stehen abspielt, steht dort.
@export var model: PackedScene


func _ready() -> void:
	collision_layer = 1 | 8
	collision_mask = 0
	interact_range = 2.8
	if model:
		add_child(model.instantiate())
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.5
	capsule.height = 2.0
	shape.shape = capsule
	shape.position.y = 1.0
	add_child(shape)
	var label := Label3D.new()
	label.text = display_name
	label.modulate = name_color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.0035
	label.font_size = 44
	label.outline_size = 8
	label.position.y = 2.1
	add_child(label)


func interact(player: Node) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.open_window(window_name, player, self)
