class_name ItemData
extends Resource
## Ein Gegenstand (Ausrüstung). Wird vom ItemGenerator zufällig erzeugt
## und liegt dann am Boden, im Inventar oder ist angezogen.

enum Slot { HELM, GLOVES, ARMOR, PANTS, BOOTS, WEAPON }
enum Rarity { NORMAL, MAGIC, RARE, LEGENDARY, SET }

const SLOT_NAMES := {
	Slot.HELM: "Helm",
	Slot.GLOVES: "Handschuhe",
	Slot.ARMOR: "Rüstung",
	Slot.PANTS: "Hose",
	Slot.BOOTS: "Schuhe",
	Slot.WEAPON: "Waffe",
}
const RARITY_NAMES := {
	Rarity.NORMAL: "Normal",
	Rarity.MAGIC: "Magisch",
	Rarity.RARE: "Selten",
	Rarity.LEGENDARY: "Legendär",
	Rarity.SET: "Set-Gegenstand",
}
const RARITY_COLORS := {
	Rarity.NORMAL: Color(0.92, 0.92, 0.92),
	Rarity.MAGIC: Color(0.4, 0.6, 1.0),
	Rarity.RARE: Color(1.0, 0.9, 0.3),
	Rarity.LEGENDARY: Color(1.0, 0.55, 0.1),
	Rarity.SET: Color(0.3, 1.0, 0.3),
}
## Anzeigenamen der Werte, die ein Gegenstand haben kann.
const STAT_NAMES := {
	"damage": "Schaden",
	"armor": "Rüstung",
	"health": "Leben",
	"regen": "Leben pro Sekunde",
	"move_speed": "% Laufgeschwindigkeit",
}

@export var item_name: String = "Gegenstand"
@export var slot: Slot = Slot.WEAPON
@export var rarity: Rarity = Rarity.NORMAL
@export var item_level: int = 1
## Nur bei Set-Gegenständen: Name des Sets.
@export var set_name: String = ""
## Werte des Gegenstands, z. B. {"armor": 12, "health": 20}. Schlüssel siehe STAT_NAMES.
@export var stats: Dictionary = {}


func get_color() -> Color:
	return RARITY_COLORS[rarity]


func get_stat(stat: String) -> float:
	return stats.get(stat, 0)


## Text für den Tooltip im Inventar (erste Zeile = Name).
func describe() -> String:
	var lines: Array[String] = [item_name]
	lines.append("%s · %s · Stufe %d" % [RARITY_NAMES[rarity], SLOT_NAMES[slot], item_level])
	if set_name != "":
		lines.append("Set: %s" % set_name)
	for stat in STAT_NAMES:
		if stats.has(stat):
			lines.append("+%s %s" % [_format(stats[stat]), STAT_NAMES[stat]])
	return "\n".join(lines)


func _format(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(value))
	return "%.1f" % value
