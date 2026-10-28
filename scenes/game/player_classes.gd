class_name PlayerClasses
extends RefCounted
## Alle Klassen mit ihren Fähigkeiten und passiven Fähigkeiten.
##
## Jede Klasse hat:
## - Fähigkeiten (Skills). Jede Fähigkeit hat eine Grundform und zwei Skillbäume ("paths"),
##   von denen man beim magischen Ältesten immer nur einen wählen kann.
## - Passive Fähigkeiten: davon wählt man MAX_PASSIVES Stück aus mehreren aus.
## - Eine Startbelegung der Skill-Leiste (6 Plätze: Q, W, E, R, Linksklick, Rechtsklick).
##   Linksklick ist bei jeder Klasse der Standardangriff.
##
## Eine Fähigkeit mit "script" wird von diesem Skript ausgeführt. Es braucht
## `static func cast(player, aim: Vector3, target: Node3D, path: int, level: int) -> bool`
## (aim = Bodenpunkt unter der Maus, target = Gegner unter der Maus oder null,
## path = 0 Grundform / 1 erster / 2 zweiter Skillbaum). true = hat geklappt
## (dann kostet es Mana und die Abklingzeit startet).
##
## Passive und Skillbäume können "stats" haben (wie Augment-Karten, z. B. {"armor": 20}),
## die einfach zu den Werten des Spielers dazukommen.

## Die Plätze der Skill-Leiste, in dieser Reihenfolge.
enum Slot { Q, W, E, R, LEFT, RIGHT }
## Beschriftung der Plätze.
const SLOT_KEYS := ["Q", "W", "E", "R", "LMT", "RMT"]
## Eingabe-Aktionen der Plätze (Linksklick läuft über "move", siehe player.gd).
const SLOT_ACTIONS := ["skill_q", "skill_w", "skill_e", "skill_r", "move", "skill_right"]
## So viele passive Fähigkeiten kann man gleichzeitig wählen.
const MAX_PASSIVES := 3
## Höchste Stufe einer Fähigkeit.
const MAX_SKILL_LEVEL := 5

const START_CLASS := "krieger"

const CLASSES := {
	"krieger": {
		"name": "Krieger",
		"text": "Nahkampf. Ausgewogen zwischen Schaden und Standfestigkeit.",
		"skills": ["krieger_schlag"],
		"passives": [],
		# Startbelegung: Q, W, E, R, Linksklick, Rechtsklick ("" = leer).
		"bar": ["", "", "", "", "krieger_schlag", ""],
	},
}

const SKILLS := {
	"krieger_schlag": {
		"name": "Schlag",
		"text": "Standardangriff: Linksklick auf einen Gegner, die Figur läuft hin und schlägt zu.",
		"icon": preload("res://assets/icons/skill_attack.svg"),
		# Der Standardangriff wird direkt vom Spieler ausgeführt (Klick auf Gegner).
		"basic_attack": true,
		"mana": 0,
		"cooldown": 0.0,
		"paths": [],
	},
}

const PASSIVES := {}


## Name der Klasse, z. B. "Krieger".
static func class_title(class_id: String) -> String:
	return CLASSES[class_id].name if CLASSES.has(class_id) else class_id


## Eine Fähigkeit ("" oder unbekannt = leeres Dictionary).
static func skill(skill_id: String) -> Dictionary:
	return SKILLS.get(skill_id, {})


## Beschreibung für den Tooltip, mit gewähltem Skillbaum.
static func describe_skill(skill_id: String, path: int = 0, level: int = 0) -> String:
	var data := skill(skill_id)
	if data.is_empty():
		return ""
	var lines: Array[String] = [data.name]
	if level > 0:
		lines[0] += "  (Stufe %d)" % level
	lines.append(data.text)
	if data.mana > 0:
		lines.append("Mana: %d" % data.mana)
	if data.cooldown > 0.0:
		lines.append("Abklingzeit: %s s" % str(data.cooldown))
	if path > 0 and path <= data.paths.size():
		var chosen: Dictionary = data.paths[path - 1]
		lines.append("Skillbaum: %s - %s" % [chosen.name, chosen.text])
	return "\n".join(lines)
