extends Node
## Spielstand, der Szenenwechsel überlebt (Autoload "GameState").
## Beim Wechsel Stadt ↔ Dungeon wird die Spielerfigur neu erzeugt. Damit Stufe,
## Erfahrung, Inventar und Leben erhalten bleiben, merkt sich GameState diese Werte
## und gibt sie der neuen Figur zurück.

const TOWN_SCENE := "res://scenes/levels/town.tscn"
const DUNGEON_SCENE := "res://scenes/levels/dungeon.tscn"
const ENDLESS_SCENE := "res://scenes/levels/endless.tscn"
## Höchste wählbare Monsterstufe.
const MAX_MONSTER_LEVEL := 100

## Stufe der Monster im aktuellen Dungeon (am Altar gewählt, 1–100).
## Im Endlos-Modus die Startstufe; sie steigt dort während des Laufs.
var dungeon_level: int = 1
## Zuletzt am Altar gewählte Stufe (0 = noch nie gewählt, dann wird die Spielerstufe vorgeschlagen).
var chosen_level: int = 0
## Zufalls-Startwert des aktuellen Dungeons. Gleicher Wert = gleiche Karte.
var dungeon_seed: int = 0

## Wird ausgelöst, wenn sich Karten, Arcana, Unterklasse oder Fähigkeiten ändern
## (der Spieler rechnet dann seine Werte neu aus).
signal progress_changed

## Augment-Karten (siehe AugmentCards): gekaufte und ausgerüstete Karten, maximales Arcana.
var owned_cards: Array[String] = []
var equipped_cards: Array[String] = []
var max_arcana: int = AugmentCards.START_ARCANA
## Unterklasse beim magischen Ältesten ("" = noch keine gewählt) und Stufen der Fähigkeiten.
var subclass: String = ""
var skill_levels: Dictionary = {}

## Angebot des Händlers (3 Gegenstände). Leer = beim nächsten Besuch neu würfeln.
var shop_items: Array[ItemData] = []

var _has_saved := false
var _level: int = 1
var _xp: int = 0
var _health: int = 0
var _bag: Array[ItemData] = []
var _equipped: Dictionary = {}
var _materials: Dictionary = {}
var _gold: int = 0


## Öffnet einen neuen, zufällig erzeugten Dungeon mit Monstern der Stufe `monster_level`.
func enter_new_dungeon(player: Node, monster_level: int) -> void:
	_enter(player, monster_level, DUNGEON_SCENE)


## Startet den Endlos-Modus (Arena) mit Monstern ab Stufe `monster_level`.
func enter_endless(player: Node, monster_level: int) -> void:
	_enter(player, monster_level, ENDLESS_SCENE)


func _enter(player: Node, monster_level: int, scene: String) -> void:
	save_player(player)
	dungeon_level = clampi(monster_level, 1, MAX_MONSTER_LEVEL)
	chosen_level = dungeon_level
	dungeon_seed = randi()
	get_tree().change_scene_to_file.call_deferred(scene)


## Wird aufgerufen, wenn der Boss eines Dungeons besiegt ist: der Händler bekommt neue Ware.
func complete_dungeon() -> void:
	shop_items.clear()


## Arcana, das die ausgerüsteten Karten gerade verbrauchen.
func used_arcana() -> int:
	var total := 0
	for id in equipped_cards:
		total += AugmentCards.CARDS[id].arcana
	return total


## Summe eines Werts (z. B. "health") über alle ausgerüsteten Karten.
func card_stat_total(stat: String) -> float:
	var total := 0.0
	for id in equipped_cards:
		total += AugmentCards.CARDS[id].stats.get(stat, 0)
	return total


## Bringt den Spieler in die Stadt. `full_health`: dort mit vollem Leben ankommen (z. B. nach dem Tod).
func go_to_town(player: Node, full_health: bool = false) -> void:
	save_player(player)
	if full_health:
		_health = -1
	get_tree().change_scene_to_file.call_deferred(TOWN_SCENE)


## Merkt sich die Werte der Spielerfigur.
func save_player(player: Node) -> void:
	_has_saved = true
	_level = player.experience.level
	_xp = player.experience.xp
	_health = player.health.current
	_bag = player.inventory.bag.duplicate()
	_equipped = player.inventory.equipped.duplicate()
	_materials = player.inventory.materials.duplicate()
	_gold = player.inventory.gold


## Gibt einer neuen Spielerfigur die gemerkten Werte zurück (am Spielstart: nichts zu tun).
func restore_player(player: Node) -> void:
	if not _has_saved:
		return
	player.experience.level = _level
	player.experience.xp = _xp
	player.inventory.bag = _bag.duplicate()
	player.inventory.equipped = _equipped.duplicate()
	player.inventory.materials = _materials.duplicate()
	player.inventory.gold = _gold
	player.recalculate_stats()
	# -1 = voll geheilt (siehe go_to_town).
	player.health.current = player.health.max_health if _health < 0 else clampi(_health, 1, player.health.max_health)
