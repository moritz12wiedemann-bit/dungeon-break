class_name ItemData
extends Resource
## Ein Gegenstand (Ausrüstung). Wird vom ItemGenerator zufällig erzeugt
## und liegt dann am Boden, im Inventar oder ist angezogen.
##
## Die Seltenheit hängt an der Zahl der Werte: 1 Wert = Normal, 2 = Magisch,
## 3 = Selten, 4 = Legendär. Set-Gegenstände haben auch 4 Werte und stehen auf
## einer Stufe mit Legendär (eine Alternative dazu, nicht besser).

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
## Bildchen je Platz (helle Zeichnung, wird in der Farbe der Seltenheit eingefärbt).
const SLOT_ICONS := {
	Slot.HELM: preload("res://assets/icons/helm.svg"),
	Slot.GLOVES: preload("res://assets/icons/gloves.svg"),
	Slot.ARMOR: preload("res://assets/icons/armor.svg"),
	Slot.PANTS: preload("res://assets/icons/pants.svg"),
	Slot.BOOTS: preload("res://assets/icons/boots.svg"),
	Slot.WEAPON: preload("res://assets/icons/weapon.svg"),
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
## Anzeigenamen der Werte, die ein Gegenstand haben kann (in dieser Reihenfolge angezeigt).
const STAT_NAMES := {
	"damage": "Schaden",
	"armor": "Rüstung",
	"health": "Leben",
	"regen": "Leben pro Sekunde",
	"move_speed": "% Laufgeschwindigkeit",
	"attack_speed": "% Angriffstempo",
}
## So viele Werte hat ein Gegenstand jeder Seltenheit.
const STAT_COUNT := {
	Rarity.NORMAL: 1,
	Rarity.MAGIC: 2,
	Rarity.RARE: 3,
	Rarity.LEGENDARY: 4,
	Rarity.SET: 4,
}
## Höchstzahl an Werten (= Legendär).
const MAX_STATS := 4

@export var item_name: String = "Gegenstand"
## Grundname ohne Zusätze, z. B. "Eisenhelm". Daraus wird item_name gebaut.
@export var base_name: String = ""
@export var slot: Slot = Slot.WEAPON
@export var rarity: Rarity = Rarity.NORMAL
@export var item_level: int = 1
## Nur bei Set-Gegenständen: Name des Sets.
@export var set_name: String = ""
## Werte des Gegenstands, z. B. {"armor": 12, "health": 20}. Schlüssel siehe STAT_NAMES.
@export var stats: Dictionary = {}
## Wertebereich je Wert: Vector2(Minimum, Maximum). Neu auswürfeln bleibt in diesem Bereich.
@export var ranges: Dictionary = {}
## Der Grundwert (Waffe: Schaden, sonst Rüstung). Ihn hat jeder Gegenstand, er kann nicht entfernt werden.
@export var base_stat: String = ""


func get_color() -> Color:
	return RARITY_COLORS[rarity]


func get_icon() -> Texture2D:
	return SLOT_ICONS[slot]


func get_stat(stat: String) -> float:
	return stats.get(stat, 0)


## Werte in Anzeige-Reihenfolge, der Grundwert zuerst.
func sorted_stats() -> Array[String]:
	var result: Array[String] = []
	if stats.has(base_stat):
		result.append(base_stat)
	for stat in STAT_NAMES:
		if stats.has(stat) and stat != base_stat:
			result.append(stat)
	return result


## Eine Zeile für einen Wert, z. B. "+7 Rüstung".
func stat_text(stat: String) -> String:
	return "+%s %s" % [format_number(stats[stat]), STAT_NAMES[stat]]


## Der Wertebereich in Klammern, z. B. "(5–10)".
func range_text(stat: String) -> String:
	if not ranges.has(stat):
		return ""
	var r: Vector2 = ranges[stat]
	return "(%s–%s)" % [format_number(r.x), format_number(r.y)]


## Text für den Tooltip (erste Zeile = Name).
func describe() -> String:
	var lines: Array[String] = [item_name]
	lines.append("%s · %s · Stufe %d" % [RARITY_NAMES[rarity], SLOT_NAMES[slot], item_level])
	if set_name != "":
		lines.append("Set: %s" % set_name)
	for stat in sorted_stats():
		lines.append("%s  %s" % [stat_text(stat), range_text(stat)])
	return "\n".join(lines)


static func format_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.1f" % value
