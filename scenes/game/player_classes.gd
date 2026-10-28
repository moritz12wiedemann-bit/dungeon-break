class_name PlayerClasses
extends RefCounted
## Alle Klassen mit ihren Fähigkeiten und passiven Fähigkeiten.
##
## Der Skillbaum ist ein Kreis (siehe scenes/ui/skill_tree.gd):
## - Ringe von innen nach außen: Basis, Core, Mobility, Buffs, Ultimate (RINGS).
## - Drei Bereiche: unten die Fähigkeiten, die jeder Krieger hat ("base"),
##   rechts und links die beiden Unterklassen ("right", "left").
## - Jede Fähigkeit kostet 1 Punkt. Dazu hat sie zwei Erweiterungen ("upgrades"),
##   von denen man immer nur eine wählen kann (auch 1 Punkt).
## Punkte verteilt man nur beim magischen Ältesten. Gelernte Fähigkeiten legt man
## sich auf der Skill-Leiste hin, wo man will (Klick auf einen Platz der Leiste).
##
## Eine Fähigkeit mit "script" wird von diesem Skript ausgeführt. Es braucht
## `static func cast(player, aim: Vector3, target: Node3D, upgrade: int, charge: float) -> bool`
## (aim = Bodenpunkt unter der Maus, target = Gegner unter der Maus oder null,
## upgrade = 0 keine / 1 erste / 2 zweite Erweiterung, charge = aufgeladene Sekunden).
## true = hat geklappt (dann kostet es Mana und die Abklingzeit startet).
##
## Weitere Schlüssel einer Fähigkeit:
## - "cast_time": so lange (Sekunden) bleibt die Figur beim Zaubern stehen.
## - "moving_upgrade": mit dieser Erweiterung bleibt sie nicht stehen.
## - "charge_upgrade" + "max_charge": mit dieser Erweiterung hält man die Taste gedrückt
##   zum Aufladen (höchstens max_charge Sekunden), losgelassen wird gezaubert.
## Passive und Erweiterungen können "stats" haben (wie Augment-Karten, z. B. {"armor": 20}).

## Die Plätze der Skill-Leiste, in dieser Reihenfolge.
enum Slot { Q, W, E, R, LEFT, RIGHT }
## Beschriftung der Plätze.
const SLOT_KEYS := ["Q", "W", "E", "R", "LMT", "RMT"]
## Eingabe-Aktionen der Plätze (Linksklick läuft über "move", siehe player.gd).
const SLOT_ACTIONS := ["skill_q", "skill_w", "skill_e", "skill_r", "move", "skill_right"]
## In dieser Reihenfolge bekommen neu gelernte Fähigkeiten einen freien Platz.
const AUTO_SLOTS := [Slot.Q, Slot.W, Slot.E, Slot.R, Slot.RIGHT]
## So viele passive Fähigkeiten kann man gleichzeitig wählen.
const MAX_PASSIVES := 3

## Ringe des Skillbaums von innen nach außen.
const RINGS := [
	{"name": "Basis-Skills", "color": Color(0.35, 0.55, 1.0)},
	{"name": "Core-Skills", "color": Color(1.0, 0.78, 0.25)},
	{"name": "Mobility", "color": Color(0.35, 0.85, 0.4)},
	{"name": "Buffs", "color": Color(0.95, 0.55, 0.3)},
	{"name": "Ultimate-Skills", "color": Color(0.8, 0.35, 0.95)},
]

const START_CLASS := "krieger"

const CLASSES := {
	"krieger": {
		"name": "Krieger",
		"text": "Nahkampf. Ausgewogen zwischen Schaden und Standfestigkeit.",
		"icon": preload("res://assets/icons/class_krieger.svg"),
		# Standardangriff (Linksklick), den jede Klasse von Anfang an hat.
		"basic_attack": "krieger_schlag",
		# Die beiden Unterklassen (Namen und Fähigkeiten kommen später).
		"subclasses": {"left": "Unterklasse 1", "right": "Unterklasse 2"},
		"skills": ["krieger_slash", "krieger_stich"],
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
		"upgrades": [],
	},
	"krieger_slash": {
		"name": "Slash",
		"text": "Großer, breiter Schwerthieb in Richtung Mauszeiger. Trifft alle Gegner im Bogen und macht 160 % Schaden.",
		"icon": preload("res://assets/icons/skill_slash.svg"),
		"script": preload("res://scenes/skills/slash.gd"),
		"ring": 0,
		"sector": "base",
		"mana": 25,
		"cooldown": 3.0,
		"cast_time": 0.35,
		"upgrades": [
			{
				"name": "Weiter Hieb",
				"text": "Der Slash ist doppelt so groß und macht 20 % mehr Schaden.",
				"icon": preload("res://assets/icons/upgrade_slash_wide.svg"),
			},
			{
				"name": "Lähmender Hieb",
				"text": "Getroffene Gegner sind 10 Sekunden lang um 50 % verlangsamt und erleiden 30 % mehr Schaden.",
				"icon": preload("res://assets/icons/upgrade_slash_cripple.svg"),
			},
		],
	},
	"krieger_stich": {
		"name": "Stich",
		"text": "Kurzer Stich nach vorne. Trifft nur einen Gegner, macht aber 300 % Schaden.",
		"icon": preload("res://assets/icons/skill_stab.svg"),
		"script": preload("res://scenes/skills/stab.gd"),
		"ring": 0,
		"sector": "base",
		"mana": 20,
		"cooldown": 3.0,
		"cast_time": 0.3,
		"moving_upgrade": 1,
		"charge_upgrade": 2,
		"max_charge": 2.0,
		"upgrades": [
			{
				"name": "Sturmstich",
				"text": "Der Stich geht auch im Laufen. Stirbt der Gegner, bekommst du die Hälfte des Manas zurück.",
				"icon": preload("res://assets/icons/upgrade_stab_run.svg"),
			},
			{
				"name": "Aufgeladener Stich",
				"text": "Taste gedrückt halten zum Aufladen (bis zu 2 Sekunden). Voll aufgeladen macht der Stich doppelten Schaden.",
				"icon": preload("res://assets/icons/upgrade_stab_charge.svg"),
			},
		],
	},
}

const PASSIVES := {}


## Name der Klasse, z. B. "Krieger".
static func class_title(class_id: String) -> String:
	return CLASSES[class_id].name if CLASSES.has(class_id) else class_id


## Eine Fähigkeit ("" oder unbekannt = leeres Dictionary).
static func skill(skill_id: String) -> Dictionary:
	return SKILLS.get(skill_id, {})


## Beschreibung für den Tooltip, mit gewählter Erweiterung (0 = keine).
static func describe_skill(skill_id: String, upgrade: int = 0) -> String:
	var data := skill(skill_id)
	if data.is_empty():
		return ""
	var lines: Array[String] = [data.name]
	if data.has("ring"):
		lines[0] += "  (%s)" % RINGS[data.ring].name
	lines.append(data.text)
	if data.mana > 0:
		lines.append("Mana: %d" % data.mana)
	if data.cooldown > 0.0:
		lines.append("Abklingzeit: %s s" % str(data.cooldown))
	if upgrade > 0 and upgrade <= data.upgrades.size():
		var chosen: Dictionary = data.upgrades[upgrade - 1]
		lines.append("Erweiterung: %s - %s" % [chosen.name, chosen.text])
	return "\n".join(lines)
