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

var _has_saved := false
var _level: int = 1
var _xp: int = 0
var _health: int = 0
var _bag: Array[ItemData] = []
var _equipped: Dictionary = {}


## Öffnet einen neuen, zufällig erzeugten Dungeon.
func enter_new_dungeon(player: Node) -> void:
	save_player(player)
	dungeon_level = _level
	dungeon_seed = randi()
	get_tree().change_scene_to_file.call_deferred(DUNGEON_SCENE)


## Bringt den Spieler in die Stadt.
func go_to_town(player: Node) -> void:
	save_player(player)
	get_tree().change_scene_to_file.call_deferred(TOWN_SCENE)


## Merkt sich die Werte der Spielerfigur.
func save_player(player: Node) -> void:
	_has_saved = true
	_level = player.experience.level
	_xp = player.experience.xp
	_health = player.health.current
	_bag = player.inventory.bag.duplicate()
	_equipped = player.inventory.equipped.duplicate()


## Gibt einer neuen Spielerfigur die gemerkten Werte zurück (am Spielstart: nichts zu tun).
func restore_player(player: Node) -> void:
	if not _has_saved:
		return
	player.experience.level = _level
	player.experience.xp = _xp
	player.inventory.bag = _bag.duplicate()
	player.inventory.equipped = _equipped.duplicate()
	player.recalculate_stats()
	player.health.current = clampi(_health, 1, player.health.max_health)
