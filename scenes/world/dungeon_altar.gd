extends Interactable
## Dungeon-Altar in der Stadt: Anklicken öffnet einen neuen, zufällig erzeugten Dungeon.

@onready var crystal: Node3D = $Crystal


func _process(delta: float) -> void:
	crystal.rotate_y(delta * 0.8)
	crystal.position.y = 2.2 + sin(Time.get_ticks_msec() / 500.0) * 0.1


func interact(player: Node) -> void:
	GameState.enter_new_dungeon(player)
