class_name TrampleRider
extends Node3D
## Ein Reiter von Trampeln: prescht geradeaus und trifft jeden Gegner auf seinem Weg einmal.

const HIT_RADIUS := 1.3

var _player: Node3D
var _start: Vector3
var _direction: Vector3
var _length: float
var _seconds: float
var _delay: float
var _damage: float
var _weaken: float
var _weaken_seconds: float
var _time := 0.0
var _hit: Array = []


func _init(player: Node3D, start: Vector3, direction: Vector3, length: float, seconds: float, delay: float,
		damage: float, weaken: float, weaken_seconds: float) -> void:
	_player = player
	_start = start
	_direction = direction
	_length = length
	_seconds = seconds
	_delay = delay
	_damage = damage
	_weaken = weaken
	_weaken_seconds = weaken_seconds


func _ready() -> void:
	visible = false
	global_position = _start
	rotation.y = atan2(_direction.x, _direction.z)
	# Galoppierendes Pferd mit einer schwachen Staubspur am Boden.
	var horse := HorseModel.new()
	horse.running = true
	horse.run_speed = 1.8
	add_child(horse)
	var dust := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.9, 3.0)
	dust.mesh = plane
	dust.position = Vector3(0, 0.08, -1.8)
	dust.material_override = SkillEffects._glow_material(Color(0.9, 0.75, 0.5, 0.08))
	add_child(dust)


func _process(delta: float) -> void:
	_time += delta
	var t := (_time - _delay) / _seconds
	if t < 0.0:
		return
	if t >= 1.0 or not is_instance_valid(_player):
		queue_free()
		return
	visible = true
	global_position = _start + _direction * _length * t
	for enemy in SkillEffects.enemies_around(get_tree(), global_position, HIT_RADIUS):
		if enemy in _hit:
			continue
		_hit.append(enemy)
		enemy.take_damage(_player.roll_damage(_damage))
		if _weaken > 0.0 and not enemy.is_dead():
			enemy.apply_weaken(_weaken, _weaken_seconds)
