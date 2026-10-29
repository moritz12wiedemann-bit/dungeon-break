class_name OrbitHammer
extends Node3D
## Ein Hammer, der um den Spieler kreist (Hammerwurf) und jeden Gegner trifft, den er berührt
## (denselben Gegner höchstens alle HIT_EVERY Sekunden). Verschwindet nach `time_left` Sekunden.

const RADIUS := 3.2
const SPEED := 3.2
const HIT_RADIUS := 0.9
const HIT_EVERY := 0.6

var player: Node3D
var slot: int
var slot_count: int
var time_left: float
var multiplier: float
var _model: Node3D
## Gegner (Instanz-ID) → Zeitpunkt (ms), ab dem er wieder getroffen werden kann.
var _next_hit: Dictionary = {}


func _init(owner_player: Node3D, hammer_slot: int, slots: int, seconds: float, damage_multiplier: float, blocks_projectiles: bool) -> void:
	player = owner_player
	slot = hammer_slot
	slot_count = slots
	time_left = seconds
	multiplier = damage_multiplier
	add_to_group("orbit_hammers")
	if blocks_projectiles:
		add_to_group("projectile_blockers")


## Erster freier Platz für einen neuen Hammer von `player` (-1 = alle belegt).
static func free_slot(owner_player: Node3D, slots: int) -> int:
	var used := []
	for hammer in owner_player.get_tree().get_nodes_in_group("orbit_hammers"):
		if hammer.player == owner_player and not hammer.is_queued_for_deletion():
			used.append(hammer.slot)
	for i in slots:
		if not i in used:
			return i
	return -1


func _ready() -> void:
	_model = _build_model(multiplier > 1.0)
	add_child(_model)
	_follow()


func _process(delta: float) -> void:
	time_left -= delta
	if time_left <= 0.0 or not is_instance_valid(player) or player.is_dead():
		queue_free()
		return
	_follow()
	_model.rotate_y(delta * 9.0)
	var now := Time.get_ticks_msec()
	for enemy in SkillEffects.enemies_around(get_tree(), global_position, HIT_RADIUS):
		var key := enemy.get_instance_id()
		if _next_hit.get(key, 0) > now:
			continue
		_next_hit[key] = now + int(HIT_EVERY * 1000.0)
		enemy.take_damage(player.roll_damage(multiplier))


func _follow() -> void:
	var angle := Time.get_ticks_msec() / 1000.0 * SPEED + slot * TAU / slot_count
	global_position = player.global_position + Vector3(cos(angle) * RADIUS, 1.0, sin(angle) * RADIUS)


## Hammer aus einfachen Formen: Holzstiel und Metallkopf, leicht leuchtend.
static func _build_model(heavy: bool) -> Node3D:
	var root := Node3D.new()
	root.rotation_degrees = Vector3(0, 0, 70)
	var handle := MeshInstance3D.new()
	var stick := CylinderMesh.new()
	stick.top_radius = 0.045
	stick.bottom_radius = 0.055
	stick.height = 0.7
	handle.mesh = stick
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.45, 0.3, 0.17)
	handle.material_override = wood
	root.add_child(handle)
	var head := MeshInstance3D.new()
	var block := BoxMesh.new()
	block.size = Vector3(0.42, 0.24, 0.24)
	head.mesh = block
	head.position = Vector3(0, 0.36, 0)
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.85, 0.7, 0.35) if heavy else Color(0.7, 0.74, 0.8)
	metal.metallic = 0.8
	metal.roughness = 0.35
	metal.emission_enabled = true
	metal.emission = Color(1.0, 0.75, 0.3) if heavy else Color(0.55, 0.7, 1.0)
	metal.emission_energy_multiplier = 0.6
	head.material_override = metal
	root.add_child(head)
	root.scale = Vector3.ONE * 1.2
	return root
