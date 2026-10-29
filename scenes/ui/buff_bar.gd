class_name BuffBar
extends HBoxContainer
## Kleine Buff-Leiste direkt über der Skill-Leiste: ein Bild pro aktivem Buff
## (siehe PlayerClasses.BUFFS) mit der Zahl der Stacks bzw. den restlichen Sekunden unten rechts.

const ICON_SIZE := 30.0

var _player: Node = null
## Buff → Panel mit Bild und Zahl.
var _shown: Dictionary = {}


func _init() -> void:
	add_theme_constant_override("separation", 4)
	alignment = BoxContainer.ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	# Über der Skill-Leiste (die endet 42 + 52 px über dem Rand).
	offset_bottom = -100
	offset_top = -100 - ICON_SIZE
	offset_left = -200
	offset_right = 200


func track_player(player: Node) -> void:
	_player = player


func _process(_delta: float) -> void:
	if _player == null:
		return
	for id in _shown.keys():
		if not _player.buffs.has(id):
			_shown[id].queue_free()
			_shown.erase(id)
	for id in _player.buffs:
		if not _shown.has(id):
			_shown[id] = _make_icon(id)
		var label: Label = _shown[id].get_child(1)
		var buff: Dictionary = _player.buffs[id]
		# Buffs mit Laufzeit zeigen die restlichen Sekunden, die anderen ihre Stacks.
		# Buffs ohne Ende (Auren, gehaltene Fähigkeiten) zeigen nichts.
		if buff.has("time"):
			label.text = "%ds" % ceili(buff.time) if buff.time < 10000.0 else ""
		else:
			label.text = str(buff.stacks)


func _make_icon(id: String) -> Panel:
	var data: Dictionary = PlayerClasses.BUFFS[id]
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2.ONE * ICON_SIZE
	panel.tooltip_text = "%s\n%s" % [data.name, data.text]
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.05, 0.85)
	style.border_color = Color(0.85, 0.55, 0.25)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", style)
	var icon := TextureRect.new()
	icon.texture = data.icon
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in [SIDE_LEFT, SIDE_TOP]:
		icon.set_offset(side, 3)
	for side in [SIDE_RIGHT, SIDE_BOTTOM]:
		icon.set_offset(side, -3)
	panel.add_child(icon)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_constant_override("outline_size", 4)
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	label.offset_right = -2
	label.offset_bottom = 2
	panel.add_child(label)
	add_child(panel)
	return panel
