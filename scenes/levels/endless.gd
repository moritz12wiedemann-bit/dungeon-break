extends "res://scenes/levels/dungeon.gd"
## Endlos-Modus (wie ein "Survivor"-Spiel): eine offene Arena, in der nach und nach
## immer mehr Monster rund um den Spieler auftauchen und direkt auf ihn zulaufen.
## Alle paar Kills steigt die Monsterstufe, bis der Spieler irgendwann fällt.
## Beute gibt es erst am Ende: Sie fällt neben dem Spieler zu Boden, wenn er stirbt.
## Erfahrung gibt es sofort für jeden Kill.

## Kantenlänge der Arena in Kästchen (je 2 m).
@export var arena_size: int = 18
## Nach so vielen Kills steigt die Monsterstufe um 1.
@export var kills_per_level: int = 8
## Sekunden zwischen zwei Monstern am Anfang ...
@export var spawn_interval_start: float = 2.0
## ... und frühestens (wird mit der Zeit schneller).
@export var spawn_interval_min: float = 0.45
## So viel schneller wird es pro Kill (Sekunden).
@export var spawn_speedup_per_kill: float = 0.03
## Höchstens so viele Monster gleichzeitig.
@export var max_alive: int = 30
## Abstand (Meter), in dem neue Monster um den Spieler herum auftauchen.
@export var spawn_distance_min: float = 9.0
@export var spawn_distance_max: float = 15.0

@export_group("Belohnung")
## Pro so vielen Kills ein Gegenstand (wie von einem normalen Gegner).
@export var kills_per_item: int = 5
## Pro so vielen Kills ein Gegenstand wie vom Boss.
@export var kills_per_boss_item: int = 25
## Pro so vielen Kills ein Orb.
@export var kills_per_orb: int = 30

var _monster_level: int = 1
var _kills: int = 0
var _spawn_left: float = 1.0
var _running := true


func _generate_layout() -> void:
	_generator.generate_arena(arena_size)


func _place_chests() -> void:
	pass


func _spawn_enemies() -> void:
	_monster_level = GameState.dungeon_level


func _setup_hud() -> void:
	hud.death_handler = _on_run_over
	_update_hud()
	hud.show_toast("Überlebe so lange du kannst! (T = Abbrechen, dann ohne Belohnung)")


func _process(delta: float) -> void:
	if not _running:
		return
	_spawn_left -= delta
	if _spawn_left > 0.0:
		return
	_spawn_left = maxf(spawn_interval_start - _kills * spawn_speedup_per_kill, spawn_interval_min)
	if enemies.get_child_count() < max_alive:
		_spawn_hunter()


func _spawn_hunter() -> void:
	var cell := _spawn_cell()
	if cell == Vector2i(-1, -1):
		return
	var scene := BRUTE_SCENE if _rng.randf() < 0.15 else ENEMY_SCENE
	var enemy := scene.instantiate()
	enemy.apply_level(_monster_level)
	enemy.hunt_player = true
	enemy.drops_loot = false
	enemy.position = _cell_to_world(cell)
	enemy.rotation.y = _rng.randf() * TAU
	enemies.add_child(enemy)
	enemy.died.connect(_on_hunter_died)
	# Kurz aus dem Boden steigen.
	var visual: Node3D = enemy.get_node("Visual")
	visual.scale = Vector3.ONE * 0.2
	visual.create_tween().tween_property(visual, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Ein freies Bodenkästchen im passenden Abstand zum Spieler (oder (-1, -1), wenn keins passt).
func _spawn_cell() -> Vector2i:
	var room := _generator.start_room()
	for attempt in 30:
		var cell := _generator.random_cell_in(room, _rng, 1)
		var distance := _cell_to_world(cell).distance_to(Vector3(player.global_position.x, 0, player.global_position.z))
		if distance >= spawn_distance_min and distance <= spawn_distance_max:
			return cell
	# Spieler steht in einer Ecke: dann eben irgendwo, aber nicht direkt neben ihm.
	for attempt in 30:
		var cell := _generator.random_cell_in(room, _rng, 1)
		if _cell_to_world(cell).distance_to(player.global_position) >= spawn_distance_min * 0.6:
			return cell
	return Vector2i(-1, -1)


func _on_hunter_died() -> void:
	if not _running:
		return
	_kills += 1
	if _kills % kills_per_level == 0:
		_monster_level = mini(_monster_level + 1, GameState.MAX_MONSTER_LEVEL)
		hud.show_toast("Die Monster werden stärker! Stufe %d" % _monster_level, 2.5)
	_update_hud()


func _update_hud() -> void:
	hud.set_location("Endlos-Modus · Monsterstufe %d" % _monster_level)
	hud.enemies_label.show()
	hud.enemies_label.text = "Besiegt: %d" % _kills


## Der Spieler ist gefallen: Monster verschwinden, die Belohnung fällt neben ihm zu Boden.
func _on_run_over() -> void:
	_running = false
	for enemy in enemies.get_children():
		enemy.set_physics_process(false)
		var tween := enemy.create_tween()
		tween.tween_property(enemy.get_node("Visual"), "scale", Vector3.ONE * 0.01, 0.5)
		tween.tween_callback(enemy.queue_free)
	_drop_rewards()
	hud.show_message("Endlos-Lauf vorbei!\n%d Gegner besiegt, Monsterstufe %d erreicht.\nDeine Belohnung liegt neben dir am Boden." % [_kills, _monster_level],
		"Aufstehen und einsammeln", _stand_up, "In die Stadt", player.restart_in_town)


## Je mehr Kills und je höher die erreichte Stufe, desto mehr und bessere Beute.
func _drop_rewards() -> void:
	var where := player.global_position
	var tree := get_tree()
	var gold := 0
	for i in _kills:
		gold += Loot.roll_gold(1.0, _monster_level)
	if gold > 0:
		GroundPickup.drop_gold(gold, Loot.scatter(where), tree)
	for i in _kills / kills_per_item:
		GroundItem.drop(ItemGenerator.create_item(ItemGenerator.roll_rarity(0), _monster_level), Loot.scatter(where), tree)
	for i in _kills / kills_per_boss_item:
		GroundItem.drop(ItemGenerator.create_item(ItemGenerator.roll_rarity(2), _monster_level), Loot.scatter(where), tree)
	for i in _kills / kills_per_orb:
		GroundPickup.drop_material(GameMaterials.ORBS.pick_random(), 1, Loot.scatter(where), tree)


## Mit vollem Leben aufstehen, Beute einsammeln, dann durch das Portal zurück in die Stadt.
func _stand_up() -> void:
	player.revive()
	player.health.heal(player.health.max_health)
	var portal := PORTAL_SCENE.instantiate()
	add_child(portal)
	portal.global_position = player.global_position + Vector3(3.0, 0, -3.0)
	if not _generator.is_floor(_world_to_cell(portal.global_position)):
		portal.global_position = _cell_to_world(_generator.start_room().get_center())
	hud.show_toast("Sammle deine Belohnung ein. Das Portal bringt dich in die Stadt.")
