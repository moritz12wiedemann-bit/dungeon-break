class_name ItemGenerator
extends RefCounted
## Würfelt zufällige Gegenstände aus.
## Wie oft etwas fällt und wie gut es ist, hängt von der Beute-Stufe des Gegners ab
## (0 = normaler Gegner, 1 = großer Gegner, 2 = Boss). Alle Zahlen stehen hier oben
## in den Tabellen und lassen sich leicht anpassen.

## Pro Beute-Stufe: Chance, dass überhaupt etwas fällt, und wie viele Gegenstände.
const DROP_TABLE := [
	{"chance": 0.35, "min": 1, "max": 1},  # normaler Gegner
	{"chance": 0.8, "min": 1, "max": 2},   # großer Gegner
	{"chance": 1.0, "min": 2, "max": 4},   # Boss
]
## Pro Beute-Stufe: Gewichte für Normal, Magisch, Selten, Legendär, Set.
## Höhere Zahl = häufiger. Beispiel normaler Gegner: 70 von 100 Drops sind weiß.
const RARITY_WEIGHTS := [
	[70.0, 25.0, 4.5, 0.4, 0.1],
	[35.0, 40.0, 20.0, 3.5, 1.5],
	[5.0, 35.0, 40.0, 12.0, 8.0],
]
## Wie viele Zusatzwerte jede Seltenheit bekommt.
const AFFIX_COUNT := {
	ItemData.Rarity.NORMAL: 0,
	ItemData.Rarity.MAGIC: 1,
	ItemData.Rarity.RARE: 3,
	ItemData.Rarity.LEGENDARY: 4,
	ItemData.Rarity.SET: 3,
}
## Grundnamen je Platz.
const BASE_NAMES := {
	ItemData.Slot.HELM: ["Lederkappe", "Eisenhelm", "Kapuze", "Hörnerhelm"],
	ItemData.Slot.GLOVES: ["Lederhandschuhe", "Kettenhandschuhe", "Stulpen"],
	ItemData.Slot.ARMOR: ["Lederwams", "Kettenhemd", "Plattenpanzer", "Robe"],
	ItemData.Slot.PANTS: ["Lederhose", "Kettenbeinlinge", "Beinschienen"],
	ItemData.Slot.BOOTS: ["Stiefel", "Sandalen", "Eisenschuhe"],
	ItemData.Slot.WEAPON: ["Kurzschwert", "Axt", "Streitkolben", "Langschwert", "Dolch"],
}
const MAGIC_SUFFIXES := ["der Stärke", "des Bären", "der Schärfe", "des Fuchses", "der Ausdauer", "des Lichts"]
const RARE_WORDS_A := ["Blut", "Sturm", "Schatten", "Knochen", "Glut", "Frost", "Dämonen"]
const RARE_WORDS_B := ["biss", "wacht", "zorn", "schrei", "hüter", "fluch", "rufer"]
const LEGENDARY_NAMES := ["Die Ewige Glut", "Herz des Berges", "Schwur des Königs", "Seelenernte", "Mitternacht"]
## Sets: Name des Sets → Zusatz am Gegenstandsnamen.
const SETS := {
	"Rüstzeug des Wanderers": "des Wanderers",
	"Erbe des Grabwächters": "des Grabwächters",
	"Schwarzer Mond": "des Schwarzen Mondes",
}
## Zusatzwerte: Name → [Minimum, Maximum] auf Gegenstandsstufe 1 (wächst mit der Stufe).
const AFFIXES := {
	"damage": [1.0, 4.0],
	"armor": [3.0, 10.0],
	"health": [8.0, 25.0],
	"regen": [0.5, 2.0],
	"move_speed": [3.0, 8.0],
}


## Würfelt alle Gegenstände aus, die ein besiegter Gegner fallen lässt (kann leer sein).
static func roll_drops(loot_tier: int, item_level: int) -> Array[ItemData]:
	var tier := clampi(loot_tier, 0, DROP_TABLE.size() - 1)
	var result: Array[ItemData] = []
	if randf() > DROP_TABLE[tier].chance:
		return result
	for i in randi_range(DROP_TABLE[tier].min, DROP_TABLE[tier].max):
		result.append(create_item(_roll_rarity(tier), item_level))
	return result


## Erzeugt einen zufälligen Gegenstand mit der angegebenen Seltenheit.
static func create_item(rarity: ItemData.Rarity, item_level: int, slot: int = -1) -> ItemData:
	var item := ItemData.new()
	item.rarity = rarity
	item.item_level = maxi(item_level, 1)
	item.slot = slot if slot >= 0 else ItemData.Slot.values().pick_random()
	var scale := 1.0 + 0.15 * (item.item_level - 1)
	# Grundwert: Waffen machen Schaden, alles andere gibt Rüstung.
	if item.slot == ItemData.Slot.WEAPON:
		item.stats["damage"] = roundf(randf_range(3.0, 6.0) * scale)
	else:
		item.stats["armor"] = roundf(randf_range(4.0, 8.0) * scale)
	# Zusatzwerte je nach Seltenheit; legendär würfelt mit höheren Werten.
	var quality := 1.5 if rarity == ItemData.Rarity.LEGENDARY else 1.0
	var affix_names: Array = AFFIXES.keys()
	affix_names.shuffle()
	for affix in affix_names.slice(0, AFFIX_COUNT[rarity]):
		var range_: Array = AFFIXES[affix]
		# Laufgeschwindigkeit wächst nicht mit der Stufe, sonst wird man irgendwann zu schnell.
		var affix_scale := 1.0 if affix == "move_speed" else scale
		var value := randf_range(range_[0], range_[1]) * affix_scale * quality
		value = snappedf(value, 0.5) if affix == "regen" else roundf(value)
		item.stats[affix] = item.stats.get(affix, 0.0) + value
	item.item_name = _make_name(item)
	return item


static func _roll_rarity(tier: int) -> ItemData.Rarity:
	var weights: Array = RARITY_WEIGHTS[tier]
	var total := 0.0
	for w in weights:
		total += w
	var roll := randf() * total
	for i in weights.size():
		roll -= weights[i]
		if roll <= 0.0:
			return i as ItemData.Rarity
	return ItemData.Rarity.NORMAL


static func _make_name(item: ItemData) -> String:
	var base: String = BASE_NAMES[item.slot].pick_random()
	match item.rarity:
		ItemData.Rarity.MAGIC:
			return "%s %s" % [base, MAGIC_SUFFIXES.pick_random()]
		ItemData.Rarity.RARE:
			return "%s%s (%s)" % [RARE_WORDS_A.pick_random(), RARE_WORDS_B.pick_random(), base]
		ItemData.Rarity.LEGENDARY:
			return "%s (%s)" % [LEGENDARY_NAMES.pick_random(), base]
		ItemData.Rarity.SET:
			item.set_name = SETS.keys().pick_random()
			return "%s %s" % [base, SETS[item.set_name]]
	return base
