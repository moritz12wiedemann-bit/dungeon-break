class_name GameMaterials
extends RefCounted
## Materialien und Orbs. Sie liegen nicht in der Tasche, sondern werden im Reiter
## "Materialien" des Inventars nur hochgezählt (beliebig viele).
## Orbs benutzt man so: Orb im Reiter anklicken (rechts oder links), dann einen Gegenstand anklicken.

const ORB_ADD := "orb_add"
const ORB_REMOVE := "orb_remove"
const ORB_REROLL := "orb_reroll"
const SCRAP := "scrap"
## Orbs, die zufällig als Beute fallen können.
const ORBS := [ORB_ADD, ORB_REMOVE, ORB_REROLL]

## Alle Materialien: Name, Beschreibung, Bild und ob man es auf Gegenstände anwenden kann.
const INFO := {
	ORB_ADD: {
		"name": "Orb der Erweiterung",
		"text": "Fügt einem Gegenstand einen zufälligen neuen Wert hinzu.\nDie Seltenheit steigt (Normal, Magisch, Selten, Legendär).",
		"icon": preload("res://assets/icons/orb_add.svg"),
		"usable": true,
	},
	ORB_REMOVE: {
		"name": "Orb der Läuterung",
		"text": "Entfernt einen zufälligen Wert von einem Gegenstand (nie den Grundwert).\nDie Seltenheit sinkt.",
		"icon": preload("res://assets/icons/orb_remove.svg"),
		"usable": true,
	},
	ORB_REROLL: {
		"name": "Orb des Wandels",
		"text": "Würfelt alle Werte eines Gegenstands neu,\njeweils innerhalb des Bereichs in Klammern.",
		"icon": preload("res://assets/icons/orb_reroll.svg"),
		"usable": true,
	},
	SCRAP: {
		"name": "Altmetall",
		"text": "Bekommt man beim Schmied, wenn man Gegenstände zerlegt.\nWird später zum Herstellen gebraucht.",
		"icon": preload("res://assets/icons/scrap.svg"),
		"usable": false,
	},
}
const GOLD_ICON := preload("res://assets/icons/gold.svg")
## So viele hat jeder Spieler am Anfang (zum Ausprobieren).
const STARTING := {ORB_ADD: 5, ORB_REMOVE: 5, ORB_REROLL: 5}


static func display_name(id: String) -> String:
	return INFO[id].name


## Wendet den Orb `id` auf `item` an. Gibt eine Fehlermeldung zurück oder "" bei Erfolg.
static func apply_orb(id: String, item: ItemData) -> String:
	match id:
		ORB_ADD:
			return ItemGenerator.add_random_stat(item)
		ORB_REMOVE:
			return ItemGenerator.remove_random_stat(item)
		ORB_REROLL:
			return ItemGenerator.reroll_stats(item)
	return "Das kann man nicht auf Gegenstände anwenden."
