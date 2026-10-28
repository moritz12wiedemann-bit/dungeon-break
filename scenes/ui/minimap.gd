class_name Minimap
extends Control
## Kleine, leicht durchsichtige Karte oben rechts (nur im Dungeon und im Endlos-Modus).
## Zeigt nur, was man schon gesehen hat: alles im Umkreis von `reveal_radius` Kästchen um
## den Spieler wird aufgedeckt. Der Spieler ist ein Pfeil in der Mitte, der Boss ein roter
## Totenkopf, sobald man seinen Platz aufgedeckt hat.
## Die Karte ist so gedreht wie die Kamera (oben auf der Karte = oben im Bild).
## Wird von hud.gd erzeugt und mit setup() gestartet.

## Größe der Karte in Pixeln.
const MAP_SIZE := 200.0
## Pixel pro Kästchen (größer = näher herangezoomt).
const PIXELS_PER_CELL := 4.0
## So weit (Kästchen) um den Spieler herum wird die Karte aufgedeckt.
const REVEAL_RADIUS := 9
## Gleiche Drehung wie die Iso-Kamera (45 Grad).
const MAP_ROTATION := PI / 4.0
const BACKGROUND := Color(0.0, 0.0, 0.0, 0.4)
const BORDER := Color(0.95, 0.8, 0.5, 0.6)
const FLOOR := Color(0.75, 0.72, 0.65, 0.5)
const WALL := Color(0.95, 0.88, 0.7, 0.85)
const PLAYER := Color(0.4, 0.85, 1.0, 0.95)
const BOSS := Color(0.95, 0.2, 0.15, 0.95)

var _generator: DungeonGenerator
var _cell_size: float = 2.0
var _player: Node3D
var _boss: Node3D
var _image: Image
var _texture: ImageTexture
var _revealed: Dictionary = {}
var _reveal_timer: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -MAP_SIZE - 16.0
	offset_right = -16.0
	offset_top = 12.0
	offset_bottom = 12.0 + MAP_SIZE
	hide()


## Startet die Karte für einen Dungeon. `boss` darf null sein (Endlos-Modus).
func setup(generator: DungeonGenerator, cell_size: float, player: Node3D, boss: Node3D) -> void:
	_generator = generator
	_cell_size = cell_size
	_player = player
	_boss = boss
	_image = Image.create(generator.width, generator.height, false, Image.FORMAT_RGBA8)
	_texture = ImageTexture.create_from_image(_image)
	_reveal_around_player()
	show()


func _process(delta: float) -> void:
	if _player == null:
		return
	_reveal_timer -= delta
	if _reveal_timer <= 0.0:
		_reveal_timer = 0.2
		_reveal_around_player()
	queue_redraw()


## Deckt die Kästchen rund um den Spieler auf: Boden hell, Wände am Rand noch heller.
func _reveal_around_player() -> void:
	var center := _player_cell()
	var changed := false
	for dy in range(-REVEAL_RADIUS, REVEAL_RADIUS + 1):
		for dx in range(-REVEAL_RADIUS, REVEAL_RADIUS + 1):
			if dx * dx + dy * dy > REVEAL_RADIUS * REVEAL_RADIUS:
				continue
			var cell := center + Vector2i(dx, dy)
			if _revealed.has(cell) or cell.x < 0 or cell.y < 0 \
					or cell.x >= _generator.width or cell.y >= _generator.height:
				continue
			_revealed[cell] = true
			if _generator.is_floor(cell):
				_image.set_pixelv(cell, FLOOR)
				changed = true
			elif _touches_floor(cell):
				_image.set_pixelv(cell, WALL)
				changed = true
	if changed:
		_texture.update(_image)


func _touches_floor(cell: Vector2i) -> bool:
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if _generator.is_floor(cell + Vector2i(dx, dy)):
				return true
	return false


func _player_cell() -> Vector2i:
	return Vector2i(floori(_player.global_position.x / _cell_size), floori(_player.global_position.z / _cell_size))


func _draw() -> void:
	if _player == null:
		return
	var center := size / 2.0
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
	# Karte gedreht und so verschoben, dass der Spieler in der Mitte steht.
	var player_pos := Vector2(_player.global_position.x, _player.global_position.z) / _cell_size
	draw_set_transform(center, MAP_ROTATION, Vector2.ONE * PIXELS_PER_CELL)
	draw_texture(_texture, -player_pos)
	draw_set_transform(Vector2.ZERO)

	if is_instance_valid(_boss) and not _boss.is_dead():
		var boss_cell := Vector2i(floori(_boss.global_position.x / _cell_size), floori(_boss.global_position.z / _cell_size))
		if _revealed.has(boss_cell):
			_draw_skull(center + _to_map(Vector2(_boss.global_position.x, _boss.global_position.z) / _cell_size - player_pos))

	# Spieler: Pfeil in Blickrichtung.
	var facing := _to_map(Vector2(sin(_player.rotation.y), cos(_player.rotation.y))).normalized()
	var side := Vector2(-facing.y, facing.x)
	draw_colored_polygon(PackedVector2Array([
		center + facing * 7.0, center - facing * 4.0 + side * 4.5, center - facing * 4.0 - side * 4.5,
	]), PLAYER)
	# Dünner Rahmen, damit man die Karte auch über hellem Boden sieht.
	draw_rect(Rect2(Vector2.ZERO, size), BORDER, false, 2.0)


## Rechnet einen Abstand in Kästchen in Pixel auf der (gedrehten) Karte um.
func _to_map(cells: Vector2) -> Vector2:
	return cells.rotated(MAP_ROTATION) * PIXELS_PER_CELL


## Roter Totenkopf als Boss-Zeichen (gezeichnet, weil die Web-Schrift keine Symbole hat).
func _draw_skull(at: Vector2) -> void:
	var dark := Color(0.1, 0.0, 0.0, 0.9)
	draw_circle(at + Vector2(0, -1), 7.5, dark)
	draw_rect(Rect2(at + Vector2(-5, 2), Vector2(10, 7)), dark)
	draw_circle(at + Vector2(0, -1), 6.0, BOSS)
	draw_rect(Rect2(at + Vector2(-3.5, 2), Vector2(7, 5.5)), BOSS)
	draw_circle(at + Vector2(-2.4, -1.5), 1.7, dark)
	draw_circle(at + Vector2(2.4, -1.5), 1.7, dark)
	draw_line(at + Vector2(0, 4), at + Vector2(0, 7.5), dark, 1.0)
