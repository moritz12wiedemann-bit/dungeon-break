class_name MaterialSlot
extends Button
## Kästchen im Reiter "Materialien": Bild des Materials und wie viele man hat.
## Rechts- oder Linksklick wählt es aus (z. B. einen Orb zum Anwenden).

signal selected

var material_id: String
var _count_label := Label.new()
var _icon := TextureRect.new()


func _init(id: String) -> void:
	material_id = id
	custom_minimum_size = Vector2(56, 56)
	focus_mode = Control.FOCUS_NONE
	var info: Dictionary = GameMaterials.INFO[id]
	tooltip_text = "%s\n%s" % [info.name, info.text]
	_icon.texture = info.icon
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in [SIDE_LEFT, SIDE_TOP]:
		_icon.set_offset(side, 6)
	for side in [SIDE_RIGHT, SIDE_BOTTOM]:
		_icon.set_offset(side, -6)
	add_child(_icon)
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count_label.add_theme_font_size_override("font_size", 14)
	_count_label.add_theme_constant_override("outline_size", 5)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_count_label.offset_top = -20
	_count_label.offset_right = -4
	add_child(_count_label)
	pressed.connect(selected.emit)
	gui_input.connect(_on_gui_input)


func set_count(count: int, is_selected: bool) -> void:
	_count_label.text = str(count)
	_icon.modulate = Color.WHITE if count > 0 else Color(1, 1, 1, 0.3)
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.08, 0.07, 0.95).lightened(0.12 if state == "hover" else 0.0)
		style.border_color = Color(0.75, 0.5, 1.0) if is_selected else Color(0.3, 0.27, 0.22)
		style.set_border_width_all(3 if is_selected else 2)
		style.set_corner_radius_all(4)
		add_theme_stylebox_override(state, style)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		selected.emit()
		accept_event()
