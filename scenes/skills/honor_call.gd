extends RefCounted
## Krieger: Ehrenruf. Kampfruf, 15 s lang machen normale Angriffe 20 % mehr Schaden
## und sind 25 % schneller. Kostet keinen Zorn.
## Erweiterung 1 "Kampfschrei": stattdessen +30 % Schaden, kostet dafür 15 Zorn (siehe "upgrade_mana").
## Erweiterung 2 "Sturmruf": zusätzlich +15 % Bewegungstempo.

const SECONDS := 15.0
const DAMAGE := 20.0
const STRONG_DAMAGE := 30.0
const ATTACK_SPEED := 25.0
const MOVE_SPEED := 15.0


static func cast(player, _aim: Vector3, _target: Node3D, upgrade: int, _charge: float) -> bool:
	var stats := {"basic_damage": STRONG_DAMAGE if upgrade == 1 else DAMAGE, "basic_attack_speed": ATTACK_SPEED}
	if upgrade == 2:
		stats["move_speed"] = MOVE_SPEED
	player.add_timed_buff("ehrenruf", SECONDS, stats)
	player.animator.play_action("Spell_Shoot", 0.5)
	SkillEffects.burst_ring(player, Color(1.0, 0.8, 0.35, 0.9), 3.5, 0.6)
	DamageNumber.spawn_text(player, "Ehrenruf!", Color(1.0, 0.85, 0.4))
	return true
