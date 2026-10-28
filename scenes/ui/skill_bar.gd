class_name SkillBar
extends HBoxContainer
## Skill-Leiste unten in der Mitte, direkt über dem Erfahrungsbalken:
## 6 Plätze nebeneinander (Q, W, E, R, Linksklick, Rechtsklick).
## Jeder Platz zeigt das Bild der Fähigkeit, die Taste und die Abklingzeit
## (dunkle Fläche, die von oben nach unten schrumpft). Fehlt Mana, wird das Bild blau getönt.
## Beim Drüberfahren mit der Maus erscheint die Beschreibung.
## Klick auf einen Platz öffnet darüber eine Auswahl: welche Fähigkeit soll hier liegen?
## (Standardangriff und alle gelernten Fähigkeiten; liegt sie schon woanders, tauschen die Plätze.)

const SLOT_SIZE := 52.0

var _player: Node = null
var _slots: Array[Panel] = []
var _icons: Array[TextureRect] = []
var _shades: Array[ColorRect] = []
## Auswahl über der Leiste (null = zu). Platz, für den sie offen ist.
var _picker: PanelContainer = null
var _picker_slot: int = -1


func _init() -> void:
	add_theme_constant_override("separation", 6)
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	# Unterkante knapp über dem Erfahrungsbalken (der beginnt 36 px über dem Rand).
	offset_bottom = -42
	offset_top = -42 - SLOT_SIZE
	for slot in PlayerClasses.SLOT_KEYS.size():
		_add_slot(PlayerClasses.SLOT_KEYS[slot])
	var width := SLOT_SIZE * _slots.size() + 6 * (_slots.size() - 1)
	offset_left = -width / 2.0
	offset_right = width / 2.0
	GameState.progress_changed.connect(refresh)


func track_player(player: Node) -> void:
	_player = player
	refresh()


## Zeigt die Fähigkeiten so, wie sie gerade auf der Leiste liegen.
func refresh() -> void:
	for slot in _slots.size():
		var id: String = GameState.skill_bar[slot] if slot < GameState.skill_bar.size() else ""
		var data := PlayerClasses.skill(id)
		_icons[slot].texture = data.get("icon")
		var key: String = PlayerClasses.SLOT_KEYS[slot]
		if data.is_empty():
			_slots[slot].tooltip_text = "%s: noch keine Fähigkeit\n(Klicken, um eine hinzulegen)" % key
		else:
			var text := PlayerClasses.describe_skill(id, GameState.skill_upgrade(id))
			_slots[slot].tooltip_text = "%s\nTaste: %s\n(Klicken zum Ändern)" % [text, key]


func _process(_delta: float) -> void:
	if _player == null:
		return
	for slot in _slots.size():
		var ratio: float = _player.skill_cooldown_ratio(slot)
		_shades[slot].anchor_top = 1.0 - ratio
		var data := PlayerClasses.skill(GameState.skill_bar[slot])
		var short_on_mana: bool = not data.is_empty() and _player.mana < data.mana
		_icons[slot].modulate = Color(0.45, 0.55, 1.0) if short_on_mana else Color.WHITE


func _add_slot(key: String) -> void:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	panel.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.05, 0.9)
	style.border_color = Color(0.55, 0.4, 0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var slot_index := _slots.size()
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			toggle_picker(slot_index)
			panel.accept_event())
	add_child(panel)

	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in [SIDE_LEFT, SIDE_TOP]:
		icon.set_offset(side, 5)
	for side in [SIDE_RIGHT, SIDE_BOTTOM]:
		icon.set_offset(side, -5)
	panel.add_child(icon)

	var shade := ColorRect.new()
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.color = Color(0, 0, 0, 0.65)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.anchor_top = 1.0
	panel.add_child(shade)

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = key
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.6))
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	label.offset_right = -4
	label.offset_bottom = -1
	panel.add_child(label)

	_slots.append(panel)
	_icons.append(icon)
	_shades.append(shade)


## Öffnet (oder schließt) die Auswahl für Platz `slot`.
func toggle_picker(slot: int) -> void:
	var same := _picker_slot == slot
	close_picker()
	if same:
		return
	_picker_slot = slot
	_picker = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.04, 0.95)
	style.border_color = Color(0.55, 0.4, 0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	_picker.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_picker.add_child(box)
	box.add_child(GameWindow.make_label("Fähigkeit für %s:" % PlayerClasses.SLOT_KEYS[slot], 13, Color(0.95, 0.8, 0.5)))
	for id in GameState.usable_skills():
		var data := PlayerClasses.skill(id)
		var button := GameWindow.make_button(data.name, _pick.bind(slot, id))
		button.icon = data.icon
		button.expand_icon = false
		button.add_theme_constant_override("icon_max_width", 28)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.tooltip_text = PlayerClasses.describe_skill(id, GameState.skill_upgrade(id))
		if GameState.skill_bar[slot] == id:
			button.disabled = true
		box.add_child(button)
	if GameState.learned_skills.is_empty():
		box.add_child(GameWindow.make_label("Neue Fähigkeiten lernst du\nbeim magischen Ältesten.", 11, Color(0.6, 0.57, 0.5)))
	box.add_child(GameWindow.make_button("Leer lassen", _pick.bind(slot, "")))
	get_parent().add_child(_picker)
	_picker.reset_size()
	var slot_rect := _slots[slot].get_global_rect()
	_picker.position = Vector2(slot_rect.get_center().x - _picker.size.x / 2.0, slot_rect.position.y - _picker.size.y - 8.0)


## Schließt die Auswahl. Gibt false zurück, wenn keine offen war.
func close_picker() -> bool:
	_picker_slot = -1
	if _picker == null:
		return false
	_picker.queue_free()
	_picker = null
	return true


func _pick(slot: int, id: String) -> void:
	GameState.assign_skill(slot, id)
	close_picker()
