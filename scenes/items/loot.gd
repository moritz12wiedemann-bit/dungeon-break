class_name Loot
extends RefCounted
## Beute außer Ausrüstung: Gold und Orbs von Gegnern und Kisten, Preise beim Händler,
## Material beim Zerlegen. Alle Zahlen stehen hier oben und lassen sich leicht anpassen.

## Pro Beute-Stufe (0 = normaler Gegner, 1 = großer Gegner, 2 = Boss, 3 = Kiste):
## Chance auf Gold, Gold-Faktor, Chance auf einen Orb, Anzahl Orbs.
const DROPS := [
	{"gold_chance": 0.6, "gold": 1.0, "orb_chance": 0.01, "orbs": 1},
	{"gold_chance": 1.0, "gold": 3.0, "orb_chance": 0.05, "orbs": 1},
	{"gold_chance": 1.0, "gold": 12.0, "orb_chance": 0.5, "orbs": 1},
	{"gold_chance": 1.0, "gold": 6.0, "orb_chance": 0.2, "orbs": 1},
]
const CHEST_TIER := 3
## Gold pro Haufen auf Stufe 1 (wird mit Faktor und Stufe größer).
const GOLD_MIN := 3
const GOLD_MAX := 8
## Preis eines Gegenstands = (Grundpreis + Preis pro Stufe × Stufe) × Faktor der Seltenheit.
const PRICE_BASE := 10
const PRICE_PER_LEVEL := 4
const PRICE_RARITY := {
	ItemData.Rarity.NORMAL: 1.0,
	ItemData.Rarity.MAGIC: 2.5,
	ItemData.Rarity.RARE: 6.0,
	ItemData.Rarity.LEGENDARY: 15.0,
	ItemData.Rarity.SET: 15.0,
}
## Verkaufen bringt diesen Anteil des Kaufpreises.
const SELL_RATIO := 0.25
## Zerlegen: Altmetall [min, max] und Chance auf einen Orb je Seltenheit.
const SALVAGE := {
	ItemData.Rarity.NORMAL: [1, 2, 0.0],
	ItemData.Rarity.MAGIC: [2, 3, 0.03],
	ItemData.Rarity.RARE: [3, 5, 0.1],
	ItemData.Rarity.LEGENDARY: [6, 8, 0.35],
	ItemData.Rarity.SET: [6, 8, 0.35],
}


## Lässt Gold und Orbs für Beute-Stufe `tier` um `where` herum fallen.
static func drop_extras(tier: int, level: int, where: Vector3, tree: SceneTree) -> void:
	var table: Dictionary = DROPS[tier]
	if randf() < table.gold_chance:
		GroundPickup.drop_gold(roll_gold(table.gold, level), scatter(where), tree)
	if randf() < table.orb_chance:
		for i in table.orbs:
			GroundPickup.drop_material(GameMaterials.ORBS.pick_random(), 1, scatter(where), tree)


## Lässt alles aus einer Kiste fallen: Gold, 1–2 Gegenstände, vielleicht einen Orb.
static func drop_chest(level: int, where: Vector3, tree: SceneTree) -> void:
	drop_extras(CHEST_TIER, level, where, tree)
	for i in randi_range(1, 2):
		GroundItem.drop(ItemGenerator.create_item(ItemGenerator.roll_rarity(1), level), scatter(where), tree)


static func roll_gold(factor: float, level: int) -> int:
	return maxi(int(round(randi_range(GOLD_MIN, GOLD_MAX) * factor * (1.0 + 0.5 * (level - 1)))), 1)


static func buy_price(item: ItemData) -> int:
	return int(round((PRICE_BASE + PRICE_PER_LEVEL * item.item_level) * PRICE_RARITY[item.rarity]))


static func sell_price(item: ItemData) -> int:
	return maxi(int(round(buy_price(item) * SELL_RATIO)), 1)


## Zerlegt `item` und gibt zurück, was dabei herauskommt: Material-Name → Anzahl.
static func salvage(item: ItemData) -> Dictionary:
	var table: Array = SALVAGE[item.rarity]
	var result := {GameMaterials.SCRAP: randi_range(table[0], table[1])}
	if randf() < table[2]:
		var orb: String = GameMaterials.ORBS.pick_random()
		result[orb] = result.get(orb, 0) + 1
	return result


## Zufällige Stelle 0.6–1.6 m neben `where`.
static func scatter(where: Vector3) -> Vector3:
	var angle := randf() * TAU
	return where + Vector3(cos(angle), 0, sin(angle)) * randf_range(0.6, 1.6)
