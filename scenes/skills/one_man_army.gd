extends RefCounted
## Krieger: Ein-Mann-Armee (Ultimate). 20 s lang 50 % weniger erlittener Schaden und
## 30 % mehr Schaden (normale Angriffe und Fähigkeiten). Kostet keinen Zorn.
## Erweiterung 1 "Unbändiger Zorn": solange sie läuft, 3 Zorn pro Sekunde.
## Erweiterung 2 "Kriegeraura": solange sie läuft, machen Gegner im Umkreis 20 % weniger
## Schaden und erleiden 20 % mehr (siehe army_aura.gd).

const SECONDS := 20.0
const DAMAGE_REDUCTION := 50.0
const DAMAGE := 30.0
const RAGE_PER_SECOND := 3.0


static func cast(player, _aim: Vector3, _target: Node3D, upgrade: int, _charge: float) -> bool:
	var stats := {"damage_reduction": DAMAGE_REDUCTION, "all_damage": DAMAGE}
	player.add_timed_buff("armee", SECONDS, stats, 1.0 if upgrade == 1 else 0.0)
	if upgrade == 2:
		ArmyAura.attach(player)
	player.animator.play_action("Sword_Heavy_Combo", 0.6)
	SkillEffects.burst_ring(player, Color(1.0, 0.45, 0.2, 0.9), 5.0, 0.7)
	DamageNumber.spawn_text(player, "Ein-Mann-Armee!", Color(1.0, 0.6, 0.3))
	return true


## Jede Sekunde (nur mit "Unbändiger Zorn"). false = Buff endet.
static func tick(player) -> bool:
	player.restore_mana(RAGE_PER_SECOND)
	return true
