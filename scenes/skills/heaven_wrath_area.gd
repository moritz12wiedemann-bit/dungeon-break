extends Node3D
## Die Fläche von "Zorn des Himmels": goldener Kreis am Boden. Nach DELAY Sekunden schlagen
## vereinzelt kleine Blitze ein, DURATION Sekunden lang alle TICK Sekunden Schaden an allen Gegnern darin.
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
## So viele kleine Blitze pro Treffer (nur Aussehen).
const BOLTS_PER_TICK := 1


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
	# Boden nur leicht markieren (normal gemischt, nicht leuchtend aufaddiert).
	_disc_material = _glow(Color(COLOR, 0.08))
	_disc_material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	disc.material_override = _disc_material
	add_child(disc)

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = RADIUS - 0.12
	torus.outer_radius = RADIUS
	torus.rings = 64
	ring.mesh = torus
	ring.material_override = _glow(Color(COLOR, 0.55))
	add_child(ring)


func _physics_process(delta: float) -> void:
	_time += delta
	if _time < DELAY:
		# Kurz vorher: Fläche leuchtet langsam auf.
		_disc_material.albedo_color.a = 0.08 + 0.1 * _time / DELAY
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


func _hit() -> void:
	for i in BOLTS_PER_TICK:
		_spawn_bolt()
	if not is_instance_valid(_player):
		return
	for enemy in SkillEffects.enemies_around(get_tree(), global_position, RADIUS):
		enemy.take_damage(_player.roll_damage(DAMAGE_PER_TICK * _bonus))


## Ein kleiner Blitz: Zickzack-Linie vom Himmel an eine zufällige Stelle in der Fläche, verblasst schnell.
func _spawn_bolt() -> void:
	var angle := randf() * TAU
	var spot := Vector3(cos(angle), 0, sin(angle)) * sqrt(randf()) * (RADIUS - 0.3)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3] = []
	var height := 6.0
	var segments := 7
	for i in segments + 1:
		var t := float(i) / segments
		var jitter := Vector3(randf_range(-0.35, 0.35), 0, randf_range(-0.35, 0.35)) if i > 0 and i < segments else Vector3.ZERO
		points.append(spot + Vector3(0, height * (1.0 - t), 0) + jitter)
	# Zum Bildschirm hin breit: dünne Bänder quer zur Blickrichtung der Iso-Kamera.
	var side := Vector3(0.06, 0, -0.06)
	for i in segments:
		var a := points[i]
		var b := points[i + 1]
		for vertex in [a - side, a + side, b + side, a - side, b + side, b - side]:
			tool.set_color(Color(1.0, 0.95, 0.7))
			tool.add_vertex(vertex)
	var bolt := MeshInstance3D.new()
	bolt.mesh = tool.commit()
	var material := _glow(Color(1.0, 0.92, 0.6, 1.0))
	bolt.material_override = material
	add_child(bolt)
	# Kleiner Lichtfleck am Einschlag.
	var flash := MeshInstance3D.new()
	var flash_mesh := CylinderMesh.new()
	flash_mesh.top_radius = 0.45
	flash_mesh.bottom_radius = 0.45
	flash_mesh.height = 0.02
	flash.mesh = flash_mesh
	var flash_material := _glow(Color(COLOR, 0.6))
	flash.material_override = flash_material
	flash.position = spot + Vector3(0, 0.02, 0)
	add_child(flash)
	var tween := bolt.create_tween().set_parallel()
	tween.tween_property(material, "albedo_color:a", 0.0, 0.18)
	tween.tween_property(flash_material, "albedo_color:a", 0.0, 0.3)
	tween.chain().tween_callback(func():
		bolt.queue_free()
		flash.queue_free())


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
