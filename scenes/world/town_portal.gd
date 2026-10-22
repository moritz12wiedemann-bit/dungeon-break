extends Interactable
## Portal zurück in die Stadt. Erscheint nach dem Sieg über den Boss.

@onready var ring: Node3D = $Ring


func _ready() -> void:
	# Portal "wächst" beim Erscheinen.
	scale = Vector3.ONE * 0.01
	create_tween().tween_property(self, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	ring.rotate_object_local(Vector3.UP, delta * 1.5)


func interact(player: Node) -> void:
	GameState.go_to_town(player)
