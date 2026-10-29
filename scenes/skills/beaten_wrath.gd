class_name BeatenWrath
extends RefCounted
## Krieger: Zorn des Geschlagenen. 10 s lang pro Sekunde 3 % des maximalen Lebens verlieren
## und dafür 2 Zorn bekommen. Tötet nicht: bei 1 Leben endet der Buff.
## Erweiterung 1 "Umgekehrter Zorn": pro Sekunde 2 Zorn verbrauchen, 3 % Leben herstellen;
## endet, wenn der Zorn nicht mehr reicht.
## Erweiterung 2 "Blutrausch": solange der Buff läuft, verkürzt jeder getötete Gegner die
## Abklingzeit um KILL_COOLDOWN_CUT Sekunden (siehe player.gd _on_enemy_killed).

const SECONDS := 10.0
const HEALTH_PER_SECOND := 0.03
const RAGE_PER_SECOND := 2.0
const KILL_COOLDOWN_CUT := 3.0


static func cast(player, _aim: Vector3, _target: Node3D, upgrade: int, _charge: float) -> bool:
	if upgrade == 1 and player.mana < RAGE_PER_SECOND:
		DamageNumber.spawn_text(player, "Nicht genug Zorn", Color(0.85, 0.3, 0.3))
		return false
	if upgrade != 1 and player.health.current <= 1:
		DamageNumber.spawn_text(player, "Zu wenig Leben", Color(0.85, 0.3, 0.3))
		return false
	player.add_timed_buff("geschlagen", SECONDS, {}, 1.0)
	player.animator.play_action("Hit_Chest", 0.5)
	var color := Color(0.4, 1.0, 0.45, 0.8) if upgrade == 1 else Color(1.0, 0.25, 0.15, 0.85)
	SkillEffects.burst_ring(player, color, 2.0, 0.5)
	return true


## Jede Sekunde, solange der Buff läuft. false = Buff endet.
static func tick(player) -> bool:
	var amount := int(round(player.health.max_health * HEALTH_PER_SECOND))
	if GameState.skill_upgrade("krieger_geschlagen") == 1:
		if player.mana < RAGE_PER_SECOND:
			return false
		player.mana -= RAGE_PER_SECOND
		player.health.heal(amount)
		DamageNumber.spawn_text(player, "+%d" % amount, Color(0.4, 1.0, 0.4))
		return true
	var lost: int = mini(amount, player.health.current - 1)
	if lost > 0:
		player.health.take_damage(lost)
	player.restore_mana(RAGE_PER_SECOND)
	return player.health.current > 1
