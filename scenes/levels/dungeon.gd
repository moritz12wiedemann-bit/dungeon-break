extends Node3D
## Zufällig erzeugter Dungeon. Jedes Mal, wenn man ihn über den Altar betritt,
## sieht die Karte anders aus (siehe dungeon_generator.gd).
## Baut Boden und Wände aus Kästen, berechnet das Navigations-Netz, setzt Spieler,
## Gegner und Fackeln. Nach dem Sieg über den Boss erscheint ein Portal in die Stadt.

const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const BRUTE_SCENE := preload("res://scenes/enemies/enemy_brute.tscn")
const BOSS_SCENE := preload("res://scenes/enemies/enemy_boss.tscn")
const PORTAL_SCENE := preload("res://scenes/world/town_portal.tscn")

## Kantenlänge eines Rasterkästchens in Metern.
@export var cell_size: float = 2.0
## Höhe der Wände in Metern.
@export var wall_height: float = 2.0
## Wie viele normale Gegner pro Raum (zufällig dazwischen).
@export var enemies_per_room_min: int = 2
@export var enemies_per_room_max: int = 4
## Chance, dass in einem Raum zusätzlich ein großer Gegner steht.
@export_range(0.0, 1.0) var brute_chance: float = 0.35
@export var floor_material: StandardMaterial3D
@export var wall_material: StandardMaterial3D

@onready var nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var geometry: Node3D = $NavigationRegion3D/Geometry
@onready var lights: Node3D = $Lights
@onready var enemies: Node3D = $Enemies
@onready var player: CharacterBody3D = $Player
@onready var camera: Node3D = $IsoCamera
@onready var hud: CanvasLayer = $HUD

var _generator := DungeonGenerator.new()
var _rng := RandomNumberGenerator.new()
var _enemies_left: int = 0
var _box_meshes: Dictionary = {}


func _ready() -> void:
	_rng.seed = GameState.dungeon_seed
	_generator.generate(_rng)
	_build_geometry()
	nav_region.bake_navigation_mesh(false)

	player.global_position = _cell_to_world(_generator.start_room().get_center())
	player.nav_agent.target_position = player.global_position
	camera.global_position = player.global_position

	_spawn_enemies()
	_place_lights()

	hud.track_player(player)
	hud.set_location("Dungeon · Stufe %d" % GameState.dungeon_level)
	hud.set_enemies_left(_enemies_left)
	hud.show_toast("Besiege den Boss! (T = zurück in die Stadt)")


func _cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3((cell.x + 0.5) * cell_size, 0.0, (cell.y + 0.5) * cell_size)


## Boden und Wände: Kästchen einer Zeile werden zu langen Kästen zusammengefasst,
## damit es nicht Tausende einzelne Objekte werden.
func _build_geometry() -> void:
	for y in _generator.height:
		var x := 0
		while x < _generator.width:
			var kind := _cell_kind(Vector2i(x, y))
			var start := x
			while x < _generator.width and _cell_kind(Vector2i(x, y)) == kind:
				x += 1
			if kind != "":
				_add_box(kind, Vector2i(start, y), x - start)


## "floor" = Boden, "wall" = Wand neben Boden, "" = Wand ohne Boden daneben (wird nicht gebaut).
func _cell_kind(cell: Vector2i) -> String:
	if _generator.is_floor(cell):
		return "floor"
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if _generator.is_floor(cell + Vector2i(dx, dy)):
				return "wall"
	return ""


func _add_box(kind: String, first_cell: Vector2i, length: int) -> void:
	var is_wall := kind == "wall"
	var size := Vector3(length * cell_size, wall_height if is_wall else 1.0, cell_size)
	var body := StaticBody3D.new()
	body.collision_mask = 0
	body.position = Vector3(first_cell.x * cell_size + size.x / 2.0,
		wall_height / 2.0 if is_wall else -0.5, (first_cell.y + 0.5) * cell_size)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _get_box_mesh(size, wall_material if is_wall else floor_material)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(mesh_instance)
	body.add_child(collision)
	geometry.add_child(body)


func _get_box_mesh(size: Vector3, material: Material) -> BoxMesh:
	var key := "%s_%s" % [size, material.get_instance_id()]
	if not _box_meshes.has(key):
		var mesh := BoxMesh.new()
		mesh.size = size
		mesh.material = material
		_box_meshes[key] = mesh
	return _box_meshes[key]


func _spawn_enemies() -> void:
	var rooms := _generator.rooms
	# Startraum (0) bleibt leer, damit man in Ruhe ankommt.
	for i in range(1, rooms.size() - 1):
		var count := _rng.randi_range(enemies_per_room_min, enemies_per_room_max)
		for n in count:
			_spawn(ENEMY_SCENE, _generator.random_cell_in(rooms[i], _rng))
		if _rng.randf() < brute_chance:
			_spawn(BRUTE_SCENE, _generator.random_cell_in(rooms[i], _rng, 2))
	var boss_room := _generator.boss_room()
	var boss := _spawn(BOSS_SCENE, boss_room.get_center())
	boss.died.connect(_on_boss_died.bind(boss))
	for n in 3:
		_spawn(ENEMY_SCENE, _generator.random_cell_in(boss_room, _rng, 2))


func _spawn(scene: PackedScene, cell: Vector2i) -> Node3D:
	var enemy := scene.instantiate()
	enemy.apply_level(GameState.dungeon_level)
	enemy.position = _cell_to_world(cell)
	enemy.rotation.y = _rng.randf() * TAU
	enemies.add_child(enemy)
	enemy.died.connect(_on_enemy_died)
	_enemies_left += 1
	return enemy


func _place_lights() -> void:
	for room in _generator.rooms:
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.7, 0.4)
		light.light_energy = 2.0
		light.omni_range = maxf(room.size.x, room.size.y) * cell_size * 0.9
		lights.add_child(light)
		light.global_position = _cell_to_world(room.get_center()) + Vector3(0, 3.5, 0)


func _on_enemy_died() -> void:
	_enemies_left -= 1
	hud.set_enemies_left(_enemies_left)


func _on_boss_died(boss: Node3D) -> void:
	var portal := PORTAL_SCENE.instantiate()
	add_child(portal)
	# Etwas neben den Boss stellen, damit die Beute nicht verdeckt wird.
	portal.global_position = boss.global_position + Vector3(3.0, 0, 0)
	if not _generator.is_floor(_world_to_cell(portal.global_position)):
		portal.global_position = _cell_to_world(_generator.boss_room().get_center())
	hud.show_toast("Boss besiegt! Das Portal bringt dich zurück in die Stadt.")


func _world_to_cell(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x / cell_size), floori(pos.z / cell_size))
