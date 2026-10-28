extends Node3D
## Feste, schräge Iso-Kamera, die einem Ziel (meist dem Spieler) weich folgt.
## Der Winkel bleibt immer gleich, nur die Position wandert mit.
## Mit dem Mausrad zoomt man näher heran oder weiter weg.

## Der Knoten, dem die Kamera folgt.
@export var target: Node3D
## Wie weich die Kamera nachzieht. Größer = schneller, 0 = gar nicht.
@export var follow_speed: float = 8.0
## Zoom-Grenzen: Anteil des normalen Abstands (0.4 = ganz nah, 1.0 = normal).
@export var zoom_min: float = 0.4
@export var zoom_max: float = 1.2
## So viel ändert ein Mausrad-Schritt.
@export var zoom_step: float = 0.08

## Zoom bleibt beim Wechsel Stadt ↔ Dungeon erhalten. Start: 0,72 (etwa ein Viertel näher als früher).
static var _saved_zoom: float = 0.72

@onready var camera: Camera3D = $Pivot/Camera3D
## Abstand der Kamera bei Zoom 1.0 (aus der Szene).
@onready var _base_offset: Vector3 = camera.position

var _zoom: float = 1.0


func _ready() -> void:
	# Damit die Kamera sich nicht mitdreht, wenn sie irgendwo als Kind hängt.
	top_level = true
	if target:
		global_position = target.global_position
	_zoom = clampf(_saved_zoom, zoom_min, zoom_max)
	camera.position = _base_offset * _zoom


func _unhandled_input(event: InputEvent) -> void:
	# Nur wenn die Maus nicht über einem Fenster ist (sonst kommt das Rad nicht hier an).
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(_saved_zoom - zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(_saved_zoom + zoom_step)


func _set_zoom(value: float) -> void:
	_saved_zoom = clampf(value, zoom_min, zoom_max)


func _physics_process(delta: float) -> void:
	var weight := clampf(follow_speed * delta, 0.0, 1.0)
	# Weich zum gewünschten Zoom gleiten.
	_zoom = lerpf(_zoom, _saved_zoom, weight)
	camera.position = _base_offset * _zoom
	if target == null:
		return
	global_position = global_position.lerp(target.global_position, weight)
