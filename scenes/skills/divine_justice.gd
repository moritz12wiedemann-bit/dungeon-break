extends RefCounted
## Templer: Gottes Gerechtigkeit. Dauerhafte Aura, sobald gelernt ("aura" in PlayerClasses,
## player.gd _sync_auras): Gegner im Umkreis RADIUS mit weniger als THRESHOLD Leben werden
## sofort exekutiert. Zählt nur, wenn die Aura den Gegner tötet.
## Erweiterung 1 "Gerechter Zorn": +1 Zorn pro Exekution.
## Erweiterung 2 "Heiliges Urteil": pro Exekution 0,5 % des maximalen Lebens geheilt.

const RADIUS := 3.0
const THRESHOLD := 0.05
const RAGE := 1.0
const HEAL := 0.005


## Alle 0,2 Sekunden.
static func tick(player) -> bool:
	var upgrade := GameState.skill_upgrade("templer_gerechtigkeit")
	for enemy in SkillEffects.enemies_around(player.get_tree(), player.global_position, RADIUS):
		var health: Health = enemy.health
		if health.current > health.max_health * THRESHOLD:
			continue
		var spot: Vector3 = enemy.global_position
		SkillEffects.lightning(player.get_tree(), spot + Vector3(0, 6, 0), spot + Vector3(0, 0.2, 0), Color(1.0, 0.85, 0.4))
		enemy.take_damage(health.current)
		if upgrade == 1:
			player.restore_mana(RAGE)
		elif upgrade == 2:
			player.health.heal(maxi(int(round(player.health.max_health * HEAL)), 1))
	return true
