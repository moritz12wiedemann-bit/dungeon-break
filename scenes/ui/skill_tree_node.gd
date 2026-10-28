class_name SkillTreeNode
extends Control
## Ein runder Knoten im Skillbaum (Fähigkeit, Erweiterung oder die Klasse in der Mitte).
## Zeigt ein Bild im Kreis; Rahmen und Helligkeit zeigen, ob er gelernt, lernbar oder gesperrt ist.

## Linksklick (`right` = false) oder Rechtsklick (`right` = true).
signal clicked(right: bool)

enum State { LOCKED, AVAILABLE, LEARNED }

var icon: Texture2D
var radius: float = 20.0
var state: State = State.LOCKED
## Farbe des Rings, in dem der Knoten liegt (Rahmen, wenn gelernt).
var ring_color := Color.WHITE

var _hovered := false


func _init(node_icon: Texture2D, node_radius: float) -> void:
	icon = node_icon
	radius = node_radius
	size = Vector2.ONE * radius * 2.0
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func(): _hovered = true; queue_redraw())
	mouse_exited.connect(func(): _hovered = false; queue_redraw())


## Ändert die Größe (beim Zoomen).
func set_radius(new_radius: float) -> void:
	radius = new_radius
	size = Vector2.ONE * radius * 2.0
	queue_redraw()


## Setzt die Mitte des Knotens auf `point` (im Skillbaum).
func place_at(point: Vector2) -> void:
	position = point - size / 2.0


func set_state(new_state: State) -> void:
	state = new_state
	queue_redraw()


func _has_point(point: Vector2) -> bool:
	return point.distance_to(size / 2.0) <= radius + 2.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(false)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			clicked.emit(true)
			accept_event()


func _draw() -> void:
	var center := size / 2.0
	var border := Color(0.35, 0.33, 0.3)
	var background := Color(0.07, 0.06, 0.06)
	var icon_tint := Color(1, 1, 1, 0.3)
	match state:
		State.AVAILABLE:
			border = Color(0.85, 0.7, 0.35)
			icon_tint = Color(1, 1, 1, 0.75)
		State.LEARNED:
			border = ring_color
			background = Color(0.12, 0.1, 0.08).lerp(ring_color, 0.18)
			icon_tint = Color.WHITE
			# Leuchten um gelernte Knoten.
			draw_circle(center, radius * 1.28, Color(ring_color, 0.18))
			draw_circle(center, radius * 1.14, Color(ring_color, 0.3))
	if _hovered:
		border = border.lightened(0.35)
	draw_circle(center, radius, background)
	if icon:
		var inset := radius * 0.62
		draw_texture_rect(icon, Rect2(center - Vector2.ONE * inset, Vector2.ONE * inset * 2.0), false, icon_tint)
	draw_arc(center, radius, 0.0, TAU, 48, border, maxf(radius / 7.0, 1.5) if state == State.LEARNED else maxf(radius / 10.0, 1.2), true)
