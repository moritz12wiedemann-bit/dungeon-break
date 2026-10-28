extends RefCounted
## Krieger: 1000 Schläge. Gedrückt halten: im Stehen immer wieder in Richtung Mauszeiger schlagen
## (so schnell wie normale Angriffe). Der erste Schlag macht 50 % Schaden, jeder Schlag gibt
## einen Stack "1000 Schläge" (+10 % Schaden pro Stack, höchstens 30). Ohne Schlagen gehen
## alle 0,5 s 1 Stack verloren (siehe player.gd add_buff_stacks).
## Erweiterung 1 "Wuchtschläge": Gegner um den Getroffenen herum bekommen 30 % des Schadens.
## Erweiterung 2 "Standhafte Schläge": pro Stack +0,5 % Angriffstempo und +1 Rüstung (player.gd _buff_stat).

const REACH := 2.2
const HALF_ANGLE := deg_to_rad(50.0)
const BASE_DAMAGE := 0.5
const DAMAGE_PER_STACK := 0.1
const SPLASH_RADIUS := 2.0
const SPLASH_DAMAGE := 0.3
const ANIMATIONS := ["Sword_Regular_B", "Melee_Hook"]


static func cast(player, aim: Vector3, target: Node3D, upgrade: int, _charge: float) -> bool:
	var direction: Vector3 = aim - player.global_position
	direction.y = 0.0
	if direction.length() < 0.1:
		direction = player.global_transform.basis.z
	var victim: Node3D = null
	if target and not target.is_dead() and player.global_position.distance_to(target.global_position) <= REACH + 0.4:
		victim = target
	else:
		victim = SkillEffects.nearest_enemy_in_cone(player, direction, REACH, HALF_ANGLE)
	if victim:
		direction = victim.global_position - player.global_position
		direction.y = 0.0
	player.face_towards(player.global_position + direction)
	var interval: float = player.attack_cooldown
	player.animator.play_action(ANIMATIONS[randi() % ANIMATIONS.size()], interval, true)
	var stacks: int = player.buff_stacks("tausend")
	player.hit_later(func(): SkillEffects.slash_arc(player, direction, 1.8, deg_to_rad(35.0), Color(1.0, 0.55, 0.25).lerp(Color(1, 0.2, 0.1), stacks / 30.0)))
	if victim:
		var damage: int = player.roll_damage(BASE_DAMAGE * (1.0 + DAMAGE_PER_STACK * stacks))
		# Schaden erst, wenn das Schwert in der Animation trifft.
		player.hit_later(func():
			if not is_instance_valid(victim) or victim.is_dead():
				return
			var hit_point := victim.global_position
			victim.take_damage(damage)
			if upgrade == 1:
				for enemy in SkillEffects.enemies_around(player.get_tree(), hit_point, SPLASH_RADIUS, victim):
					enemy.take_damage(maxi(int(round(damage * SPLASH_DAMAGE)), 1)))
	# Stacks verfallen erst, wenn bis kurz nach dem nächsten möglichen Schlag nichts kommt.
	player.add_buff_stacks("tausend", 1, interval + 0.25)
	return true
