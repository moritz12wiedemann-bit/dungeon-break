class_name SkillBar
extends HBoxContainer
## Skill-Leiste unten in der Mitte, direkt über dem Erfahrungsbalken:
## 6 Plätze nebeneinander (Q, W, E, R, Linksklick, Rechtsklick).
## Jeder Platz zeigt das Bild der Fähigkeit, die Taste und die Abklingzeit
## (dunkle Fläche, die von oben nach unten schrumpft). Fehlt Mana, wird das Bild blau getönt.
## Beim Drüberfahren mit der Maus erscheint die Beschreibung.

const SLOT_SIZE := 52.0

var _player: Node = null
var _slots: Array[Panel] = []
var _icons: Array[TextureRect] = []
var _shades: Array[ColorRect] = []


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
			_slots[slot].tooltip_text = "%s: noch keine Fähigkeit" % key
		else:
			var text := PlayerClasses.describe_skill(id, GameState.skill_path(id), GameState.skill_levels.get(id, 0))
			_slots[slot].tooltip_text = "%s\nTaste: %s" % [text, key]


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
