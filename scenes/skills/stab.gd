extends RefCounted
## Krieger: Stich. Kurzer Stich nach vorne, trifft nur einen Gegner, aber mit viel Schaden.
## Kostet keinen Zorn, sondern bringt RAGE_ON_HIT Zorn, wenn er trifft (aufgeladen: egal wie viele).
## Erweiterung 1 "Sturmstich": geht im Laufen (siehe "moving_upgrade"), stirbt der Gegner,
## gibt es zusätzlich RAGE_ON_KILL Zorn.
## Erweiterung 2 "Aufgeladener Stich": Taste halten (bis 2 s), voll aufgeladen dreifacher Schaden
## und dreimal so lang und breit; trifft dann alle Gegner in seiner Bahn.

const REACH := 2.6
const HALF_ANGLE := deg_to_rad(35.0)
const DAMAGE := 3.0
## Schaden, Länge und Breite bei voller Aufladung (3.0 = dreimal so viel).
const CHARGE_MAX_FACTOR := 3.0
const RAGE_ON_HIT := 10.0
const RAGE_ON_KILL := 5.0


static func cast(player, aim: Vector3, target: Node3D, upgrade: int, charge: float) -> bool:
	var direction: Vector3 = aim - player.global_position
	direction.y = 0.0
	if direction.length() < 0.1:
		direction = player.global_transform.basis.z
	var data := PlayerClasses.skill("krieger_stich")
	var charge_ratio := clampf(charge / data.max_charge, 0.0, 1.0) if upgrade == 2 else 0.0
	var factor := lerpf(1.0, CHARGE_MAX_FACTOR, charge_ratio)
	var reach := REACH * factor
	# Breiter Stich: Trefferkegel wird mit breiter (aber höchstens 75°).
	var half_angle := minf(HALF_ANGLE * factor, deg_to_rad(75.0))
	# Gegner unter dem Mauszeiger, wenn er nah genug ist, sonst der nächste vor der Figur.
	var victim: Node3D = null
	if target and not target.is_dead() and player.global_position.distance_to(target.global_position) <= reach + 0.4:
		victim = target
		direction = target.global_position - player.global_position
		direction.y = 0.0
	else:
		victim = SkillEffects.nearest_enemy_in_cone(player, direction, reach, half_angle)
		if victim:
			direction = victim.global_position - player.global_position
			direction.y = 0.0
	player.face_towards(player.global_position + direction)
	SkillEffects.thrust(player, direction, reach, 0.25 * factor,
		Color(1.0, 0.75, 0.3) if charge_ratio > 0.0 else Color(0.85, 0.9, 1.0))
	player.animator.play_action("Sword_Attack", 0.3)
	if upgrade == 2:
		# Aufgeladener Stich: alle Gegner in der Bahn.
		var hits := SkillEffects.enemies_in_line(player, direction, reach, 0.25 * factor)
		if victim and not victim in hits:
			hits.append(victim)
		for enemy in hits:
			enemy.take_damage(player.roll_damage(DAMAGE * factor))
		if not hits.is_empty():
			player.restore_mana(RAGE_ON_HIT)
		return true
	if victim == null:
		return true
	victim.take_damage(player.roll_damage(DAMAGE * factor))
	player.restore_mana(RAGE_ON_HIT)
	if upgrade == 1 and victim.is_dead():
		player.restore_mana(RAGE_ON_KILL)
		DamageNumber.spawn_text(player, "+%d %s" % [int(RAGE_ON_KILL), PlayerClasses.resource_name(GameState.player_class)], Color(1.0, 0.62, 0.15))
	return true
