class_name SkillTree
extends Control
## Der Skillbaum als Kreis (beim magischen Ältesten):
## - Ringe von innen nach außen: Basis-Skills, Core-Skills, Mobility, Buffs, Ultimate-Skills.
## - Rote Linien teilen ihn in drei Bereiche: unten die Fähigkeiten, die jeder hat,
##   rechts und links die beiden Unterklassen.
## - In der Mitte die Klasse, davon gehen die Fähigkeiten ab, an jeder hängen ihre
##   zwei Erweiterungen (nur eine wählbar).
## Linksklick lernt bzw. wählt, Rechtsklick verlernt. Was ein Klick bewirkt, entscheidet
## das Fenster (Signale skill_clicked / upgrade_clicked).
## Mausrad zoomt (zum Mauszeiger hin), Ziehen mit gedrückter Maustaste auf freier Fläche verschiebt.
## Alle Maße unten sind "Baum-Einheiten" (Mitte = 0); _to_screen() rechnet sie mit Zoom und
## Verschiebung in Pixel um.

signal skill_clicked(skill_id: String, right: bool)
signal upgrade_clicked(skill_id: String, upgrade: int, right: bool)

const TREE_SIZE := 520.0
## Außenradius jedes Rings (Pixel), passend zu PlayerClasses.RINGS.
const RING_RADII := [108.0, 170.0, 205.0, 234.0, 256.0]
## Bereiche: Mitte und Breite (Grad; 0 = rechts, 90 = unten).
const SECTORS := {
	"base": {"center": 90.0, "span": 120.0},
	"right": {"center": -30.0, "span": 120.0},
	"left": {"center": 210.0, "span": 120.0},
}
const LINE_COLOR := Color(0.85, 0.18, 0.15)
const SKILL_RADIUS := 18.0
const UPGRADE_RADIUS := 12.0
const CENTER_RADIUS := 27.0
const MIN_ZOOM := 0.6
const MAX_ZOOM := 4.0

## Zoom relativ zu "passt genau ins Fenster" (1 = ganzer Baum sichtbar).
var zoom := 1.0
## Verschiebung der Mitte in Pixeln.
var pan := Vector2.ZERO
var _dragging := false

var _class_id := ""
## Fähigkeit → {"node": SkillTreeNode, "upgrades": [SkillTreeNode, SkillTreeNode], "ring": int}
var _nodes: Dictionary = {}
## Knoten → {"pos": Vector2 in Baum-Einheiten, "radius": float}
var _layout_info: Dictionary = {}
var _center_node: SkillTreeNode


func _init() -> void:
	custom_minimum_size = Vector2(400, 400)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	resized.connect(_layout)


## Zoom und Verschiebung zurück auf "ganzer Baum sichtbar".
func reset_view() -> void:
	zoom = 1.0
	pan = Vector2.ZERO
	_layout()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var old_scale := _z()
			zoom = clampf(zoom * (1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15), MIN_ZOOM, MAX_ZOOM)
			# Der Punkt unter dem Mauszeiger bleibt, wo er ist.
			var center := size / 2.0 + pan
			var new_center: Vector2 = event.position - (event.position - center) * (_z() / old_scale)
			pan = new_center - size / 2.0
			_layout()
			accept_event()
		elif event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_dragging = event.pressed
			mouse_default_cursor_shape = Control.CURSOR_DRAG if _dragging else Control.CURSOR_ARROW
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		pan += event.relative
		_layout()
		accept_event()


## Pixel pro Baum-Einheit.
func _z() -> float:
	return minf(size.x, size.y) / (TREE_SIZE + 20.0) * zoom


func _to_screen(point: Vector2) -> Vector2:
	return size / 2.0 + pan + point * _z()


## Setzt alle Knoten passend zu Zoom und Verschiebung.
func _layout() -> void:
	for node in _layout_info:
		if not is_instance_valid(node):
			continue
		var info: Dictionary = _layout_info[node]
		node.set_radius(info.radius * _z())
		node.place_at(_to_screen(info.pos))
	queue_redraw()


func _add_node(node: SkillTreeNode, pos: Vector2, radius: float) -> void:
	_layout_info[node] = {"pos": pos, "radius": radius}
	add_child(node)


## Baut die Knoten für die Klasse `class_id` auf.
func build(class_id: String) -> void:
	_class_id = class_id
	for child in get_children():
		child.queue_free()
	_nodes.clear()
	_layout_info.clear()
	var class_data: Dictionary = PlayerClasses.CLASSES[class_id]
	_center_node = SkillTreeNode.new(class_data.icon, CENTER_RADIUS)
	_center_node.state = SkillTreeNode.State.LEARNED
	_center_node.ring_color = Color(0.95, 0.8, 0.5)
	_center_node.tooltip_text = "%s\n%s" % [class_data.name, class_data.text]
	_center_node.mouse_default_cursor_shape = Control.CURSOR_ARROW
	_add_node(_center_node, Vector2.ZERO, CENTER_RADIUS)

	# Fähigkeiten nach Bereich und Ring sortieren und gleichmäßig verteilen.
	var groups := {}
	for id in class_data.skills:
		var data := PlayerClasses.skill(id)
		var key := "%s/%d" % [data.sector, data.ring]
		if not groups.has(key):
			groups[key] = []
		groups[key].append(id)
	for key in groups:
		var ids: Array = groups[key]
		for i in ids.size():
			_add_skill(ids[i], i, ids.size())
	_layout()


## Zeigt an, was gelernt ist und was gelernt werden kann.
func refresh(free_points: int) -> void:
	for id in _nodes:
		var data := PlayerClasses.skill(id)
		var learned: bool = id in GameState.learned_skills
		var node: SkillTreeNode = _nodes[id].node
		var ring: int = data.get("ring", 0)
		var unlocked := GameState.ring_unlocked(ring)
		var hint := "Gelernt. Rechtsklick: verlernen (Punkt zurück)."
		if learned:
			node.set_state(SkillTreeNode.State.LEARNED)
		elif not unlocked:
			node.set_state(SkillTreeNode.State.LOCKED)
			hint = "Gesperrt: erst ab %d Punkten in den inneren Ringen (%d ausgegeben)." % [
				GameState.ring_requirement(ring), GameState.points_below_ring(ring)]
		else:
			node.set_state(SkillTreeNode.State.AVAILABLE if free_points > 0 else SkillTreeNode.State.LOCKED)
			hint = "Linksklick: lernen (1 Punkt)." if free_points > 0 else "Kein Punkt frei."
		node.tooltip_text = "%s\n\n%s" % [PlayerClasses.describe_skill(id, 0, _class_id), hint]
		var chosen := GameState.skill_upgrade(id)
		for i in _nodes[id].upgrades.size():
			var upgrade_node: SkillTreeNode = _nodes[id].upgrades[i]
			var upgrade: Dictionary = data.upgrades[i]
			var upgrade_hint := ""
			if chosen == i + 1:
				upgrade_node.set_state(SkillTreeNode.State.LEARNED)
				upgrade_hint = "Gewählt. Rechtsklick: ablegen (Punkt zurück)."
			elif learned and (chosen > 0 or free_points > 0):
				upgrade_node.set_state(SkillTreeNode.State.AVAILABLE)
				upgrade_hint = "Linksklick: stattdessen wählen (kostenlos)." if chosen > 0 else "Linksklick: wählen (1 Punkt)."
			else:
				upgrade_node.set_state(SkillTreeNode.State.LOCKED)
				upgrade_hint = "Erst %s lernen." % data.name if not learned else "Kein Punkt frei."
			upgrade_node.tooltip_text = "%s (Erweiterung von %s)\n%s\nNur eine der beiden Erweiterungen gilt.\n\n%s" % [
				upgrade.name, data.name, upgrade.text, upgrade_hint]
	queue_redraw()


func _add_skill(id: String, index: int, count: int) -> void:
	var data := PlayerClasses.skill(id)
	var ring: int = data.ring
	var sector: Dictionary = SECTORS[data.sector]
	var inner: float = 0.0 if ring == 0 else RING_RADII[ring - 1]
	var outer: float = RING_RADII[ring]
	var skill_distance := 62.0 if ring == 0 else inner + 22.0
	var upgrade_distance := 92.0 if ring == 0 else outer - 14.0
	# Abstand zwischen den Fähigkeiten im selben Ring: so viel, dass die Erweiterungen nicht überlappen.
	var step := minf(rad_to_deg((50.0 if ring == 0 else 64.0) / skill_distance), sector.span * 0.8 / count)
	# Erste Fähigkeit links, dann nach rechts (im unteren Bereich heißt das: größerer Winkel zuerst).
	var angle := deg_to_rad(sector.center - (index - (count - 1) / 2.0) * step)
	var ring_color: Color = PlayerClasses.RINGS[ring].color

	var node := SkillTreeNode.new(data.icon, SKILL_RADIUS)
	node.ring_color = ring_color
	node.clicked.connect(func(right: bool): skill_clicked.emit(id, right))
	_add_node(node, Vector2.from_angle(angle) * skill_distance, SKILL_RADIUS)
	var upgrade_nodes: Array[SkillTreeNode] = []
	var spread := 20.0 / upgrade_distance
	for i in data.upgrades.size():
		var upgrade_angle := angle + (spread if i == 0 else -spread)
		var upgrade_node := SkillTreeNode.new(data.upgrades[i].icon, UPGRADE_RADIUS)
		upgrade_node.ring_color = ring_color
		upgrade_node.clicked.connect(func(right: bool): upgrade_clicked.emit(id, i + 1, right))
		_add_node(upgrade_node, Vector2.from_angle(upgrade_angle) * upgrade_distance, UPGRADE_RADIUS)
		upgrade_nodes.append(upgrade_node)
	_nodes[id] = {"node": node, "upgrades": upgrade_nodes, "ring": ring}


func _center() -> Vector2:
	return _to_screen(Vector2.ZERO)


func _draw() -> void:
	var center := _center()
	var z := _z()
	var font := get_theme_default_font()
	# Hintergrund (auch zum Anfassen beim Ziehen).
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.025, 0.025, 0.6))
	# Ringe als leicht getönte Flächen, von außen nach innen.
	for ring in range(RING_RADII.size() - 1, -1, -1):
		var color: Color = PlayerClasses.RINGS[ring].color
		draw_circle(center, RING_RADII[ring] * z, Color(0.06, 0.05, 0.05).lerp(color, 0.07))
	for ring in RING_RADII.size():
		var color: Color = PlayerClasses.RINGS[ring].color
		draw_arc(center, RING_RADII[ring] * z, 0.0, TAU, 160, Color(color, 0.85), maxf(2.0 * z, 1.0), true)

	# Unterklassen-Bereiche abdunkeln, solange sie noch keine Fähigkeiten haben.
	var subclasses: Dictionary = PlayerClasses.CLASSES[_class_id].subclasses if _class_id != "" else {}
	for side in ["left", "right"]:
		_draw_sector_shade(SECTORS[side])

	# Rote Trennlinien zwischen den Bereichen.
	for angle in [30.0, 150.0, 270.0]:
		draw_line(center, center + Vector2.from_angle(deg_to_rad(angle)) * (RING_RADII[-1] + 6.0) * z, LINE_COLOR, maxf(2.0 * z, 1.0), true)

	# Verbindungslinien: Mitte → Fähigkeit → Erweiterungen.
	for id in _nodes:
		var node: SkillTreeNode = _nodes[id].node
		var node_center := node.position + node.size / 2.0
		var learned := node.state == SkillTreeNode.State.LEARNED
		# Fähigkeiten in äußeren Ringen hängen am Rand des Rings davor.
		var ring: int = _nodes[id].ring
		var start: Vector2 = center if ring == 0 else center + (node_center - center).normalized() * RING_RADII[ring - 1] * z
		draw_line(start, node_center, Color(node.ring_color, 0.9) if learned else Color(0.5, 0.48, 0.44, 0.6), maxf((2.5 if learned else 1.5) * z, 1.0), true)
		for upgrade_node in _nodes[id].upgrades:
			var upgrade_center: Vector2 = upgrade_node.position + upgrade_node.size / 2.0
			var chosen: bool = upgrade_node.state == SkillTreeNode.State.LEARNED
			draw_line(node_center, upgrade_center, Color(node.ring_color, 0.9) if chosen else Color(0.5, 0.48, 0.44, 0.5), maxf((2.0 if chosen else 1.2) * z, 1.0), true)

	# Namen der Ringe oben auf der senkrechten Linie.
	for ring in RING_RADII.size():
		var inner: float = 30.0 if ring == 0 else RING_RADII[ring - 1]
		var middle: float = 86.0 if ring == 0 else (inner + RING_RADII[ring]) / 2.0
		_draw_tag(font, PlayerClasses.RINGS[ring].name, center + Vector2(0, -middle) * z, PlayerClasses.RINGS[ring].color, 11)

	# Namen der Bereiche.
	if _class_id != "":
		_draw_tag(font, PlayerClasses.CLASSES[_class_id].name, center + Vector2(0, RING_RADII[-1] - 18.0) * z, Color(0.95, 0.8, 0.5), 15)
		for side in ["left", "right"]:
			var sector: Dictionary = SECTORS[side]
			var point := center + Vector2.from_angle(deg_to_rad(sector.center)) * 165.0 * z
			_draw_tag(font, subclasses.get(side, ""), point + Vector2(0, -9) * z, Color(0.8, 0.76, 0.68), 14)
			_draw_tag(font, "kommt später", point + Vector2(0, 10) * z, Color(0.55, 0.52, 0.48), 11)


func _draw_sector_shade(sector: Dictionary) -> void:
	var center := _center()
	var points := PackedVector2Array([center])
	var start: float = sector.center - sector.span / 2.0
	for i in 33:
		var angle := deg_to_rad(start + sector.span * i / 32.0)
		points.append(center + Vector2.from_angle(angle) * RING_RADII[-1] * _z())
	draw_colored_polygon(points, Color(0, 0, 0, 0.35))


## Text mit dunklem Kästchen dahinter, mittig auf `point`.
func _draw_tag(font: Font, text: String, point: Vector2, color: Color, base_size: int) -> void:
	if text == "":
		return
	# Schrift wächst mit dem Zoom mit (scharf, weil in echter Größe gezeichnet).
	var font_size := clampi(int(round(base_size * _z())), 8, 48)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var box := Rect2(point - text_size / 2.0 - Vector2(5, 1), text_size + Vector2(10, 2))
	draw_rect(box, Color(0.05, 0.04, 0.04, 0.85))
	draw_rect(box, Color(color, 0.5), false, 1.0)
	draw_string(font, Vector2(point.x - text_size.x / 2.0, point.y + text_size.y / 2.0 - font.get_descent(font_size)),
		text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
