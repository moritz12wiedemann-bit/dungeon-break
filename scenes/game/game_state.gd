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

## Wird ausgelöst, wenn sich Karten, Arcana, Klasse, Fähigkeiten oder Passive ändern
## (der Spieler rechnet dann seine Werte neu aus).
signal progress_changed

## Augment-Karten (siehe AugmentCards): gekaufte und ausgerüstete Karten, maximales Arcana.
var owned_cards: Array[String] = []
var equipped_cards: Array[String] = []
var max_arcana: int = AugmentCards.START_ARCANA
## Klasse des Spielers (siehe PlayerClasses). Vorerst immer der Krieger.
var player_class: String = PlayerClasses.START_CLASS
## Gelernte Fähigkeiten (beim magischen Ältesten, je 1 Punkt; 1 Punkt pro Spielerstufe).
var learned_skills: Array[String] = []
## Fähigkeit → gewählte Erweiterung (1 = erste, 2 = zweite; fehlt = keine). Kostet auch 1 Punkt.
var skill_upgrades: Dictionary = {}
## Gewählte passive Fähigkeiten (höchstens PlayerClasses.MAX_PASSIVES).
var passives: Array[String] = []
## Belegung der Skill-Leiste: Q, W, E, R, Linksklick, Rechtsklick ("" = leer).
var skill_bar: Array[String] = []

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


func _ready() -> void:
	set_player_class(player_class)


## Wechselt die Klasse: Fähigkeiten, Erweiterungen und Passive fangen von vorne an.
func set_player_class(class_id: String) -> void:
	player_class = class_id
	learned_skills.clear()
	skill_upgrades.clear()
	passives.clear()
	skill_bar.assign(PlayerClasses.CLASSES[class_id].bar)
	progress_changed.emit()


## Gewählte Erweiterung einer Fähigkeit (0 = keine).
func skill_upgrade(skill_id: String) -> int:
	return skill_upgrades.get(skill_id, 0)


## Fähigkeiten, die man auf die Skill-Leiste legen kann: Standardangriff + gelernte.
func usable_skills() -> Array[String]:
	var list: Array[String] = [PlayerClasses.CLASSES[player_class].basic_attack]
	list.append_array(learned_skills)
	return list


## Noch freie Fähigkeitspunkte bei Spielerstufe `level`.
func free_skill_points(level: int) -> int:
	return level - learned_skills.size() - skill_upgrades.size()


## Punkte, die in Fähigkeiten (und ihre Erweiterungen) innerhalb der Ringe unter `ring` stecken.
## `ignore`: diese Fähigkeit nicht mitzählen; `ignore_upgrade_only`: nur ihre Erweiterung nicht.
func points_below_ring(ring: int, ignore: String = "", ignore_upgrade_only: bool = false) -> int:
	var total := 0
	for id in learned_skills:
		if PlayerClasses.skill(id).get("ring", 0) >= ring:
			continue
		if id != ignore or ignore_upgrade_only:
			total += 1
		if skill_upgrades.has(id) and id != ignore:
			total += 1
	return total


## Wie viele Punkte man in den inneren Ringen braucht, um Fähigkeiten im Ring `ring` zu lernen.
func ring_requirement(ring: int) -> int:
	return PlayerClasses.RINGS[ring].get("requires", 0)


func ring_unlocked(ring: int) -> bool:
	return points_below_ring(ring) >= ring_requirement(ring)


## Würde das Verlernen (bzw. nur das Ablegen der Erweiterung) Fähigkeiten weiter außen
## ungültig machen? Dann geht es nicht.
func removal_blocked(skill_id: String, upgrade_only: bool) -> bool:
	for id in learned_skills:
		if id == skill_id:
			continue
		var ring: int = PlayerClasses.skill(id).get("ring", 0)
		if PlayerClasses.skill(skill_id).get("ring", 0) >= ring:
			continue
		if points_below_ring(ring, skill_id, upgrade_only) < ring_requirement(ring):
			return true
	return false


## Lernt eine Fähigkeit und legt sie auf den ersten freien Platz der Leiste.
func learn_skill(skill_id: String) -> void:
	if skill_id in learned_skills:
		return
	learned_skills.append(skill_id)
	if not skill_id in skill_bar:
		for slot in PlayerClasses.AUTO_SLOTS:
			if skill_bar[slot] == "":
				skill_bar[slot] = skill_id
				break
	progress_changed.emit()


## Verlernt eine Fähigkeit (Punkte zurück, auch für die Erweiterung) und nimmt sie von der Leiste.
func unlearn_skill(skill_id: String) -> void:
	learned_skills.erase(skill_id)
	skill_upgrades.erase(skill_id)
	for slot in skill_bar.size():
		if skill_bar[slot] == skill_id:
			skill_bar[slot] = ""
	progress_changed.emit()


## Wählt Erweiterung `upgrade` (1 oder 2) einer gelernten Fähigkeit, 0 = Erweiterung ablegen.
func set_skill_upgrade(skill_id: String, upgrade: int) -> void:
	if upgrade == 0:
		skill_upgrades.erase(skill_id)
	else:
		skill_upgrades[skill_id] = upgrade
	progress_changed.emit()


## Legt eine Fähigkeit auf Platz `slot` der Leiste. Lag sie schon woanders, tauschen die Plätze.
func assign_skill(slot: int, skill_id: String) -> void:
	var old: int = skill_bar.find(skill_id) if skill_id != "" else -1
	if old >= 0:
		skill_bar[old] = skill_bar[slot]
	skill_bar[slot] = skill_id
	progress_changed.emit()


## Alle Fähigkeitspunkte zurück (Standardangriff bleibt auf der Leiste).
func reset_skills() -> void:
	for id in learned_skills.duplicate():
		unlearn_skill(id)
	passives.clear()
	progress_changed.emit()


## Summe eines Werts (z. B. "armor") über gewählte Passive und gewählte Erweiterungen.
func skill_stat_total(stat: String) -> float:
	var total := 0.0
	for id in passives:
		total += PlayerClasses.PASSIVES[id].get("stats", {}).get(stat, 0)
	for id in skill_upgrades:
		var upgrade: int = skill_upgrades[id]
		var data := PlayerClasses.skill(id)
		if upgrade > 0 and upgrade <= data.get("upgrades", []).size():
			total += data.upgrades[upgrade - 1].get("stats", {}).get(stat, 0)
	return total


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
