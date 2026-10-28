class_name AugmentCards
extends RefCounted
## Augment-Karten der Mystikerin. Man kauft sie für Gold und rüstet sie mit Arcana aus:
## Jede Karte kostet beim Ausrüsten Arcana, und man hat nur begrenzt Arcana (am Anfang 3).
## Ausgerüstete Karten geben dauerhaft ihre Effekte.
##
## PLATZHALTER: Die Karten unten geben vorerst nur einfache Werte (wie Ausrüstung).
## Die echten Karten und Effekte kommen später.

## Karte → Name, Beschreibung, Arcana-Kosten, Goldpreis, Werte (Schlüssel wie bei ItemData.STAT_NAMES).
const CARDS := {
	"bear": {"name": "Karte des Bären", "arcana": 1, "price": 150, "stats": {"health": 25}},
	"blade": {"name": "Karte der Klinge", "arcana": 1, "price": 150, "stats": {"damage": 3}},
	"shell": {"name": "Karte des Panzers", "arcana": 1, "price": 150, "stats": {"armor": 15}},
	"wind": {"name": "Karte des Windes", "arcana": 2, "price": 400, "stats": {"move_speed": 10}},
	"frenzy": {"name": "Karte der Raserei", "arcana": 2, "price": 400, "stats": {"attack_speed": 12}},
	"spring": {"name": "Karte des Lebensquells", "arcana": 2, "price": 400, "stats": {"regen": 3}},
	"titan": {"name": "Karte des Titanen", "arcana": 3, "price": 900, "stats": {"health": 60, "damage": 6}},
}
## Arcana am Anfang und höchstens.
const START_ARCANA := 3
const MAX_ARCANA := 10
## Arcana erhöhen kostet beim ersten Mal so viel Gold, danach jedes Mal doppelt so viel.
const ARCANA_BASE_PRICE := 500


## Text der Effekte einer Karte, z. B. "+25 Leben".
static func describe(id: String) -> String:
	var parts: Array[String] = []
	var stats: Dictionary = CARDS[id].stats
	for stat in stats:
		parts.append("+%s %s" % [ItemData.format_number(stats[stat]), ItemData.STAT_NAMES[stat]])
	return ", ".join(parts)


static func arcana_upgrade_price(current_max: int) -> int:
	return ARCANA_BASE_PRICE * int(pow(2, current_max - START_ARCANA))
