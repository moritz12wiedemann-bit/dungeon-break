extends RefCounted
## Krieger: Hechtrolle. Schnelle Rolle in Richtung Mauszeiger.
## Erweiterung 1 "Gepanzerte Rolle": danach 5 s lang +10 % Rüstung.
## Erweiterung 2 "Flinke Rolle": danach 5 s lang +15 % Bewegungstempo.

const DISTANCE := 4.0
const SECONDS := 0.4
const BUFF_SECONDS := 5.0
const ARMOR_PERCENT := 10.0
const MOVE_SPEED := 15.0


static func cast(player, aim: Vector3, _target: Node3D, upgrade: int, _charge: float) -> bool:
	player.dash(aim - player.global_position, DISTANCE, SECONDS)
	player.animator.play_action("Roll", SECONDS + 0.15, true)
	SkillEffects.burst_ring(player, Color(0.55, 0.9, 0.5, 0.6), 1.2, 0.35)
	if upgrade == 1:
		player.add_timed_buff("rolle_ruestung", BUFF_SECONDS, {"armor_percent": ARMOR_PERCENT})
	elif upgrade == 2:
		player.add_timed_buff("rolle_tempo", BUFF_SECONDS, {"move_speed": MOVE_SPEED})
	return true
