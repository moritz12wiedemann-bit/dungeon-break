class_name ArmyAura
extends Node3D
## Kriegeraura (Erweiterung von Ein-Mann-Armee): Kreis am Boden, der dem Spieler folgt.
## Gegner darin machen RATIO weniger Schaden und erleiden RATIO mehr (enemy.apply_aura).
## Verschwindet von selbst, sobald der Buff "armee" vorbei ist.

const RADIUS := 3.0
const RATIO := 0.2
const EVERY := 0.25

var _player: Node3D
var _next := 0.0


## Hängt die Aura an den Spieler (eine alte wird ersetzt).
static func attach(player: Node3D) -> void:
	for child in player.get_children():
		if child is ArmyAura:
			child.queue_free()
	var aura := ArmyAura.new()
	aura._player = player
	player.add_child(aura)


func _ready() -> void:
	position = Vector3(0, 0.06, 0)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = RADIUS - 0.12
	torus.outer_radius = RADIUS
	ring.mesh = torus
	ring.scale = Vector3(1.0, 0.3, 1.0)
	ring.material_override = SkillEffects._glow_material(Color(0.9, 0.3, 0.08, 0.45))
	add_child(ring)
	var disc := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = RADIUS
	cylinder.bottom_radius = RADIUS
	cylinder.height = 0.01
	cylinder.radial_segments = 48
	disc.mesh = cylinder
	disc.material_override = SkillEffects._glow_material(Color(1.0, 0.4, 0.15, 0.06))
	add_child(disc)


func _process(delta: float) -> void:
	if not is_instance_valid(_player) or not _player.buffs.has("armee") or _player.is_dead():
		queue_free()
		return
	rotation.y += delta * 0.6
	_next -= delta
	if _next > 0.0:
		return
	_next = EVERY
	for enemy in SkillEffects.enemies_around(get_tree(), _player.global_position, RADIUS):
		enemy.apply_aura(RATIO, EVERY + 0.25)
