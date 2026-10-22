class_name DamageNumber
extends Label3D
## Schadenszahl, die kurz über einer Figur aufsteigt und verblasst.
## Aufruf von überall: DamageNumber.spawn(self, 12, Color.WHITE)


## Erzeugt eine Zahl über dem Knoten `owner_node`.
static func spawn(owner_node: Node3D, amount: int, color: Color) -> void:
	var label := DamageNumber.new()
	label.text = str(amount)
	label.modulate = color
	owner_node.get_tree().current_scene.add_child(label)
	label.global_position = owner_node.global_position + Vector3(randf_range(-0.3, 0.3), 2.2, 0)


func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	font_size = 64
	outline_size = 12
	pixel_size = 0.008
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y + 1.0, 0.7).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.3)
	tween.tween_property(self, "outline_modulate:a", 0.0, 0.4).set_delay(0.3)
	tween.chain().tween_callback(queue_free)
