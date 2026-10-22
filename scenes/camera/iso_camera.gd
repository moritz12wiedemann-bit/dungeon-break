extends Node3D
## Feste, schräge Iso-Kamera, die einem Ziel (meist dem Spieler) weich folgt.
## Der Winkel bleibt immer gleich, nur die Position wandert mit.

## Der Knoten, dem die Kamera folgt.
@export var target: Node3D
## Wie weich die Kamera nachzieht. Größer = schneller, 0 = gar nicht.
@export var follow_speed: float = 8.0


func _ready() -> void:
	# Damit die Kamera sich nicht mitdreht, wenn sie irgendwo als Kind hängt.
	top_level = true
	if target:
		global_position = target.global_position


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var weight := clampf(follow_speed * delta, 0.0, 1.0)
	global_position = global_position.lerp(target.global_position, weight)
