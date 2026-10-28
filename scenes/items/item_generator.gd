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
## Legendär und Set sind gleich selten (Set ist eine Alternative zu Legendär).
const RARITY_WEIGHTS := [
	[70.0, 25.0, 4.4, 0.3, 0.3],
	[35.0, 40.0, 20.0, 2.5, 2.5],
	[5.0, 35.0, 40.0, 10.0, 10.0],
]
## Grundnamen je Platz.
const BASE_NAMES := {
	ItemData.Slot.HELM: ["Lederkappe", "Eisenhelm", "Kapuze", "Hörnerhelm"],
	ItemData.Slot.GLOVES: ["Lederhandschuhe", "Kettenhandschuhe", "Stulpen"],
	ItemData.Slot.ARMOR: ["Lederwams", "Kettenhemd", "Plattenpanzer", "Robe"],
	ItemData.Slot.PANTS: ["Lederhose", "Kettenbeinlinge", "Beinschienen"],
	ItemData.Slot.BOOTS: ["Stiefel", "Sandalen", "Eisenschuhe"],
	ItemData.Slot.WEAPON: ["Kurzschwert", "Axt", "Streitkolben", "Langschwert", "Dolch"],
	ItemData.Slot.AMULET: ["Knochenamulett", "Silberkette", "Talisman", "Bernsteinanhänger", "Wolfszahnkette"],
	ItemData.Slot.BRACERS: ["Lederarmschienen", "Eisenarmschienen", "Nietenarmbänder", "Schuppenarmschienen"],
	ItemData.Slot.RING: ["Eisenring", "Silberring", "Siegelring", "Knochenring", "Rubinring", "Onyxring"],
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
## Grundwert je Platz: Waffen machen Schaden, Rüstungsteile geben Rüstung, Schmuck ist
## schwächer, dafür trägt man zwei Ringe. Wert und Bereich [Minimum, Maximum] auf
## Gegenstandsstufe 1 (wächst mit der Stufe). Nicht aufgeführte Plätze: DEFAULT_BASE.
const BASE_STATS := {
	ItemData.Slot.WEAPON: ["damage", 3.0, 7.0],
	ItemData.Slot.BRACERS: ["armor", 3.0, 7.0],
	ItemData.Slot.AMULET: ["health", 12.0, 30.0],
	ItemData.Slot.RING: ["damage", 1.0, 3.0],
}
const DEFAULT_BASE := ["armor", 5.0, 10.0]
## Zusatzwerte: Name → [Minimum, Maximum] auf Gegenstandsstufe 1.
const AFFIXES := {
	"damage": [1.0, 4.0],
	"armor": [3.0, 8.0],
	"health": [8.0, 25.0],
	"regen": [0.5, 2.0],
	"move_speed": [3.0, 8.0],
	"attack_speed": [3.0, 8.0],
}
## Diese Werte wachsen nicht mit der Stufe (sonst wird man irgendwann zu schnell).
const FIXED_STATS := ["move_speed", "attack_speed"]


## Würfelt alle Gegenstände aus, die ein besiegter Gegner fallen lässt (kann leer sein).
static func roll_drops(loot_tier: int, item_level: int) -> Array[ItemData]:
	var tier := clampi(loot_tier, 0, DROP_TABLE.size() - 1)
	var result: Array[ItemData] = []
	if randf() > DROP_TABLE[tier].chance:
		return result
	for i in randi_range(DROP_TABLE[tier].min, DROP_TABLE[tier].max):
		result.append(create_item(roll_rarity(tier), item_level))
	return result


## Erzeugt einen zufälligen Gegenstand mit der angegebenen Seltenheit.
static func create_item(rarity: ItemData.Rarity, item_level: int, slot: int = -1) -> ItemData:
	var item := ItemData.new()
	item.rarity = rarity
	item.item_level = maxi(item_level, 1)
	item.slot = slot if slot >= 0 else ItemData.ITEM_SLOTS.pick_random()
	item.base_stat = BASE_STATS.get(item.slot, DEFAULT_BASE)[0]
	item.base_name = BASE_NAMES[item.slot].pick_random()
	_add_stat(item, item.base_stat)
	for i in ItemData.STAT_COUNT[rarity] - 1:
		_add_stat(item, _free_affixes(item).pick_random())
	if rarity == ItemData.Rarity.SET:
		item.set_name = SETS.keys().pick_random()
	item.item_name = _make_name(item)
	return item


## Orb der Erweiterung: fügt einen zufälligen neuen Wert hinzu, die Seltenheit steigt.
## Gibt eine Fehlermeldung zurück oder "" bei Erfolg.
static func add_random_stat(item: ItemData) -> String:
	if item.rarity == ItemData.Rarity.SET:
		return "Set-Gegenstände kann man nur neu auswürfeln."
	if item.stats.size() >= ItemData.MAX_STATS:
		return "Der Gegenstand hat schon die meisten Werte (Legendär)."
	# Höchstens bis Selten (Gelb), nie zu Legendär.
	if item.stats.size() >= ItemData.MAX_STATS - 1:
		return "Mit diesem Orb geht es höchstens bis Selten (Gelb)."
	_add_stat(item, _free_affixes(item).pick_random())
	_update_rarity(item)
	return ""


## Orb der Läuterung: entfernt einen zufälligen Wert (nie den Grundwert), die Seltenheit sinkt.
static func remove_random_stat(item: ItemData) -> String:
	if item.rarity == ItemData.Rarity.SET:
		return "Set-Gegenstände kann man nur neu auswürfeln."
	var removable := item.sorted_stats().filter(func(stat): return stat != item.base_stat)
	if removable.is_empty():
		return "Der Grundwert kann nicht entfernt werden."
	var stat: String = removable.pick_random()
	item.stats.erase(stat)
	item.ranges.erase(stat)
	_update_rarity(item)
	return ""


## Orb des Wandels: würfelt alle Werte innerhalb ihrer Bereiche neu.
static func reroll_stats(item: ItemData) -> String:
	for stat in item.stats:
		item.stats[stat] = _roll_value(stat, item.ranges[stat])
	return ""


## Bereich eines Werts auf der Stufe des Gegenstands (Grundwert: Bereich hängt am Platz).
static func stat_range(stat: String, item: ItemData) -> Vector2:
	var low_high: Array = AFFIXES[stat]
	if stat == item.base_stat:
		low_high = BASE_STATS.get(item.slot, DEFAULT_BASE).slice(1)
	var scale := 1.0 if stat in FIXED_STATS else 1.0 + 0.15 * (item.item_level - 1)
	var low := _round_stat(stat, low_high[0] * scale)
	var high := maxf(_round_stat(stat, low_high[1] * scale), low)
	return Vector2(low, high)


static func _add_stat(item: ItemData, stat: String) -> void:
	var r := stat_range(stat, item)
	item.ranges[stat] = r
	item.stats[stat] = _roll_value(stat, r)


static func _roll_value(stat: String, r: Vector2) -> float:
	if stat == "regen":
		# In halben Schritten würfeln, jeder Schritt gleich wahrscheinlich.
		return r.x + 0.5 * randi_range(0, int(roundf((r.y - r.x) * 2.0)))
	return float(randi_range(int(r.x), int(r.y)))


static func _round_stat(stat: String, value: float) -> float:
	return maxf(snappedf(value, 0.5), 0.5) if stat == "regen" else maxf(roundf(value), 1.0)


## Zusatzwerte, die der Gegenstand noch nicht hat.
static func _free_affixes(item: ItemData) -> Array:
	return AFFIXES.keys().filter(func(stat): return not item.stats.has(stat))


## Seltenheit an die Zahl der Werte anpassen und den Namen neu bauen.
static func _update_rarity(item: ItemData) -> void:
	var count := item.stats.size()
	for rarity in [ItemData.Rarity.NORMAL, ItemData.Rarity.MAGIC, ItemData.Rarity.RARE, ItemData.Rarity.LEGENDARY]:
		if ItemData.STAT_COUNT[rarity] == count:
			item.rarity = rarity
	item.item_name = _make_name(item)


static func roll_rarity(tier: int) -> ItemData.Rarity:
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
	var base := item.base_name
	match item.rarity:
		ItemData.Rarity.MAGIC:
			return "%s %s" % [base, MAGIC_SUFFIXES.pick_random()]
		ItemData.Rarity.RARE:
			return "%s%s (%s)" % [RARE_WORDS_A.pick_random(), RARE_WORDS_B.pick_random(), base]
		ItemData.Rarity.LEGENDARY:
			return "%s (%s)" % [LEGENDARY_NAMES.pick_random(), base]
		ItemData.Rarity.SET:
			return "%s %s" % [base, SETS[item.set_name]]
	return base
