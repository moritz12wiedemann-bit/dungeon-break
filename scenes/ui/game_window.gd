class_name GameWindow
extends PanelContainer
## Grundgerüst für Fenster wie Schmied oder Händler: Titel, Schließen-Knopf, Inhalt.
## Steht links in der Mitte (das Inventar ist rechts). Schließt sich mit Escape, mit dem
## Knopf oder von selbst, wenn der Spieler sich von der Figur entfernt.
## Eigene Fenster erben davon, bauen ihren Inhalt in _build() in `content` und
## aktualisieren ihn in refresh().

## Ab dieser Entfernung (Meter) zur Figur schließt sich das Fenster.
const CLOSE_DISTANCE := 6.0

var content := VBoxContainer.new()
var player: Node = null
## Die Figur, zu der das Fenster gehört (null = keine).
var source: Node3D = null

var _title := Label.new()
var _status := Label.new()


func _init(title: String) -> void:
	hide()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.04, 0.95)
	style.border_color = Color(0.55, 0.4, 0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style)
	set_anchors_preset(Control.PRESET_CENTER_LEFT)
	offset_left = 16
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	_title.text = title
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_color_override("font_color", Color(0.95, 0.8, 0.5))
	_title.add_theme_font_size_override("font_size", 22)
	header.add_child(_title)
	var close := Button.new()
	close.text = "✕"
	close.focus_mode = Control.FOCUS_NONE
	close.tooltip_text = "Schließen (Esc)"
	close.pressed.connect(hide)
	header.add_child(close)
	content.add_theme_constant_override("separation", 10)
	box.add_child(content)
	_status.add_theme_font_size_override("font_size", 13)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status)
	_build()
	# Bleibt senkrecht in der Mitte, auch wenn sich der Inhalt ändert.
	minimum_size_changed.connect(func(): _recenter.call_deferred())


## Hier bauen erbende Fenster ihren Inhalt in `content`.
func _build() -> void:
	pass


## Zeigt den aktuellen Stand an (wird beim Öffnen und bei jeder Änderung im Inventar aufgerufen).
func refresh() -> void:
	pass


func open(for_player: Node, from: Node3D) -> void:
	if player != for_player:
		player = for_player
		player.inventory.changed.connect(_on_inventory_changed)
	source = from
	_status.text = ""
	show()
	refresh()
	_recenter.call_deferred()


func _recenter() -> void:
	reset_size()
	offset_top = -size.y / 2.0
	offset_bottom = size.y / 2.0


func _process(_delta: float) -> void:
	if not visible or source == null or player == null:
		return
	if not is_instance_valid(source) or player.global_position.distance_to(source.global_position) > CLOSE_DISTANCE:
		hide()


func show_status(text: String, is_error: bool = false) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", Color(1, 0.45, 0.4) if is_error else Color(0.6, 1, 0.6))


func _on_inventory_changed() -> void:
	if visible:
		refresh()


# --- Bausteine für erbende Fenster ---

static func make_label(text: String, size: int = 14, color: Color = Color(0.85, 0.82, 0.75)) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


static func make_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button


## Raster mit den Plätzen der Tasche. `on_click(index)` wird bei Linksklick aufgerufen.
func make_bag_grid(slot_count: int, on_click: Callable) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 6
	for i in slot_count:
		var slot := ItemSlot.new()
		slot.custom_minimum_size = Vector2(56, 56)
		slot.pressed.connect(on_click.bind(i))
		grid.add_child(slot)
	return grid


## Zeigt die Tasche des Spielers im Raster. `caption_for(item) -> String` liefert die Zeile darunter.
func fill_bag_grid(grid: GridContainer, caption_for: Callable = Callable()) -> void:
	var bag: Array[ItemData] = player.inventory.bag
	for i in grid.get_child_count():
		var slot: ItemSlot = grid.get_child(i)
		var item: ItemData = bag[i] if i < bag.size() else null
		slot.caption = caption_for.call(item) if item and caption_for.is_valid() else ""
		slot.set_item(item)
