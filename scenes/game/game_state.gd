extends Node
## Spielstand, der Szenenwechsel überlebt (Autoload "GameState").
## Beim Wechsel Stadt ↔ Dungeon wird die Spielerfigur neu erzeugt. Damit Stufe,
## Erfahrung, Inventar und Leben erhalten bleiben, merkt sich GameState diese Werte
## und gibt sie der neuen Figur zurück.

const TOWN_SCENE := "res://scenes/levels/town.tscn"
const DUNGEON_SCENE := "res://scenes/levels/dungeon.tscn"

## Stufe der Monster im aktuellen Dungeon (= Spielerstufe beim Betreten).
var dungeon_level: int = 1
## Zufalls-Startwert des aktuellen Dungeons. Gleicher Wert = gleiche Karte.
var dungeon_seed: int = 0

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


## Öffnet einen neuen, zufällig erzeugten Dungeon.
func enter_new_dungeon(player: Node) -> void:
	save_player(player)
	dungeon_level = _level
	dungeon_seed = randi()
	get_tree().change_scene_to_file.call_deferred(DUNGEON_SCENE)


## Wird aufgerufen, wenn der Boss eines Dungeons besiegt ist: der Händler bekommt neue Ware.
func complete_dungeon() -> void:
	shop_items.clear()


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
