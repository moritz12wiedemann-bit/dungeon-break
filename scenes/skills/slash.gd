extends RefCounted
## Krieger: Slash. Großer, breiter Schwerthieb in Richtung Mauszeiger, trifft alle Gegner im Bogen.
## Kostet keinen Zorn, sondern bringt RAGE_PER_HIT Zorn pro getroffenem Gegner.
## Erweiterung 1 "Weiter Hieb": doppelt so groß, +20 % Schaden.
## Erweiterung 2 "Lähmender Hieb": Getroffene 10 s um 50 % langsamer und +30 % Schaden erleiden.

const RADIUS := 3.0
const HALF_ANGLE := deg_to_rad(70.0)
const DAMAGE := 1.6
const WIDE_SIZE := 2.0
const WIDE_DAMAGE := 1.2
const CRIPPLE_SLOW := 0.5
const CRIPPLE_VULNERABLE := 0.3
const CRIPPLE_SECONDS := 10.0
const RAGE_PER_HIT := 5.0


static func cast(player, aim: Vector3, _target: Node3D, upgrade: int, _charge: float) -> bool:
	var direction: Vector3 = aim - player.global_position
	direction.y = 0.0
	if direction.length() < 0.1:
		direction = player.global_transform.basis.z
	var radius := RADIUS * (WIDE_SIZE if upgrade == 1 else 1.0)
	var multiplier := DAMAGE * (WIDE_DAMAGE if upgrade == 1 else 1.0)
	var color := Color(0.75, 0.55, 1.0) if upgrade == 2 else Color(1.0, 0.85, 0.5)
	SkillEffects.slash_arc(player, direction, radius, HALF_ANGLE, color)
	player.animator.play_action("Sword_Regular_C", 0.35)
	var hits := SkillEffects.enemies_in_arc(player, direction, radius, HALF_ANGLE)
	player.restore_mana(RAGE_PER_HIT * hits.size())
	for enemy in hits:
		enemy.take_damage(player.roll_damage(multiplier))
		if upgrade == 2 and not enemy.is_dead():
			enemy.apply_slow(CRIPPLE_SLOW, CRIPPLE_SECONDS)
			enemy.apply_vulnerable(CRIPPLE_VULNERABLE, CRIPPLE_SECONDS)
	return true
