class_name HealingOrb
extends Interactable
## Kugel der Erneuerung in der Stadt: anklicken füllt Leben und Zorn (bzw. Mana) ganz auf und
## setzt alle Abklingzeiten zurück (Fähigkeiten und Heiltrank).

const COLOR := Color(0.2, 0.9, 0.4)

var _orb: Node3D
var _time := 0.0


func _ready() -> void:
	collision_layer = 9
	collision_mask = 0
	var pedestal: Node3D = load("res://assets/models/quaternius/dungeon/Pedestal2.gltf").instantiate()
	pedestal.scale = Vector3(0.6, 0.55, 0.6)
	add_child(pedestal)
	_orb = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR
	material.emission_enabled = true
	material.emission = COLOR
	material.emission_energy_multiplier = 0.7
	sphere.material = material
	_orb.mesh = sphere
	_orb.position = Vector3(0, 1.7, 0)
	add_child(_orb)
	var light := OmniLight3D.new()
	light.light_color = COLOR
	light.light_energy = 2.0
	light.omni_range = 6.0
	light.position = Vector3(0, 2.0, 0)
	add_child(light)
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.6
	cylinder.height = 2.5
	shape.shape = cylinder
	shape.position = Vector3(0, 1.25, 0)
	add_child(shape)
	var label := Label3D.new()
	label.text = "Kugel der Erneuerung\n(anklicken: alles auffüllen)"
	label.pixel_size = 0.0035
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = COLOR.lerp(Color.WHITE, 0.3)
	label.font_size = 44
	label.outline_size = 8
	label.position = Vector3(0, 2.6, 0)
	add_child(label)


func _process(delta: float) -> void:
	_time += delta
	_orb.position.y = 1.7 + sin(_time * 2.0) * 0.06


func interact(player: Node) -> void:
	if player.is_dead():
		return
	player.health.heal(player.health.max_health)
	player.mana = player.max_mana
	player.skill_cooldowns.clear()
	player.potion_cooldown_left = 0.0
	SkillEffects.burst_ring(player, COLOR, 2.5, 0.6)
	DamageNumber.spawn_text(player, "Erneuert!", COLOR)
