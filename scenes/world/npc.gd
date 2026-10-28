class_name Npc
extends Interactable
## Figur in der Stadt (Schmied, Händler ...). Steht da und atmet (Animation "Idle").
## Anklicken öffnet das passende Fenster in der Benutzeroberfläche (HUD).

## Welches Fenster sich öffnet (siehe hud.gd, open_window): "smith", "merchant" ...
@export var window_name: String = ""
## Name über dem Kopf.
@export var display_name: String = "Bewohner"
@export var name_color: Color = Color(1.0, 0.9, 0.6)
## Modell (KayKit-Figur).
@export var model: PackedScene
@export var model_scale: float = 0.75
## Diese Gegenstände in den Händen bleiben sichtbar, alle anderen werden versteckt.
@export var held_items: PackedStringArray = []
## Animation im Stehen.
@export var idle_animation: String = "Idle"


func _ready() -> void:
	collision_layer = 1 | 8
	collision_mask = 0
	interact_range = 2.8
	if model:
		var figure: Node3D = model.instantiate()
		figure.scale = Vector3.ONE * model_scale
		add_child(figure)
		for hand in figure.find_children("handslot_*", "", true, false):
			for held in hand.get_children():
				held.visible = held.name in held_items
		var animation: AnimationPlayer = figure.find_child("AnimationPlayer", true, false)
		if animation and animation.has_animation(idle_animation):
			animation.get_animation(idle_animation).loop_mode = Animation.LOOP_LINEAR
			animation.play(idle_animation)
			# Nicht alle Figuren im Gleichtakt.
			animation.seek(randf() * animation.current_animation_length)
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
	label.pixel_size = 0.007
	label.font_size = 44
	label.outline_size = 10
	label.position.y = 2.4
	add_child(label)


func interact(player: Node) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.open_window(window_name, player, self)
