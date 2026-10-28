extends GameWindow
## Magischer Ältester: hier lernt und verbessert man Fähigkeiten, wählt pro Fähigkeit
## einen der zwei Skillbäume (oder bleibt bei der Grundform) und wählt bis zu
## PlayerClasses.MAX_PASSIVES passive Fähigkeiten. Nur hier, nirgends sonst.
## Fähigkeitspunkte: 1 pro Stufe. Skillbäume und Passive kann man jederzeit umstellen.

var _info: Label
var _points_label: Label
var _skills_box: VBoxContainer
var _passives_label: Label
var _passives_box: HFlowContainer


func _init() -> void:
	super("Magischer Ältester")


func _build() -> void:
	_info = make_label("", 14)
	content.add_child(_info)
	_points_label = make_label("", 16, Color(0.6, 0.85, 1.0))
	content.add_child(_points_label)
	content.add_child(make_label("Fähigkeiten", 18, Color(0.95, 0.8, 0.5)))
	_skills_box = VBoxContainer.new()
	_skills_box.add_theme_constant_override("separation", 8)
	content.add_child(_skills_box)
	_passives_label = make_label("", 18, Color(0.95, 0.8, 0.5))
	content.add_child(_passives_label)
	_passives_box = HFlowContainer.new()
	_passives_box.custom_minimum_size.x = 420
	_passives_box.add_theme_constant_override("h_separation", 6)
	_passives_box.add_theme_constant_override("v_separation", 6)
	content.add_child(_passives_box)


func refresh() -> void:
	var class_data: Dictionary = PlayerClasses.CLASSES[GameState.player_class]
	_info.text = "Klasse: %s\n%s" % [class_data.name, class_data.text]
	_points_label.text = "Fähigkeitspunkte frei: %d" % _free_points()

	for child in _skills_box.get_children():
		child.queue_free()
	for id in class_data.skills:
		_skills_box.add_child(_make_skill_row(id))
	if class_data.skills.size() <= 1:
		_skills_box.add_child(make_label("Weitere Fähigkeiten folgen bald.", 12, Color(0.6, 0.57, 0.5)))

	_passives_label.text = "Passive Fähigkeiten (%d / %d gewählt)" % [GameState.passives.size(), PlayerClasses.MAX_PASSIVES]
	for child in _passives_box.get_children():
		child.queue_free()
	if class_data.passives.is_empty():
		_passives_box.add_child(make_label("Noch keine passiven Fähigkeiten.", 12, Color(0.6, 0.57, 0.5)))
	for id in class_data.passives:
		var passive: Dictionary = PlayerClasses.PASSIVES[id]
		var button := make_button(passive.name, _toggle_passive.bind(id))
		button.toggle_mode = true
		button.button_pressed = id in GameState.passives
		button.tooltip_text = passive.text
		_passives_box.add_child(button)


## Eine Fähigkeit: Bild, Name, Stufe mit "+" und darunter die Wahl Grundform / Skillbaum 1 / Skillbaum 2.
func _make_skill_row(id: String) -> Control:
	var data := PlayerClasses.skill(id)
	var box := VBoxContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var icon := TextureRect.new()
	icon.texture = data.icon
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var name_label := make_label(data.name, 15)
	name_label.custom_minimum_size.x = 150
	name_label.tooltip_text = data.text
	name_label.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(name_label)
	if data.get("basic_attack", false):
		row.add_child(make_label("Standardangriff (Linksklick)", 13, Color(0.7, 0.68, 0.62)))
	else:
		var level: int = GameState.skill_levels.get(id, 0)
		row.add_child(make_label("Stufe %d / %d" % [level, PlayerClasses.MAX_SKILL_LEVEL], 14, Color(0.7, 0.68, 0.62)))
		var plus := make_button("+", _raise.bind(id))
		plus.disabled = level >= PlayerClasses.MAX_SKILL_LEVEL or _free_points() <= 0
		row.add_child(plus)
	if not data.paths.is_empty():
		var paths := HBoxContainer.new()
		paths.add_theme_constant_override("separation", 6)
		paths.add_child(make_label("Skillbaum:", 13, Color(0.7, 0.68, 0.62)))
		var names: Array = ["Grundform"]
		var texts: Array = [data.text]
		for path in data.paths:
			names.append(path.name)
			texts.append(path.text)
		for i in names.size():
			var button := make_button(names[i], _choose_path.bind(id, i))
			button.toggle_mode = true
			button.button_pressed = GameState.skill_path(id) == i
			button.tooltip_text = texts[i]
			paths.add_child(button)
		box.add_child(paths)
	return box


## 1 Punkt pro Stufe, minus die schon verteilten.
func _free_points() -> int:
	var spent := 0
	for skill in GameState.skill_levels:
		spent += GameState.skill_levels[skill]
	return int(player.experience.level) - spent


func _raise(id: String) -> void:
	if _free_points() <= 0:
		return
	GameState.skill_levels[id] = GameState.skill_levels.get(id, 0) + 1
	show_status("%s ist jetzt Stufe %d." % [PlayerClasses.skill(id).name, GameState.skill_levels[id]])
	GameState.progress_changed.emit()
	refresh()


## Skillbaum wählen (0 = Grundform). Es gilt immer nur einer.
func _choose_path(id: String, path: int) -> void:
	var data := PlayerClasses.skill(id)
	GameState.skill_paths[id] = path
	var path_name: String = "Grundform" if path == 0 else data.paths[path - 1].name
	show_status("%s: %s gewählt." % [data.name, path_name])
	GameState.progress_changed.emit()
	refresh()


func _toggle_passive(id: String) -> void:
	var passive_name: String = PlayerClasses.PASSIVES[id].name
	if id in GameState.passives:
		GameState.passives.erase(id)
		show_status("%s abgelegt." % passive_name)
	elif GameState.passives.size() >= PlayerClasses.MAX_PASSIVES:
		show_status("Du kannst nur %d passive Fähigkeiten wählen." % PlayerClasses.MAX_PASSIVES, true)
	else:
		GameState.passives.append(id)
		show_status("%s gewählt." % passive_name)
	GameState.progress_changed.emit()
	refresh()
