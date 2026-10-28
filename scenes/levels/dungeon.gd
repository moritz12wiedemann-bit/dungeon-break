extends Node3D
## Zufällig erzeugter Dungeon. Jedes Mal, wenn man ihn über den Altar betritt,
## sieht die Karte anders aus (siehe dungeon_generator.gd).
## Baut Boden und Wände (unsichtbare Kästen für Kollision, darüber die Modelle aus dem
## Modular Dungeon) und stellt Möbel aus Modular Dungeon und Fantasy Props MegaKit auf,
## berechnet das Navigations-Netz, setzt Spieler, Gegner, Fackeln und Deko.
## Nach dem Sieg über den Boss erscheint ein Portal in die Stadt.

const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const BRUTE_SCENE := preload("res://scenes/enemies/enemy_brute.tscn")
const BOSS_SCENE := preload("res://scenes/enemies/enemy_boss.tscn")
const PORTAL_SCENE := preload("res://scenes/world/town_portal.tscn")
const TORCH_FLICKER := preload("res://scenes/world/torch_flicker.gd")
## Ordner mit Boden, Wänden, Säulen (Quaternius Modular Dungeon).
const DUNGEON_KIT := "res://assets/models/quaternius/dungeon/"
## Dicke eines Wandstücks aus dem Modular Dungeon.
const WALL_THICKNESS := 0.44
## Grundfarbe des Bodens (jede Platte wird noch etwas heller/dunkler gemacht).
const FLOOR_COLOR := Color(0.36, 0.35, 0.34)
## Ordner mit den Möbel-Modellen (Quaternius Fantasy Props MegaKit).
const KIT := "res://assets/models/quaternius/props/"
## Möbel und Kisten am Rand der Räume: [Modell, Größe, Radius der Kollision].
const PROPS := [
	["Barrel", 1.0, 0.45],
	["Barrel_Apples", 1.0, 0.45],
	["Barrel_Holder", 0.9, 0.7],
	["Crate_Wooden", 0.9, 0.6],
	["Crate_Metal", 0.9, 0.55],
	["Cauldron", 1.0, 0.55],
	["Cage_Small", 1.0, 0.5],
	["Vase_2", 1.0, 0.4],
	["CandleStick_Stand", 1.0, 0.35],
	["WeaponStand", 0.9, 0.7],
	[DUNGEON_KIT + "Barrel", 0.75, 0.45],
	[DUNGEON_KIT + "Crate", 0.75, 0.6],
	[DUNGEON_KIT + "Table_Small", 1.0, 0.8],
]
## Kleinkram auf dem Boden, ohne Kollision.
const CLUTTER := ["Vase_Rubble_Medium", "Candle_1", "Candle_2", "Bottle_1", "Book_Stack_1", "Coin_Pile",
	"Chain_Coil", "Table_Plate", "Pot_1", "Scroll_1", "Mug", "Potion_2", "Shield_Wooden",
	DUNGEON_KIT + "Skull", DUNGEON_KIT + "Bag_Coins", DUNGEON_KIT + "Brick"]
const BANNERS := ["Banner_1", "Banner_2"]

## Kantenlänge eines Rasterkästchens in Metern.
@export var cell_size: float = 2.0
## Höhe der (unsichtbaren) Kollisions-Wände in Metern.
@export var wall_height: float = 2.0
## Sichtbare Höhe der hinteren Wände (oben und links im Bild) in Metern.
@export var back_wall_height: float = 3.0
## Sichtbare Höhe der vorderen Wände (unten und rechts im Bild). Niedrig, damit sie die Sicht nicht verdecken.
@export var front_wall_height: float = 1.0
## Wie viele Fackeln höchstens pro Raum.
@export var torches_per_room: int = 2
## Wie viele normale Gegner pro Raum (zufällig dazwischen).
## Name oben links (der erste Dungeon ist der Kalksteintempel).
@export var dungeon_name: String = "Kalksteintempel"
@export var enemies_per_room_min: int = 4
@export var enemies_per_room_max: int = 8
## Chance, dass in einem Raum zusätzlich ein großer Gegner steht (wird zweimal gewürfelt).
@export_range(0.0, 1.0) var brute_chance: float = 0.35
## Chance, dass in einem Raum eine Schatzkiste steht (mindestens eine gibt es immer).
@export_range(0.0, 1.0) var chest_chance: float = 0.4
## Chance, dass eine Kiste golden ist (doppelte Beute).
@export_range(0.0, 1.0) var golden_chest_chance: float = 0.15

@onready var nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var geometry: Node3D = $NavigationRegion3D/Geometry
@onready var decor: Node3D = $Decor
@onready var lights: Node3D = $Lights
@onready var enemies: Node3D = $Enemies
@onready var player: CharacterBody3D = $Player
@onready var camera: Node3D = $IsoCamera
@onready var hud: CanvasLayer = $HUD

var _generator := DungeonGenerator.new()
var _rng := RandomNumberGenerator.new()
var _enemies_left: int = 0
## Eigener Zufall für die Deko, damit sie die Gegner-Verteilung nicht verändert.
var _decor_rng := RandomNumberGenerator.new()
var _batch := ModelBatch.new()
var _floor_material: StandardMaterial3D
## Der Boss (für die Karte oben rechts; im Endlos-Modus null).
var _boss: Node3D = null
## Kästchen, auf denen schon Deko steht.
var _used_cells: Dictionary = {}


func _ready() -> void:
	_rng.seed = GameState.dungeon_seed
	_generate_layout()
	_build_geometry()
	_build_visuals()
	_place_chests()
	nav_region.bake_navigation_mesh(false)

	player.global_position = _cell_to_world(_generator.start_room().get_center())
	player.nav_agent.target_position = player.global_position
	camera.global_position = player.global_position

	_spawn_enemies()
	_place_lights()
	hud.setup_minimap(_generator, cell_size, player, _boss)

	hud.track_player(player)
	_setup_hud()


## Erzeugt die Karte. Der Endlos-Modus (endless.gd) macht hier stattdessen eine Arena.
func _generate_layout() -> void:
	_generator.generate(_rng)


func _setup_hud() -> void:
	hud.set_location("%s · Monsterstufe %d" % [dungeon_name, GameState.dungeon_level])
	hud.set_enemies_left(_enemies_left)
	hud.show_toast("Besiege den Boss! (T = zurück in die Stadt)")


func _cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3((cell.x + 0.5) * cell_size, 0.0, (cell.y + 0.5) * cell_size)


## Unsichtbare Kollision für Boden und Wände: Kästchen einer Zeile werden zu langen Kästen
## zusammengefasst, damit es nicht Tausende einzelne Objekte werden.
## Die Navigation wird aus diesen Kästen berechnet.
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
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	geometry.add_child(body)


## Sichtbarer Dungeon: Boden, Wände und Säulen aus dem Quaternius-Pack "Modular Dungeon",
## dazu Fackeln, Banner, Fässer, Kisten und Kleinkram (Modular Dungeon + Fantasy Props MegaKit).
func _build_visuals() -> void:
	_decor_rng.seed = GameState.dungeon_seed + 1
	for y in _generator.height:
		for x in _generator.width:
			var cell := Vector2i(x, y)
			if _generator.is_floor(cell):
				_add_floor_tile(cell)
				_add_corner_fillers(cell)
	_add_walls_along(Vector2i.UP, true)
	_add_walls_along(Vector2i.LEFT, true)
	_add_walls_along(Vector2i.DOWN, false)
	_add_walls_along(Vector2i.RIGHT, false)
	for pillar in _generator.pillars:
		# Säulen niedriger als die Wände, damit sie die Figur nicht verdecken.
		_add_model(DUNGEON_KIT + "Column", _cell_to_world(pillar), 0.0, Vector3(0.95, 0.55, 0.95))
	for i in _generator.rooms.size():
		_decorate_room(_generator.rooms[i], i)
	_batch.build(decor)


## Bodenplatte: einheitlich grau und zufällig gedreht, nur selten eine etwas hellere oder dunklere
## Platte. Dazu ab und zu
## lose Steine oder ein Totenkopf, damit der Boden nicht überall gleich aussieht.
func _add_floor_tile(cell: Vector2i) -> void:
	var floor_path := DUNGEON_KIT + "Floor_Modular.gltf"
	if _floor_material == null:
		_floor_material = StandardMaterial3D.new()
		_floor_material.albedo_color = FLOOR_COLOR
		_floor_material.vertex_color_use_as_albedo = true
		_floor_material.roughness = 0.95
		_batch.set_material(floor_path, _floor_material)
		# Flache Platten: ihr Schatten fällt nirgendwohin, also gar nicht erst berechnen.
		_batch.disable_shadow(floor_path)
	var center := _cell_to_world(cell)
	var tint := Color.WHITE
	if _decor_rng.randf() < 0.08:
		var shade := _decor_rng.randf_range(0.9, 0.95) if _decor_rng.randf() < 0.5 else _decor_rng.randf_range(1.05, 1.1)
		tint = Color(shade, shade, shade)
	var turn := (_decor_rng.randi() % 4) * PI / 2.0
	# Die Platte ist 0,25 m dick und mittig, ihre Oberseite soll auf Höhe 0 liegen.
	_batch.add(floor_path, Transform3D(Basis(Vector3.UP, turn), center + Vector3(0, -0.13, 0)), tint)
	var roll := _decor_rng.randf()
	var jitter := Vector3(_decor_rng.randf_range(-0.5, 0.5), 0, _decor_rng.randf_range(-0.5, 0.5))
	if roll < 0.06:
		_add_model(DUNGEON_KIT + "Floor_BricksSeparate", center + jitter + Vector3(0, -0.12, 0), _decor_rng.randf() * TAU)
	elif roll < 0.1:
		_add_model(DUNGEON_KIT + "Floor_BricksSeparate2", center + jitter + Vector3(0, -0.2, 0), _decor_rng.randf() * TAU)
	elif roll < 0.17:
		_add_model(DUNGEON_KIT + "Brick", center + jitter, _decor_rng.randf() * TAU)
	elif roll < 0.185:
		_add_model(DUNGEON_KIT + "Skull", center + jitter, _decor_rng.randf() * TAU, Vector3.ONE * 0.8)


## Wände entlang einer Seite aller Bodenkästchen. `side` zeigt vom Boden zur Wand.
## Hinten (oben/links im Bild) hohe Wände, vorn (unten/rechts) niedrige, damit man die Figur sieht.
## Ein Wandstück ist 2 x 2 m groß (mittig um den Ursprung) und wird auf die Höhe gestreckt.
func _add_walls_along(side: Vector2i, is_back: bool) -> void:
	var height := back_wall_height if is_back else front_wall_height
	var angle: float = {Vector2i.UP: 0.0, Vector2i.LEFT: PI / 2.0, Vector2i.DOWN: PI, Vector2i.RIGHT: -PI / 2.0}[side]
	for y in _generator.height:
		for x in _generator.width:
			var cell := Vector2i(x, y)
			if not _needs_wall(cell, side):
				continue
			# Vorderseite der Wand genau auf der Kante zum Boden.
			var center := _cell_to_world(cell) + Vector3(side.x, 0, side.y) * (cell_size / 2.0 + WALL_THICKNESS / 2.0)
			_add_model(DUNGEON_KIT + "Wall_Modular", center + Vector3(0, height / 2.0, 0), angle,
				Vector3(1.0, height / 2.0, 1.0))


## Gibt es auf dieser Seite des Bodenkästchens eine Wand? (Säulen bekommen ihr eigenes Modell.)
func _needs_wall(cell: Vector2i, side: Vector2i) -> bool:
	var other := cell + side
	return _generator.is_floor(cell) and not _generator.is_floor(other) and not _generator.pillars.has(other)


## Füllt die Lücke in Ecken, wo zwei Wände aufeinandertreffen (ein schmales Stück Wand).
func _add_corner_fillers(cell: Vector2i) -> void:
	var center := _cell_to_world(cell)
	var offset := cell_size / 2.0 + WALL_THICKNESS / 2.0
	for corner in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		var side_x := Vector2i(corner.x, 0)
		var side_y := Vector2i(0, corner.y)
		if not (_needs_wall(cell, side_x) and _needs_wall(cell, side_y)):
			continue
		# Nur die Ecke zwischen zwei vorderen Wänden ist niedrig.
		var is_low: bool = corner == Vector2i(1, 1)
		var height := front_wall_height if is_low else back_wall_height
		_add_model(DUNGEON_KIT + "Wall_Modular",
			center + Vector3(corner.x * offset, height / 2.0, corner.y * offset), 0.0,
			Vector3(WALL_THICKNESS / 2.0, height / 2.0, 1.0))


## Fackeln und Banner an den hinteren Wänden, Kisten und Fässer am Rand, Kleinkram auf dem Boden.
func _decorate_room(room: Rect2i, room_index: int) -> void:
	var wall_spots: Array = []
	var edge_cells: Array[Vector2i] = []
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			var cell := Vector2i(x, y)
			if not _generator.is_floor(cell):
				continue
			for side in [Vector2i.UP, Vector2i.LEFT]:
				if _is_closed_wall(cell, side):
					wall_spots.append([cell, side])
			for side in [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]:
				if _is_closed_wall(cell, side):
					edge_cells.append(cell)
					break
	wall_spots.shuffle()
	var torches := 0
	for spot in wall_spots:
		var cell: Vector2i = spot[0]
		if _used_cells.has(cell):
			continue
		if torches < torches_per_room:
			_add_torch(cell, spot[1])
			torches += 1
		elif _decor_rng.randf() < 0.5:
			_add_banner(cell, spot[1])
		else:
			continue
		_used_cells[cell] = true
	# Start- und Boss-Raum bleiben übersichtlich.
	if room_index == 0 or room_index == _generator.rooms.size() - 1:
		return
	edge_cells.shuffle()
	var props := _decor_rng.randi_range(2, 5)
	for cell in edge_cells:
		if props <= 0:
			break
		if _used_cells.has(cell):
			continue
		_add_prop(cell)
		_used_cells[cell] = true
		props -= 1
	for n in _decor_rng.randi_range(0, 3):
		var cell := _generator.random_cell_in(room, _decor_rng, 1)
		var jitter := Vector3(_decor_rng.randf_range(-0.6, 0.6), 0, _decor_rng.randf_range(-0.6, 0.6))
		_add_model(CLUTTER[_decor_rng.randi() % CLUTTER.size()], _cell_to_world(cell) + jitter,
			_decor_rng.randf() * TAU, Vector3.ONE * 1.2)


## Wand auf dieser Seite, und auch bei beiden Nachbarn daneben (also kein Durchgang direkt daneben).
func _is_closed_wall(cell: Vector2i, side: Vector2i) -> bool:
	var along := Vector2i(absi(side.y), absi(side.x))
	return _needs_wall(cell, side) and _needs_wall(cell + along, side) and _needs_wall(cell - along, side)


func _add_torch(cell: Vector2i, side: Vector2i) -> void:
	var facing := -Vector3(side.x, 0, side.y)
	var wall_face := _cell_to_world(cell) - facing * cell_size / 2.0
	var angle := atan2(facing.x, facing.z)
	_add_model("Torch_Metal", wall_face + Vector3(0, 1.6, 0), angle, Vector3.ONE * 1.2)
	var light := OmniLight3D.new()
	light.set_script(TORCH_FLICKER)
	light.light_color = Color(1.0, 0.6, 0.3)
	light.light_energy = 2.2
	light.omni_range = 7.0
	lights.add_child(light)
	light.global_position = wall_face + facing * 0.4 + Vector3(0, 2.15, 0)
	# Kleine leuchtende Flamme an der Fackel.
	var flame := MeshInstance3D.new()
	flame.mesh = _flame_mesh()
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	light.add_child(flame)


var _flame: SphereMesh


func _flame_mesh() -> SphereMesh:
	if _flame == null:
		_flame = SphereMesh.new()
		_flame.radius = 0.1
		_flame.height = 0.28
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(1.0, 0.65, 0.2)
		_flame.material = material
	return _flame


func _add_banner(cell: Vector2i, side: Vector2i) -> void:
	var facing := -Vector3(side.x, 0, side.y)
	var wall_face := _cell_to_world(cell) - facing * cell_size / 2.0
	# Die Banner-Stange zeigt im Modell nach +X, darum eine Vierteldrehung weiter.
	_add_model(BANNERS[_decor_rng.randi() % BANNERS.size()], wall_face + Vector3(0, 2.3, 0),
		atan2(facing.x, facing.z) - PI / 2.0, Vector3.ONE * 0.9)


## Kiste, Fass o. Ä. am Raumrand, mit Kollision (wird beim Navigations-Netz berücksichtigt).
func _add_prop(cell: Vector2i) -> void:
	var prop: Array = PROPS[_decor_rng.randi() % PROPS.size()]
	var toward_wall := Vector3.ZERO
	for side in [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]:
		if _needs_wall(cell, side):
			toward_wall += Vector3(side.x, 0, side.y)
	var where := _cell_to_world(cell) + toward_wall.normalized() * 0.35
	_add_model(prop[0], where, _decor_rng.randf() * TAU, Vector3.ONE * prop[1])
	var body := StaticBody3D.new()
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = prop[2]
	shape.height = 1.5
	collision.shape = shape
	body.add_child(collision)
	geometry.add_child(body)
	body.global_position = where + Vector3(0, 0.75, 0)


## Merkt ein Modell zum Zeichnen vor. Ohne Ordner im Namen aus dem Fantasy Props MegaKit.
func _add_model(model: String, where: Vector3, angle: float = 0.0, scale: Vector3 = Vector3.ONE) -> void:
	var basis := Basis(Vector3.UP, angle) * Basis.from_scale(scale)
	var path := model if model.begins_with("res://") else KIT + model
	_batch.add(path + ".gltf", Transform3D(basis, where))


## Fester "Zufallswert" für ein Kästchen (gleiches Kästchen = gleicher Wert).
func _hash(cell: Vector2i, salt: int) -> int:
	return absi(hash(Vector3i(cell.x, cell.y, salt + GameState.dungeon_seed)))


## Schatzkisten am Rand der mittleren Räume, mit dem Deckel zur Wand.
func _place_chests() -> void:
	var middle := range(1, _generator.rooms.size() - 1)
	if middle.is_empty():
		return
	middle.shuffle()
	var placed := 0
	for i in middle:
		if placed > 0 and _decor_rng.randf() > chest_chance:
			continue
		var spot := _free_wall_spot(_generator.rooms[i])
		if spot.is_empty():
			continue
		var cell: Vector2i = spot[0]
		var side: Vector2i = spot[1]
		_used_cells[cell] = true
		var chest := Chest.create(GameState.dungeon_level, _decor_rng.randf() < golden_chest_chance)
		geometry.add_child(chest)
		chest.global_position = _cell_to_world(cell) + Vector3(side.x, 0, side.y) * 0.3
		chest.rotation.y = atan2(-side.x, -side.y)
		placed += 1


## Ein freies Bodenkästchen direkt an einer geschlossenen Wand: [Kästchen, Richtung zur Wand] oder [].
func _free_wall_spot(room: Rect2i) -> Array:
	var spots: Array = []
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			var cell := Vector2i(x, y)
			if not _generator.is_floor(cell) or _used_cells.has(cell):
				continue
			for side in [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]:
				if _is_closed_wall(cell, side):
					spots.append([cell, side])
	if spots.is_empty():
		return []
	return spots[_decor_rng.randi() % spots.size()]


func _spawn_enemies() -> void:
	var rooms := _generator.rooms
	# Startraum (0) bleibt leer, damit man in Ruhe ankommt.
	for i in range(1, rooms.size() - 1):
		var count := _rng.randi_range(enemies_per_room_min, enemies_per_room_max)
		for n in count:
			_spawn(ENEMY_SCENE, _generator.random_cell_in(rooms[i], _rng))
		for roll in 2:
			if _rng.randf() < brute_chance:
				_spawn(BRUTE_SCENE, _generator.random_cell_in(rooms[i], _rng, 2))
	var boss_room := _generator.boss_room()
	_boss = _spawn(BOSS_SCENE, boss_room.get_center())
	_boss.died.connect(_on_boss_died.bind(_boss))
	for n in 6:
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
		light.light_energy = 1.0
		light.omni_range = maxf(room.size.x, room.size.y) * cell_size * 0.9
		lights.add_child(light)
		light.global_position = _cell_to_world(room.get_center()) + Vector3(0, 3.5, 0)


func _on_enemy_died() -> void:
	_enemies_left -= 1
	hud.set_enemies_left(_enemies_left)


func _on_boss_died(boss: Node3D) -> void:
	GameState.complete_dungeon()
	var portal := PORTAL_SCENE.instantiate()
	add_child(portal)
	# Etwas neben den Boss stellen, damit die Beute nicht verdeckt wird.
	portal.global_position = boss.global_position + Vector3(3.0, 0, 0)
	if not _generator.is_floor(_world_to_cell(portal.global_position)):
		portal.global_position = _cell_to_world(_generator.boss_room().get_center())
	hud.show_toast("Boss besiegt! Das Portal bringt dich zurück in die Stadt.")


func _world_to_cell(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x / cell_size), floori(pos.z / cell_size))
