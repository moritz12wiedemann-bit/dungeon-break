extends OmniLight3D
## Lässt ein Licht leicht flackern wie eine Fackel.

## Wie stark die Helligkeit schwankt (0.2 = ±20 %).
@export var strength: float = 0.2
@export var speed: float = 9.0

var _base_energy: float
var _time: float


func _ready() -> void:
	_base_energy = light_energy
	_time = randf() * 100.0


func _process(delta: float) -> void:
	_time += delta * speed
	light_energy = _base_energy * (1.0 + strength * (sin(_time) * 0.6 + sin(_time * 2.3) * 0.4))
