extends GameWindow
## Magischer Ältester: hier wählt man seine Unterklasse und lernt/verbessert Fähigkeiten.
## Nur hier, nirgends sonst. Fähigkeitspunkte: 1 pro Stufe.
##
## PLATZHALTER: Klassen, Unterklassen und Fähigkeiten haben noch keine Wirkung.
## Später wählt man die Klasse am Spielstart, jede Klasse hat zwei Unterklassen,
## und die echten Fähigkeiten kommen dazu.

## Vorerst gibt es nur den Ritter (die Figur, die man spielt).
const CLASS_NAME := "Ritter"
## Unterklasse → Beschreibung und Fähigkeiten (Platzhalter).
const SUBCLASSES := {
	"Wächter": {
		"text": "Schild und Standhaftigkeit (Platzhalter)",
		"skills": ["Schildwall", "Spott", "Bollwerk"],
	},
	"Kreuzritter": {
		"text": "Heiliger Zorn und Heilung (Platzhalter)",
		"skills": ["Lichtschlag", "Segen", "Urteil"],
	},
}
const MAX_SKILL_LEVEL := 5

var _info: Label
var _subclass_box: HBoxContainer
var _skills_box: VBoxContainer
var _points_label: Label


func _init() -> void:
	super("Magischer Ältester")


func _build() -> void:
	_info = make_label("", 14)
	content.add_child(_info)
	_subclass_box = HBoxContainer.new()
	_subclass_box.add_theme_constant_override("separation", 8)
	content.add_child(_subclass_box)
	_points_label = make_label("", 16, Color(0.6, 0.85, 1.0))
	content.add_child(_points_label)
	_skills_box = VBoxContainer.new()
	_skills_box.add_theme_constant_override("separation", 4)
	content.add_child(_skills_box)
	content.add_child(make_label("Platzhalter: Unterklassen und Fähigkeiten haben noch keine Wirkung.", 12, Color(0.6, 0.57, 0.5)))


func refresh() -> void:
	_info.text = "Klasse: %s\nWähle deine Unterklasse. Fähigkeiten lernst und verbesserst du nur hier." % CLASS_NAME
	for child in _subclass_box.get_children():
		child.queue_free()
	for subclass in SUBCLASSES:
		var button := make_button("%s\n%s" % [subclass, SUBCLASSES[subclass].text], _choose.bind(subclass))
		button.toggle_mode = true
		button.button_pressed = GameState.subclass == subclass
		_subclass_box.add_child(button)
	for child in _skills_box.get_children():
		child.queue_free()
	if GameState.subclass == "":
		_points_label.text = "Wähle zuerst eine Unterklasse."
		return
	_points_label.text = "Fähigkeitspunkte frei: %d" % _free_points()
	for skill in SUBCLASSES[GameState.subclass].skills:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var name_label := make_label(skill, 15)
		name_label.custom_minimum_size.x = 160
		row.add_child(name_label)
		var level: int = GameState.skill_levels.get(skill, 0)
		row.add_child(make_label("Stufe %d / %d" % [level, MAX_SKILL_LEVEL], 14, Color(0.7, 0.68, 0.62)))
		var plus := make_button("+", _raise.bind(skill))
		plus.disabled = level >= MAX_SKILL_LEVEL or _free_points() <= 0
		row.add_child(plus)
		_skills_box.add_child(row)


## 1 Punkt pro Stufe, minus die schon verteilten.
func _free_points() -> int:
	var spent := 0
	for skill in GameState.skill_levels:
		spent += GameState.skill_levels[skill]
	return int(player.experience.level) - spent


## Unterklasse wählen. Ein Wechsel gibt alle Fähigkeitspunkte zurück.
func _choose(subclass: String) -> void:
	if GameState.subclass == subclass:
		refresh()
		return
	var had_one := GameState.subclass != ""
	GameState.subclass = subclass
	GameState.skill_levels.clear()
	show_status("Du bist jetzt %s.%s" % [subclass, " Deine Fähigkeitspunkte sind zurückgesetzt." if had_one else ""])
	GameState.progress_changed.emit()
	refresh()


func _raise(skill: String) -> void:
	if _free_points() <= 0:
		return
	GameState.skill_levels[skill] = GameState.skill_levels.get(skill, 0) + 1
	show_status("%s ist jetzt Stufe %d." % [skill, GameState.skill_levels[skill]])
	GameState.progress_changed.emit()
	refresh()
