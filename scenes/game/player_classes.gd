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
## true = hat geklappt (dann kostet es Mana bzw. Zorn und die Abklingzeit startet).
## Im Code heißt die Ressource immer "mana"; wie sie im Spiel heißt (z. B. Zorn beim Krieger)
## und welche Farbe ihre Leiste hat, steht bei der Klasse unter "resource".
##
## Weitere Schlüssel einer Fähigkeit:
## - "cast_time": so lange (Sekunden) bleibt die Figur beim Zaubern stehen.
## - "moving_upgrade": mit dieser Erweiterung bleibt sie nicht stehen.
## - "charge_upgrade" + "max_charge": mit dieser Erweiterung hält man die Taste gedrückt
##   zum Aufladen (höchstens max_charge Sekunden), losgelassen wird gezaubert.
## - "channel": gedrückt halten wirkt immer wieder, die Figur bleibt dabei stehen.
## - "uses_attack_speed": Abklingzeit = Zeit zwischen zwei normalen Schlägen (Angriffstempo).
## - "spend_all_upgrade": mit dieser Erweiterung keine Abklingzeit, verbraucht aber den ganzen Zorn.
## - "upgrade_mana": andere Kosten mit einer Erweiterung, z. B. {1: 15} (siehe skill_cost()).
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
## "requires": so viele Punkte muss man vorher in den inneren Ringen ausgegeben haben.
const RINGS := [
	{"name": "Basis-Skills", "color": Color(0.35, 0.55, 1.0)},
	{"name": "Core-Skills", "color": Color(1.0, 0.78, 0.25), "requires": 2},
	{"name": "Mobility", "color": Color(0.35, 0.85, 0.4), "requires": 4},
	{"name": "Buffs", "color": Color(0.95, 0.55, 0.3), "requires": 6},
	{"name": "Ultimate-Skills", "color": Color(0.8, 0.35, 0.95), "requires": 10},
]

const START_CLASS := "krieger"

const CLASSES := {
	"krieger": {
		"name": "Krieger",
		"text": "Nahkampf. Ausgewogen zwischen Schaden und Standfestigkeit.",
		"icon": preload("res://assets/icons/class_krieger.svg"),
		# Statt Mana hat der Krieger Zorn (orange Leiste). Startet leer, kommt nur durch Treffen.
		"resource": {"name": "Zorn", "color": Color(1.0, 0.62, 0.15), "start_full": false},
		# Standardangriff (Linksklick), den jede Klasse von Anfang an hat.
		"basic_attack": "krieger_schlag",
		# Die beiden Unterklassen (Namen und Fähigkeiten kommen später).
		"subclasses": {"left": "Unterklasse 1", "right": "Unterklasse 2"},
		"skills": ["krieger_slash", "krieger_stich", "krieger_tausend", "krieger_himmelszorn",
			"krieger_rolle", "krieger_ehrenruf", "krieger_geschlagen", "krieger_armee"],
		"passives": [],
		# Startbelegung: Q, W, E, R, Linksklick, Rechtsklick ("" = leer).
		"bar": ["", "", "", "", "krieger_schlag", ""],
	},
}

const SKILLS := {
	"krieger_schlag": {
		"name": "Schlag",
		"text": "Standardangriff: Linksklick auf einen Gegner, die Figur läuft hin und schlägt zu.",
		"rage_gain": "2 pro Treffer",
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
		"mana": 0,
		"rage_gain": "5 pro getroffenem Gegner",
		"cooldown": 8.0,
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
		"mana": 0,
		"rage_gain": "10, wenn er trifft",
		"cooldown": 8.0,
		"cast_time": 0.3,
		"moving_upgrade": 1,
		"charge_upgrade": 2,
		"max_charge": 2.0,
		"upgrades": [
			{
				"name": "Sturmstich",
				"text": "Der Stich geht auch im Laufen. Stirbt der Gegner, bekommst du 5 Zorn extra.",
				"icon": preload("res://assets/icons/upgrade_stab_run.svg"),
			},
			{
				"name": "Aufgeladener Stich",
				"text": "Taste gedrückt halten zum Aufladen (bis zu 2 Sekunden). Voll aufgeladen ist der Stich dreimal so lang und breit und macht dreifachen Schaden. Trifft alle Gegner in seiner Bahn.",
				"icon": preload("res://assets/icons/upgrade_stab_charge.svg"),
			},
		],
	},
	"krieger_tausend": {
		"name": "1000 Schläge",
		"text": "Gedrückt halten: Die Figur bleibt stehen und schlägt immer wieder in Richtung Mauszeiger. Der erste Schlag macht 50 % Schaden, jeder Schlag gibt einen Stack 1000 Schläge (+10 % Schaden, bis 30 Stacks). Keine Abklingzeit, schlägt so schnell wie dein Angriffstempo. Ohne zu schlagen geht alle 0,5 Sekunden 1 Stack verloren.",
		"icon": preload("res://assets/icons/skill_thousand.svg"),
		"script": preload("res://scenes/skills/thousand_blows.gd"),
		"ring": 1,
		"sector": "base",
		"mana": 5,
		"cooldown": 0.0,
		"channel": true,
		"uses_attack_speed": true,
		"upgrades": [
			{
				"name": "Wuchtschläge",
				"text": "Gegner im direkten Umkreis des Getroffenen erhalten ebenfalls 30 % des Schlagschadens.",
				"icon": preload("res://assets/icons/upgrade_thousand_splash.svg"),
			},
			{
				"name": "Standhafte Schläge",
				"text": "Pro Stack 1000 Schläge zusätzlich +0,5 % Angriffstempo und +1 Rüstung.",
				"icon": preload("res://assets/icons/upgrade_thousand_steady.svg"),
			},
		],
	},
	"krieger_himmelszorn": {
		"name": "Zorn des Himmels",
		"text": "Beschwört eine runde Fläche am Mauszeiger. Nach 0,5 Sekunden macht sie 3 Sekunden lang ständig Schaden an allen Gegnern darin (insgesamt 400 %).",
		"icon": preload("res://assets/icons/skill_heaven.svg"),
		"script": preload("res://scenes/skills/heaven_wrath.gd"),
		"ring": 1,
		"sector": "base",
		"mana": 60,
		"cooldown": 10.0,
		"cast_time": 0.3,
		"spend_all_upgrade": 2,
		"upgrades": [
			{
				"name": "Himmelssog",
				"text": "Gegner in der Fläche werden zur Mitte gezogen. Herauslaufen geht nur mühsam und langsam.",
				"icon": preload("res://assets/icons/upgrade_heaven_pull.svg"),
			},
			{
				"name": "Entfesselter Zorn",
				"text": "Keine Abklingzeit mehr, aber jeder Einsatz verbraucht den ganzen Zorn (mindestens 60). Pro verbrauchtem Zorn +1 % Schaden für diesen Einsatz.",
				"icon": preload("res://assets/icons/upgrade_heaven_unleash.svg"),
			},
		],
	},
	"krieger_rolle": {
		"name": "Hechtrolle",
		"text": "Schnelle Rolle nach vorne in Richtung Mauszeiger (etwa 4 Meter).",
		"icon": preload("res://assets/icons/skill_roll.svg"),
		"script": preload("res://scenes/skills/dive_roll.gd"),
		"ring": 2,
		"sector": "base",
		"mana": 5,
		"cooldown": 3.0,
		"cast_time": 0.4,
		"upgrades": [
			{
				"name": "Gepanzerte Rolle",
				"text": "Nach der Rolle hast du 5 Sekunden lang 10 % mehr Rüstung.",
				"icon": preload("res://assets/icons/upgrade_roll_armor.svg"),
			},
			{
				"name": "Flinke Rolle",
				"text": "Nach der Rolle bist du 5 Sekunden lang 15 % schneller.",
				"icon": preload("res://assets/icons/upgrade_roll_speed.svg"),
			},
		],
	},
	"krieger_ehrenruf": {
		"name": "Ehrenruf",
		"text": "Kampfruf: 15 Sekunden lang machen normale Angriffe 20 % mehr Schaden und sind 25 % schneller.",
		"icon": preload("res://assets/icons/skill_honor.svg"),
		"script": preload("res://scenes/skills/honor_call.gd"),
		"ring": 3,
		"sector": "base",
		"mana": 0,
		"upgrade_mana": {1: 15},
		"cooldown": 60.0,
		"cast_time": 0.3,
		"upgrades": [
			{
				"name": "Kampfschrei",
				"text": "Normale Angriffe machen stattdessen 30 % mehr Schaden, dafür kostet der Ruf 15 Zorn.",
				"icon": preload("res://assets/icons/upgrade_honor_damage.svg"),
			},
			{
				"name": "Sturmruf",
				"text": "Zusätzlich 15 % mehr Bewegungstempo, ohne Zornkosten.",
				"icon": preload("res://assets/icons/upgrade_honor_speed.svg"),
			},
		],
	},
	"krieger_geschlagen": {
		"name": "Zorn des Geschlagenen",
		"text": "10 Sekunden lang verlierst du pro Sekunde 3 % deines maximalen Lebens und bekommst dafür 2 Zorn. Tötet dich nicht: bei 1 Leben endet der Buff.",
		"icon": preload("res://assets/icons/skill_beaten.svg"),
		"script": preload("res://scenes/skills/beaten_wrath.gd"),
		"ring": 3,
		"sector": "base",
		"mana": 0,
		"cooldown": 60.0,
		"cast_time": 0.25,
		"upgrades": [
			{
				"name": "Umgekehrter Zorn",
				"text": "Umgekehrt: pro Sekunde 2 Zorn verbrauchen und dafür 3 % Leben herstellen. Endet, wenn der Zorn leer ist.",
				"icon": preload("res://assets/icons/upgrade_beaten_heal.svg"),
			},
			{
				"name": "Blutrausch",
				"text": "Solange der Buff läuft, verkürzt jeder getötete Gegner die Abklingzeit um 3 Sekunden.",
				"icon": preload("res://assets/icons/upgrade_beaten_kill.svg"),
			},
		],
	},
	"krieger_armee": {
		"name": "Ein-Mann-Armee",
		"text": "20 Sekunden lang erleidest du 50 % weniger Schaden und machst 30 % mehr Schaden (normale Angriffe und Fähigkeiten).",
		"icon": preload("res://assets/icons/skill_army.svg"),
		"script": preload("res://scenes/skills/one_man_army.gd"),
		"ring": 4,
		"sector": "base",
		"mana": 0,
		"cooldown": 120.0,
		"cast_time": 0.4,
		"upgrades": [
			{
				"name": "Unbändiger Zorn",
				"text": "Solange sie läuft, bekommst du 3 Zorn pro Sekunde.",
				"icon": preload("res://assets/icons/upgrade_army_rage.svg"),
			},
			{
				"name": "Kriegeraura",
				"text": "Solange sie läuft, machen Gegner in einem großen Umkreis um dich 20 % weniger Schaden und erleiden 20 % mehr Schaden.",
				"icon": preload("res://assets/icons/upgrade_army_aura.svg"),
			},
		],
	},
}

const PASSIVES := {}

## Buffs (kleine Bilder über der Skill-Leiste, mit Anzahl der Stacks bzw. den restlichen Sekunden).
## Was ein Buff mit Laufzeit bewirkt, steht beim Spieler im Buff selbst ("stats", siehe player.gd add_timed_buff).
const BUFFS := {
	"tausend": {
		"name": "1000 Schläge",
		"text": "+10 % Schaden für 1000 Schläge pro Stack.",
		"icon": preload("res://assets/icons/skill_thousand.svg"),
		"max_stacks": 30,
	},
	"rolle_ruestung": {
		"name": "Gepanzerte Rolle",
		"text": "+10 % Rüstung.",
		"icon": preload("res://assets/icons/upgrade_roll_armor.svg"),
	},
	"rolle_tempo": {
		"name": "Flinke Rolle",
		"text": "+15 % Bewegungstempo.",
		"icon": preload("res://assets/icons/upgrade_roll_speed.svg"),
	},
	"ehrenruf": {
		"name": "Ehrenruf",
		"text": "Normale Angriffe machen mehr Schaden und sind schneller.",
		"icon": preload("res://assets/icons/skill_honor.svg"),
	},
	"geschlagen": {
		"name": "Zorn des Geschlagenen",
		"text": "Leben wird zu Zorn (bzw. Zorn zu Leben).",
		"icon": preload("res://assets/icons/skill_beaten.svg"),
		# Jede Sekunde wird tick() in diesem Skript aufgerufen.
		"script": preload("res://scenes/skills/beaten_wrath.gd"),
	},
	"armee": {
		"name": "Ein-Mann-Armee",
		"text": "50 % weniger erlittener Schaden, 30 % mehr Schaden.",
		"icon": preload("res://assets/icons/skill_army.svg"),
		# Mit "Unbändiger Zorn" jede Sekunde tick() (3 Zorn).
		"script": preload("res://scenes/skills/one_man_army.gd"),
	},
}


## Name der Klasse, z. B. "Krieger".
static func class_title(class_id: String) -> String:
	return CLASSES[class_id].name if CLASSES.has(class_id) else class_id


## Wie die Ressource der Klasse heißt (z. B. "Zorn"), Standard "Mana".
static func resource_name(class_id: String) -> String:
	return CLASSES.get(class_id, {}).get("resource", {}).get("name", "Mana")


## Farbe der Ressourcen-Leiste der Klasse.
static func resource_color(class_id: String) -> Color:
	return CLASSES.get(class_id, {}).get("resource", {}).get("color", Color(0.15, 0.35, 0.9))


## Eine Fähigkeit ("" oder unbekannt = leeres Dictionary).
static func skill(skill_id: String) -> Dictionary:
	return SKILLS.get(skill_id, {})


## Was die Fähigkeit mit der Erweiterung `upgrade` kostet (Mana bzw. Zorn).
static func skill_cost(skill_id: String, upgrade: int) -> int:
	var data := skill(skill_id)
	return data.get("upgrade_mana", {}).get(upgrade, data.get("mana", 0))


## Beschreibung für den Tooltip, mit gewählter Erweiterung (0 = keine).
static func describe_skill(skill_id: String, upgrade: int = 0, class_id: String = START_CLASS) -> String:
	var data := skill(skill_id)
	if data.is_empty():
		return ""
	var lines: Array[String] = [data.name]
	if data.has("ring"):
		lines[0] += "  (%s)" % RINGS[data.ring].name
	lines.append(data.text)
	var cost := skill_cost(skill_id, upgrade)
	if cost > 0:
		lines.append("Kostet %d %s%s" % [cost, resource_name(class_id), " pro Schlag" if data.get("channel", false) else ""])
	if data.has("rage_gain"):
		lines.append("Bringt %s %s" % [resource_name(class_id), data.rage_gain])
	if data.cooldown > 0.0:
		lines.append("Abklingzeit: %s s" % str(data.cooldown))
	if upgrade > 0 and upgrade <= data.upgrades.size():
		var chosen: Dictionary = data.upgrades[upgrade - 1]
		lines.append("Erweiterung: %s - %s" % [chosen.name, chosen.text])
	return "\n".join(lines)
