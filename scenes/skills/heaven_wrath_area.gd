extends Node3D
## Die Fläche von "Zorn des Himmels": goldener Kreis am Boden. Nach DELAY Sekunden fällt Licht
## vom Himmel und macht DURATION Sekunden lang alle TICK Sekunden Schaden an allen Gegnern darin.
## Mit Himmelssog werden Gegner in der Fläche zur Mitte gezogen.

const RADIUS := 3.0
const DELAY := 0.5
const DURATION := 3.0
const TICK := 0.25
## Schaden pro Treffer (12 Treffer in 3 s = 400 % insgesamt).
const DAMAGE_PER_TICK := 4.0 / 12.0
## So stark (Meter pro Sekunde) zieht der Himmelssog zur Mitte.
const PULL_STRENGTH := 1.6
const COLOR := Color(1.0, 0.82, 0.35)

var _player: Node3D
var _pull: bool
var _bonus: float
var _time := 0.0
var _tick_left := 0.0
var _disc_material: StandardMaterial3D
var _beam: MeshInstance3D
var _beam_material: StandardMaterial3D


func _init(player: Node3D, pull: bool, bonus: float) -> void:
	_player = player
	_pull = pull
	_bonus = bonus


func _ready() -> void:
	var disc := MeshInstance3D.new()
	var disc_mesh := CylinderMesh.new()
	disc_mesh.top_radius = RADIUS
	disc_mesh.bottom_radius = RADIUS
	disc_mesh.height = 0.02
	disc_mesh.radial_segments = 48
	disc.mesh = disc_mesh
	_disc_material = _glow(Color(COLOR, 0.12))
	disc.material_override = _disc_material
	add_child(disc)

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = RADIUS - 0.12
	torus.outer_radius = RADIUS
	torus.rings = 64
	ring.mesh = torus
	ring.material_override = _glow(Color(COLOR, 0.8))
	add_child(ring)

	_beam = MeshInstance3D.new()
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = RADIUS * 0.85
	beam_mesh.bottom_radius = RADIUS * 0.95
	beam_mesh.height = 7.0
	beam_mesh.cap_top = false
	beam_mesh.cap_bottom = false
	_beam.mesh = beam_mesh
	_beam.position.y = 3.5
	_beam_material = _glow(Color(COLOR, 0.0))
	_beam.material_override = _beam_material
	add_child(_beam)


func _physics_process(delta: float) -> void:
	_time += delta
	if _time < DELAY:
		# Kurz vorher: Fläche leuchtet langsam auf.
		_disc_material.albedo_color.a = 0.12 + 0.2 * _time / DELAY
		return
	if _time > DELAY + DURATION:
		_fade_out()
		return
	if _pull:
		for enemy in SkillEffects.enemies_around(get_tree(), global_position, RADIUS):
			enemy.apply_pull(global_position, PULL_STRENGTH)
	_tick_left -= delta
	if _tick_left <= 0.0:
		_tick_left += TICK
		_hit()
	# Lichtsäule flackert.
	_beam_material.albedo_color.a = 0.18 + 0.1 * sin(_time * 25.0)


func _hit() -> void:
	if not is_instance_valid(_player):
		return
	for enemy in SkillEffects.enemies_around(get_tree(), global_position, RADIUS):
		enemy.take_damage(_player.roll_damage(DAMAGE_PER_TICK * _bonus))


func _fade_out() -> void:
	set_physics_process(false)
	var tween := create_tween().set_parallel()
	for child in get_children():
		var material: StandardMaterial3D = child.material_override
		tween.tween_property(material, "albedo_color:a", 0.0, 0.4)
	tween.chain().tween_callback(queue_free)


static func _glow(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
