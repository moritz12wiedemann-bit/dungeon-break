extends GameWindow
## Magischer Ältester: großes Fenster mit dem Skillbaum (siehe SkillTree).
## Nur hier verteilt man Fähigkeitspunkte (1 pro Stufe): Fähigkeiten lernen, pro Fähigkeit
## eine von zwei Erweiterungen wählen, bis zu PlayerClasses.MAX_PASSIVES Passive wählen.
## Auf die Skill-Leiste legt man die Fähigkeiten überall (Klick auf einen Platz der Leiste).

var _tree := SkillTree.new()
var _class_label: Label
var _class_text: Label
var _points_label: Label
var _passives_label: Label
var _passives_box: HFlowContainer


func _init() -> void:
	super("Magischer Ältester")
	# Fast der ganze Bildschirm (mit kleinem Rand).
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 16
	offset_top = 16
	offset_right = -16
	offset_bottom = -16
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL


func _build() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(row)
	_tree.skill_clicked.connect(_on_skill_clicked)
	_tree.upgrade_clicked.connect(_on_upgrade_clicked)
	row.add_child(_tree)

	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 250
	side.add_theme_constant_override("separation", 8)
	row.add_child(side)
	_class_label = make_label("", 22, Color(0.95, 0.8, 0.5))
	side.add_child(_class_label)
	_class_text = make_label("", 13)
	_class_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_class_text)
	_points_label = make_label("", 18, Color(0.6, 0.85, 1.0))
	side.add_child(_points_label)
	var help := make_label("Linksklick: lernen bzw. Erweiterung wählen\nRechtsklick: verlernen (Punkt zurück)\n"
		+ "Mausrad: zoomen, Ziehen: verschieben\n\n"
		+ "Jede Fähigkeit hat zwei Erweiterungen, es gilt immer nur eine.\n\n"
		+ "Gelernte Fähigkeiten legst du auf die Skill-Leiste, indem du unten auf einen Platz klickst.", 12, Color(0.7, 0.68, 0.62))
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(help)

	side.add_child(HSeparator.new())
	_passives_label = make_label("", 16, Color(0.95, 0.8, 0.5))
	side.add_child(_passives_label)
	_passives_box = HFlowContainer.new()
	_passives_box.add_theme_constant_override("h_separation", 6)
	_passives_box.add_theme_constant_override("v_separation", 6)
	side.add_child(_passives_box)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(spacer)
	side.add_child(make_button("Ansicht zurücksetzen", _tree.reset_view))
	side.add_child(make_button("Alle Punkte zurücksetzen", _reset))


func open(for_player: Node, from: Node3D) -> void:
	_tree.build(GameState.player_class)
	_tree.reset_view()
	super(for_player, from)


func refresh() -> void:
	var class_data: Dictionary = PlayerClasses.CLASSES[GameState.player_class]
	_class_label.text = class_data.name
	_class_text.text = class_data.text
	var points := _free_points()
	_points_label.text = "Fähigkeitspunkte frei: %d" % points
	_tree.refresh(points)

	_passives_label.text = "Passive (%d / %d)" % [GameState.passives.size(), PlayerClasses.MAX_PASSIVES]
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


## Bleibt bildschirmfüllend (nicht wie andere Fenster auf den Inhalt schrumpfen).
func _recenter() -> void:
	pass


func _free_points() -> int:
	return GameState.free_skill_points(int(player.experience.level))


func _on_skill_clicked(id: String, right: bool) -> void:
	var skill_name: String = PlayerClasses.skill(id).name
	var learned := id in GameState.learned_skills
	var ring: int = PlayerClasses.skill(id).get("ring", 0)
	if right:
		if learned and GameState.removal_blocked(id, false):
			show_status("Verlerne zuerst die Fähigkeiten weiter außen.", true)
		elif learned:
			GameState.unlearn_skill(id)
			show_status("%s verlernt." % skill_name)
	elif learned:
		show_status("%s ist schon gelernt." % skill_name)
	elif not GameState.ring_unlocked(ring):
		show_status("%s: erst ab %d Punkten in den inneren Ringen." % [PlayerClasses.RINGS[ring].name, GameState.ring_requirement(ring)], true)
	elif _free_points() <= 0:
		show_status("Kein Fähigkeitspunkt frei (1 pro Stufe).", true)
	else:
		GameState.learn_skill(id)
		var slot := GameState.skill_bar.find(id)
		show_status("%s gelernt%s." % [skill_name, (" und auf %s gelegt" % PlayerClasses.SLOT_KEYS[slot]) if slot >= 0 else ""])
	refresh()


func _on_upgrade_clicked(id: String, upgrade: int, right: bool) -> void:
	var data := PlayerClasses.skill(id)
	var upgrade_name: String = data.upgrades[upgrade - 1].name
	var chosen := GameState.skill_upgrade(id)
	if right:
		if chosen == upgrade and GameState.removal_blocked(id, true):
			show_status("Verlerne zuerst die Fähigkeiten weiter außen.", true)
		elif chosen == upgrade:
			GameState.set_skill_upgrade(id, 0)
			show_status("%s abgelegt." % upgrade_name)
	elif not id in GameState.learned_skills:
		show_status("Lerne zuerst %s." % data.name, true)
	elif chosen == upgrade:
		show_status("%s ist schon gewählt." % upgrade_name)
	elif chosen == 0 and _free_points() <= 0:
		show_status("Kein Fähigkeitspunkt frei (1 pro Stufe).", true)
	else:
		GameState.set_skill_upgrade(id, upgrade)
		show_status("%s: %s gewählt." % [data.name, upgrade_name])
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


func _reset() -> void:
	player.buffs.clear()
	GameState.reset_skills()
	show_status("Alle Fähigkeitspunkte sind wieder frei.")
	refresh()
