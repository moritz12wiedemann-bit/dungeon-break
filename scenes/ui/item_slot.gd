class_name ItemSlot
extends Button
## Ein Kästchen im Inventar. Zeigt einen Gegenstand als Bildchen (Rahmen und Bild in der
## Farbe der Seltenheit) oder ist leer. Leere Ausrüstungsplätze zeigen ein blasses Bild,
## welcher Gegenstand dort hingehört. Beim Drüberfahren mit der Maus erscheint die Beschreibung.

## Wird bei Rechtsklick ausgelöst (Linksklick ist das normale `pressed`).
signal right_clicked

const RANGE_COLOR := Color(0.55, 0.53, 0.48)

var item: ItemData = null
## Bild im leeren Kästchen (z. B. Helm-Umriss bei Ausrüstungsplätzen). null = leer lassen.
var empty_icon: Texture2D = null
## Text unter dem Bild, z. B. ein Preis beim Händler ("" = keiner).
var caption: String = ""

var _icon := TextureRect.new()
var _caption_label := Label.new()


func _init() -> void:
	custom_minimum_size = Vector2(64, 64)
	focus_mode = Control.FOCUS_NONE
	gui_input.connect(_on_gui_input)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_icon.offset_left = 8
	_icon.offset_top = 8
	_icon.offset_right = -8
	_icon.offset_bottom = -8
	add_child(_icon)
	_caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption_label.add_theme_font_size_override("font_size", 11)
	_caption_label.add_theme_constant_override("outline_size", 4)
	_caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_caption_label.offset_top = -16
	add_child(_caption_label)


## `highlight`: Kästchen hervorheben (z. B. wenn ein Orb darauf angewendet werden kann).
func set_item(new_item: ItemData, highlight: bool = false) -> void:
	item = new_item
	var border := Color(0.3, 0.27, 0.22)
	var background := Color(0.1, 0.08, 0.07, 0.95)
	if item:
		border = item.get_color()
		background = background.lerp(border, 0.15)
		_icon.texture = item.get_icon()
		_icon.modulate = border.lerp(Color.WHITE, 0.25)
		tooltip_text = item.describe()
	else:
		_icon.texture = empty_icon
		_icon.modulate = Color(1, 1, 1, 0.12)
		tooltip_text = ""
	_caption_label.text = caption if item else ""
	if highlight and item:
		border = Color(0.75, 0.5, 1.0)
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = background.lightened(0.12) if state == "hover" else background
		style.border_color = border
		style.set_border_width_all(3 if highlight and item else 2)
		style.set_corner_radius_all(4)
		add_theme_stylebox_override(state, style)


## Eigener Tooltip: Name in der Farbe der Seltenheit, darunter die Werte mit Bereich in Klammern.
func _make_custom_tooltip(for_text: String) -> Object:
	if item == null or for_text == "":
		return null
	return ItemSlot.make_item_tooltip(item)


## Baut die Beschreibung eines Gegenstands (auch für Händler und Schmied nutzbar).
static func make_item_tooltip(shown: ItemData) -> Control:
	var box := VBoxContainer.new()
	box.add_child(_line(shown.item_name, shown.get_color(), 18))
	box.add_child(_line("%s · %s · Stufe %d" % [ItemData.RARITY_NAMES[shown.rarity],
		ItemData.SLOT_NAMES[shown.slot], shown.item_level], Color(0.7, 0.7, 0.7)))
	if shown.set_name != "":
		box.add_child(_line("Set: %s" % shown.set_name, ItemData.RARITY_COLORS[ItemData.Rarity.SET]))
	for stat in shown.sorted_stats():
		var row := HBoxContainer.new()
		row.add_child(_line(shown.stat_text(stat), Color(0.95, 0.95, 0.95) if stat == shown.base_stat else Color(0.55, 0.75, 1.0)))
		row.add_child(_line(shown.range_text(stat), RANGE_COLOR))
		box.add_child(row)
	return box


static func _line(text: String, color: Color, size: int = 14) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	return label


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		right_clicked.emit()
