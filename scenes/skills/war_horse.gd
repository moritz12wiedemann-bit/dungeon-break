extends RefCounted
## Templer: Streitross. 5 s reiten mit doppeltem Tempo; Buffs und Hämmer wirken weiter,
## angreifen und Fähigkeiten gehen nicht (player.gd is_mounted).
## Erweiterung 1 "Gepanzertes Ross": beim Reiten 20 % weniger erlittener Schaden.
## Erweiterung 2 "Ritterlicher Abstieg": danach 10 s lang +25 % Rüstung (on_end).
## Ein Pferdemodell gibt es noch nicht.

const SECONDS := 5.0
const MOVE_SPEED := 100.0
const DAMAGE_REDUCTION := 20.0
const AFTER_SECONDS := 10.0
const AFTER_ARMOR := 25.0


static func cast(player, _aim: Vector3, _target: Node3D, upgrade: int, _charge: float) -> bool:
	var stats := {"move_speed": MOVE_SPEED}
	if upgrade == 1:
		stats["damage_reduction"] = DAMAGE_REDUCTION
	player.add_timed_buff("pferd", SECONDS, stats)
	SkillEffects.burst_ring(player, Color(0.9, 0.75, 0.45, 0.7), 2.0, 0.4)
	BuffRing.attach(player, "pferd", Color(0.95, 0.8, 0.45, 0.45), 0.8)
	return true


## Beim Absteigen (Buff "pferd" ist abgelaufen).
static func on_end(player) -> void:
	if GameState.skill_upgrade("templer_pferd") == 2:
		player.add_timed_buff("pferd_ruestung", AFTER_SECONDS, {"armor_percent": AFTER_ARMOR})
