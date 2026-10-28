class_name GroundPickup
extends Node3D
## Gold oder ein Material (z. B. ein Orb), das am Boden liegt.
## Wird automatisch aufgehoben, sobald der Spieler darüber läuft (kein Klick nötig).

const COIN_MODEL := "res://assets/models/quaternius/props/Coin_Pile_2.gltf"
## Aus dieser Entfernung (Meter) wird es aufgehoben.
const PICKUP_RANGE := 1.3

## "" = Gold, sonst der Name des Materials (siehe GameMaterials).
var material_id: String = ""
var amount: int = 1

var _player: Node3D
var _collected := false
var _visual := Node3D.new()


static func drop_gold(gold: int, where: Vector3, tree: SceneTree) -> GroundPickup:
	return _drop("", gold, where, tree)


static func drop_material(id: String, count: int, where: Vector3, tree: SceneTree) -> GroundPickup:
	return _drop(id, count, where, tree)


static func _drop(id: String, count: int, where: Vector3, tree: SceneTree) -> GroundPickup:
	var pickup := GroundPickup.new()
	pickup.material_id = id
	pickup.amount = count
	tree.current_scene.add_child(pickup)
	pickup.global_position = Vector3(where.x, 0.0, where.z)
	return pickup


func _ready() -> void:
	add_child(_visual)
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.006
	label.font_size = 40
	label.outline_size = 10
	label.position.y = 0.6
	if material_id == "":
		var coins: Node3D = load(COIN_MODEL).instantiate()
		coins.scale = Vector3.ONE * 2.5
		coins.rotation.y = randf() * TAU
		_visual.add_child(coins)
		label.text = "%d Gold" % amount
		label.modulate = Color(1.0, 0.85, 0.3)
	else:
		var orb := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.18
		sphere.height = 0.36
		var material := StandardMaterial3D.new()
		var color := _orb_color()
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.5
		sphere.material = material
		orb.mesh = sphere
		orb.position.y = 0.35
		_visual.add_child(orb)
		label.text = GameMaterials.display_name(material_id)
		label.modulate = color.lerp(Color.WHITE, 0.4)
	add_child(label)
	# Kleiner Hüpfer beim Fallen.
	_visual.position.y = 0.8
	create_tween().tween_property(_visual, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _orb_color() -> Color:
	match material_id:
		GameMaterials.ORB_ADD:
			return Color(0.25, 0.65, 1.0)
		GameMaterials.ORB_REMOVE:
			return Color(1.0, 0.3, 0.2)
		GameMaterials.ORB_REROLL:
			return Color(0.7, 0.35, 1.0)
	return Color(0.75, 0.75, 0.75)


func _physics_process(_delta: float) -> void:
	if _collected:
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	if _player.is_dead():
		return
	var offset := _player.global_position - global_position
	offset.y = 0.0
	if offset.length() <= PICKUP_RANGE:
		_collect()


func _collect() -> void:
	_collected = true
	var inventory: Inventory = _player.inventory
	if material_id == "":
		inventory.add_gold(amount)
		DamageNumber.spawn_text(_player, "+%d Gold" % amount, Color(1.0, 0.85, 0.3))
	else:
		inventory.add_material(material_id, amount)
		DamageNumber.spawn_text(_player, "+%s" % GameMaterials.display_name(material_id), _orb_color())
	# Kurz zum Spieler fliegen und verschwinden.
	var tween := create_tween()
	tween.tween_property(self, "global_position", _player.global_position + Vector3(0, 1, 0), 0.15)
	tween.tween_callback(queue_free)
