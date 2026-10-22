class_name ItemSlot
extends Button
## Ein Kästchen im Inventar. Zeigt einen Gegenstand (Rahmen in der Farbe der Seltenheit)
## oder ist leer. Beim Drüberfahren mit der Maus erscheint die Beschreibung.

## Wird bei Rechtsklick ausgelöst (Linksklick ist das normale `pressed`).
signal right_clicked

const SHORT_NAMES := {
	ItemData.Slot.HELM: "Helm",
	ItemData.Slot.GLOVES: "Handsch.",
	ItemData.Slot.ARMOR: "Rüstung",
	ItemData.Slot.PANTS: "Hose",
	ItemData.Slot.BOOTS: "Schuhe",
	ItemData.Slot.WEAPON: "Waffe",
}

var item: ItemData = null
## Text, der im leeren Kästchen steht (z. B. "Helm" bei Ausrüstungsplätzen).
var empty_text: String = ""


func _init() -> void:
	custom_minimum_size = Vector2(64, 64)
	focus_mode = Control.FOCUS_NONE
	clip_text = true
	add_theme_font_size_override("font_size", 12)
	gui_input.connect(_on_gui_input)


func set_item(new_item: ItemData) -> void:
	item = new_item
	var border := Color(0.3, 0.27, 0.22)
	var background := Color(0.1, 0.08, 0.07, 0.95)
	if item:
		text = SHORT_NAMES[item.slot]
		border = item.get_color()
		background = background.lerp(border, 0.18)
		tooltip_text = item.describe()
		add_theme_color_override("font_color", border)
	else:
		text = empty_text
		tooltip_text = ""
		add_theme_color_override("font_color", Color(0.45, 0.42, 0.38))
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = background.lightened(0.12) if state == "hover" else background
		style.border_color = border
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		add_theme_stylebox_override(state, style)


## Eigener Tooltip: Name in der Farbe der Seltenheit, darunter die Werte.
func _make_custom_tooltip(for_text: String) -> Object:
	if item == null or for_text == "":
		return null
	var box := VBoxContainer.new()
	var lines := for_text.split("\n")
	for i in lines.size():
		var label := Label.new()
		label.text = lines[i]
		if i == 0:
			label.add_theme_color_override("font_color", item.get_color())
			label.add_theme_font_size_override("font_size", 18)
		elif i == 1:
			label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		elif lines[i].begins_with("Set:"):
			label.add_theme_color_override("font_color", ItemData.RARITY_COLORS[ItemData.Rarity.SET])
		box.add_child(label)
	return box


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		right_clicked.emit()
