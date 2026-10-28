extends Node3D
## Stadt (Hub): sicherer Ort ohne Gegner. Der Dungeon-Altar öffnet einen neuen Dungeon.
## Mit Taste T kommt man aus jedem Dungeon hierher zurück.
##
## Häuser, Figuren, Altäre und Möbel stehen als normale Knoten in town.tscn.
## Der Boden (Pflaster, Erde, Wiese) und der Wald mit Büschen und Pflanzen rundherum werden
## beim Start aus den Einstellungen unten gebaut (gebündelt gezeichnet, das ist viel schneller
## als Tausende einzelne Knoten).

const VILLAGE := "res://assets/models/quaternius/village/"
const NATURE := "res://assets/models/quaternius/nature/"
const TILE := 2.0
const TREES := ["CommonTree_1", "CommonTree_2", "CommonTree_3", "CommonTree_4", "CommonTree_5",
	"Pine_1", "Pine_2", "Pine_3", "Pine_5"]
## Pflanzen im Wald: [Modell, Größe von, Größe bis].
const PLANTS := [
	["Bush_Common", 0.8, 1.3], ["Bush_Common_Flowers", 0.8, 1.2], ["Fern_1", 0.7, 1.1],
	["Plant_1", 0.8, 1.2], ["Plant_7", 0.9, 1.4], ["Grass_Common_Short", 0.8, 1.2],
	["Grass_Common_Tall", 0.7, 1.0], ["Grass_Wispy_Short", 0.8, 1.2], ["Flower_3_Group", 0.5, 0.8],
	["Flower_4_Group", 0.5, 0.8], ["Clover_1", 0.6, 0.9], ["Mushroom_Common", 0.6, 1.0],
]
## Ein bisschen Grün und Steinchen in der Stadt (auf der Erde, nicht auf dem Pflaster).
const TOWN_PLANTS := [["Grass_Common_Short", 0.5, 0.8], ["Grass_Wispy_Short", 0.5, 0.8],
	["Pebble_Round_1", 1.0, 1.6], ["Pebble_Round_3", 1.0, 1.6], ["Plant_7", 0.6, 0.9]]

## Halbe Kantenlänge der Stadt innerhalb des Zauns (in Metern).
@export var town_half_size: float = 20.0
## Halbe Kantenlänge des ganzen Bodens (Wiese und Wald bis hierhin).
@export var world_half_size: float = 46.0
## Gepflasterte Flächen (Platz, Straßen, Höfe) als Rechtecke: x, z, Breite, Tiefe.
@export var paved_areas: Array[Rect2] = []
## Stellen im Wald ohne Bäume (z. B. um Häuser): x, z = Mitte, Breite = Radius.
@export var clearings: Array[Rect2] = []
@export var forest_seed: int = 7
## Bäume pro 100 m² Wald.
@export var tree_density: float = 1.4
## Pflanzen pro 100 m² Wald.
@export var plant_density: float = 9.0
## Farbe von Erde (in der Stadt) und Wiese (außerhalb).
@export var earth_color: Color = Color(0.2, 0.17, 0.14)
@export var grass_color: Color = Color(0.2, 0.3, 0.11)

@onready var nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $HUD

var _batch := ModelBatch.new()
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_build_ground_and_forest()
	nav_region.bake_navigation_mesh(false)
	hud.track_player(player)
	hud.set_location("Stadt")
	hud.show_toast("Klicke auf den Dungeon-Altar, um einen Dungeon zu betreten.")


func _build_ground_and_forest() -> void:
	_rng.seed = forest_seed
	var plane := PlaneMesh.new()
	plane.size = Vector2(TILE, TILE)
	var earth := _tile_material(earth_color)
	var grass := _tile_material(grass_color)
	var cobble := VILLAGE + "Floor_UnevenBrick.gltf"
	var steps := int(world_half_size / TILE)
	for iz in range(-steps, steps):
		for ix in range(-steps, steps):
			var center := Vector3((ix + 0.5) * TILE, 0.0, (iz + 0.5) * TILE)
			var inside := absf(center.x) < town_half_size and absf(center.z) < town_half_size
			var turn := Basis(Vector3.UP, (_rng.randi() % 4) * PI / 2.0)
			if inside and _is_paved(center):
				# Die Pflasterplatte liegt einen Hauch über der Erde, damit nichts flimmert.
				_batch.add(cobble, Transform3D(turn, center + Vector3(0, 0.01, 0)))
			elif inside:
				_batch.add_mesh("earth", plane, Transform3D(turn, center))
				_batch_color("earth", earth, 0.1)
				if _rng.randf() < 0.07 and not _near_fence(center):
					_add_plant(TOWN_PLANTS, center)
			else:
				_batch.add_mesh("grass", plane, Transform3D(turn, center))
				_batch_color("grass", grass, 0.12)
				_add_forest_cell(center)
	_batch.build($Decor)


## Bäume und Pflanzen in einem Bodenfeld außerhalb des Zauns.
func _add_forest_cell(center: Vector3) -> void:
	var area := TILE * TILE / 100.0
	var edge := maxf(absf(center.x), absf(center.z)) - town_half_size
	# Direkt am Zaun nur Büsche und Gras, Bäume erst ab 3 m Abstand.
	if edge > 3.0 and _rng.randf() < tree_density * area and _free_of_clearings(center, 3.0):
		var tree: String = TREES[_rng.randi() % TREES.size()]
		var where := center + Vector3(_rng.randf_range(-0.8, 0.8), 0, _rng.randf_range(-0.8, 0.8))
		var size := _rng.randf_range(0.55, 0.85)
		_batch.add(NATURE + tree + ".gltf", Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * size), where))
	var count := _rng.randf() * plant_density * area * 2.0
	while count > 0.5:
		count -= 1.0
		if _free_of_clearings(center, 1.5):
			_add_plant(PLANTS, center)


func _add_plant(list: Array, center: Vector3) -> void:
	var plant: Array = list[_rng.randi() % list.size()]
	var where := center + Vector3(_rng.randf_range(-0.9, 0.9), 0, _rng.randf_range(-0.9, 0.9))
	var size := _rng.randf_range(plant[1], plant[2])
	_batch.add(NATURE + plant[0] + ".gltf", Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * size), where))


## Das zuletzt hinzugefügte Bodenfeld etwas heller/dunkler machen (keine verschwommene Textur,
## sondern jedes Feld hat einen leicht anderen Farbton).
func _batch_color(key: String, material: Material, amount: float) -> void:
	_batch.set_material(key, material)
	var shade := 1.0 + _rng.randf_range(-amount, amount)
	var hue := _rng.randf_range(-amount, amount) * 0.4
	_batch.set_last_color(key, Color(shade + hue, shade, shade - hue))


func _tile_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	return material


func _is_paved(point: Vector3) -> bool:
	for rect in paved_areas:
		if rect.has_point(Vector2(point.x, point.z)):
			return true
	return false


func _near_fence(point: Vector3) -> bool:
	return maxf(absf(point.x), absf(point.z)) > town_half_size - 1.5


func _free_of_clearings(point: Vector3, margin: float) -> bool:
	for c in clearings:
		if Vector2(point.x, point.z).distance_to(c.position) < c.size.x + margin:
			return false
	return true
