class_name BuffRing
extends Node3D
## Leuchtender Ring am Boden um den Spieler, solange der Buff `buff_id` läuft (z. B. Schildwall).

var _player: Node3D
var _buff_id: String


static func attach(player: Node3D, buff_id: String, color: Color, radius: float) -> void:
	var ring := BuffRing.new()
	ring._player = player
	ring._buff_id = buff_id
	ring.position = Vector3(0, 0.07, 0)
	var mesh := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.1
	torus.outer_radius = radius
	mesh.mesh = torus
	mesh.scale = Vector3(1.0, 0.3, 1.0)
	mesh.material_override = SkillEffects._glow_material(color)
	ring.add_child(mesh)
	player.add_child(ring)


func _process(_delta: float) -> void:
	if not is_instance_valid(_player) or not _player.buffs.has(_buff_id):
		queue_free()
