class_name DungeonGenerator
extends RefCounted
## Erzeugt eine zufällige Dungeon-Karte auf einem Raster.
## Ablauf: Räume zufällig verteilen (ohne Überlappung), vom Startraum aus der Reihe nach
## mit Gängen verbinden, der Boss-Raum kommt zuletzt. Ergebnis ist ein Raster aus
## Boden (1) und Wand (0) plus die Liste der Räume.
## Gleicher Zufalls-Startwert (seed) = gleiche Karte.

## Größe des Rasters in Kästchen.
var width: int = 48
var height: int = 48
## Wie viele Räume (inklusive Start und Boss).
var min_rooms: int = 6
var max_rooms: int = 8
## Breite der Gänge in Kästchen.
var corridor_width: int = 3

## cells[y][x] == 1 → Boden (begehbar), 0 → Wand.
var cells: Array[PackedByteArray] = []
## Alle Räume in der Reihenfolge, in der man sie durchläuft (erster = Start, letzter = Boss).
var rooms: Array[Rect2i] = []
## Säulen (einzelne Wand-Kästchen in großen Räumen).
var pillars: Array[Vector2i] = []


func generate(rng: RandomNumberGenerator) -> void:
	cells.clear()
	for y in height:
		var row := PackedByteArray()
		row.resize(width)
		cells.append(row)

	var placed := _place_rooms(rng)
	rooms = _order_rooms(placed)
	for room in rooms:
		_carve_rect(room)
	for i in rooms.size() - 1:
		_carve_corridor(rooms[i].get_center(), rooms[i + 1].get_center(), rng)
	_place_pillars(rng)


func start_room() -> Rect2i:
	return rooms[0]


func boss_room() -> Rect2i:
	return rooms[rooms.size() - 1]


func is_floor(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
		return false
	return cells[cell.y][cell.x] == 1


## Zufälliges Boden-Kästchen in `room`, mit Abstand `margin` zum Rand.
func random_cell_in(room: Rect2i, rng: RandomNumberGenerator, margin: int = 1) -> Vector2i:
	for attempt in 20:
		var cell := Vector2i(
			rng.randi_range(room.position.x + margin, room.end.x - 1 - margin),
			rng.randi_range(room.position.y + margin, room.end.y - 1 - margin))
		if is_floor(cell):
			return cell
	return room.get_center()


func _place_rooms(rng: RandomNumberGenerator) -> Array[Rect2i]:
	var result: Array[Rect2i] = []
	var target := rng.randi_range(min_rooms, max_rooms)
	# Erster Raum wird der große Boss-Raum.
	var sizes := [Vector2i(10, 12)]
	for attempt in 300:
		if result.size() >= target:
			break
		var size_range: Vector2i = sizes[0] if result.is_empty() else Vector2i(5, 9)
		var size := Vector2i(rng.randi_range(size_range.x, size_range.y), rng.randi_range(size_range.x, size_range.y))
		var pos := Vector2i(rng.randi_range(1, width - size.x - 1), rng.randi_range(1, height - size.y - 1))
		var rect := Rect2i(pos, size)
		var free := true
		for other in result:
			if other.grow(3).intersects(rect):
				free = false
				break
		if free:
			result.append(rect)
	return result


## Startraum = am weitesten vom Boss-Raum entfernt. Danach immer der nächstgelegene
## noch nicht besuchte Raum. Der Boss-Raum kommt ans Ende.
func _order_rooms(placed: Array[Rect2i]) -> Array[Rect2i]:
	var boss := placed[0]
	var rest := placed.slice(1)
	rest.sort_custom(func(a, b): return _dist(a, boss) > _dist(b, boss))
	var ordered: Array[Rect2i] = [rest.pop_front()]
	while not rest.is_empty():
		var last: Rect2i = ordered[ordered.size() - 1]
		rest.sort_custom(func(a, b): return _dist(a, last) < _dist(b, last))
		ordered.append(rest.pop_front())
	ordered.append(boss)
	return ordered


func _dist(a: Rect2i, b: Rect2i) -> float:
	return Vector2(a.get_center()).distance_to(Vector2(b.get_center()))


func _carve_rect(rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if x > 0 and y > 0 and x < width - 1 and y < height - 1:
				cells[y][x] = 1


## L-förmiger Gang von a nach b (zufällig erst waagrecht oder erst senkrecht).
func _carve_corridor(a: Vector2i, b: Vector2i, rng: RandomNumberGenerator) -> void:
	var corner := Vector2i(b.x, a.y) if rng.randf() < 0.5 else Vector2i(a.x, b.y)
	_carve_line(a, corner)
	_carve_line(corner, b)


func _carve_line(from: Vector2i, to: Vector2i) -> void:
	var half := corridor_width / 2
	var top_left := Vector2i(mini(from.x, to.x) - half, mini(from.y, to.y) - half)
	var bottom_right := Vector2i(maxi(from.x, to.x) + half, maxi(from.y, to.y) + half)
	_carve_rect(Rect2i(top_left, bottom_right - top_left + Vector2i.ONE))


## In großen Räumen ein paar Säulen, aber nie auf der Mittellinie (dort kommen die Gänge an).
func _place_pillars(rng: RandomNumberGenerator) -> void:
	pillars.clear()
	for i in range(1, rooms.size()):
		var room := rooms[i]
		if room.size.x < 8 or room.size.y < 8 or rng.randf() > 0.6:
			continue
		var center := room.get_center()
		var offset := Vector2i(rng.randi_range(2, room.size.x / 2 - 2), rng.randi_range(2, room.size.y / 2 - 2))
		for sign in [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
			var cell: Vector2i = center + offset * sign
			if absi(cell.x - center.x) > 1 and absi(cell.y - center.y) > 1:
				cells[cell.y][cell.x] = 0
				pillars.append(cell)
