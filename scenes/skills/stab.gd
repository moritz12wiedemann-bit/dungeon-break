extends RefCounted
## Krieger: Stich. Kurzer Stich nach vorne, trifft nur einen Gegner, aber mit viel Schaden.
## Erweiterung 1 "Sturmstich": geht im Laufen (siehe "moving_upgrade"), stirbt der Gegner,
## kommt die Hälfte des Manas zurück.
## Erweiterung 2 "Aufgeladener Stich": Taste halten (bis 2 s), voll aufgeladen doppelter Schaden.

const REACH := 2.6
const HALF_ANGLE := deg_to_rad(35.0)
const DAMAGE := 3.0
## Zusätzlicher Schaden bei voller Aufladung (1.0 = +100 %).
const CHARGE_BONUS := 1.0


static func cast(player, aim: Vector3, target: Node3D, upgrade: int, charge: float) -> bool:
	var direction: Vector3 = aim - player.global_position
	direction.y = 0.0
	if direction.length() < 0.1:
		direction = player.global_transform.basis.z
	# Gegner unter dem Mauszeiger, wenn er nah genug ist, sonst der nächste vor der Figur.
	var victim: Node3D = null
	if target and not target.is_dead() and player.global_position.distance_to(target.global_position) <= REACH + 0.4:
		victim = target
		direction = target.global_position - player.global_position
		direction.y = 0.0
	else:
		victim = SkillEffects.nearest_enemy_in_cone(player, direction, REACH, HALF_ANGLE)
		if victim:
			direction = victim.global_position - player.global_position
			direction.y = 0.0
	var data := PlayerClasses.skill("krieger_stich")
	var charge_ratio := clampf(charge / data.max_charge, 0.0, 1.0) if upgrade == 2 else 0.0
	player.face_towards(player.global_position + direction)
	SkillEffects.thrust(player, direction, REACH * (1.0 + 0.3 * charge_ratio), 0.25 + 0.2 * charge_ratio,
		Color(1.0, 0.75, 0.3) if charge_ratio > 0.0 else Color(0.85, 0.9, 1.0))
	player.animator.play_action("Sword_Attack", 0.3)
	if victim == null:
		return true
	victim.take_damage(player.roll_damage(DAMAGE * (1.0 + CHARGE_BONUS * charge_ratio)))
	if upgrade == 1 and victim.is_dead():
		player.restore_mana.call_deferred(data.mana / 2.0)
		DamageNumber.spawn_text(player, "+%d Mana" % int(data.mana / 2.0), Color(0.4, 0.6, 1.0))
	return true
