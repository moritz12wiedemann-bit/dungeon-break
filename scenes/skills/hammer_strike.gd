extends RefCounted
## Templer: Hammerschlag. Ersetzt den Standardangriff (langsamer, 150 % Schaden, 2 Zorn pro
## Treffer; das macht player.gd _attack mit "attack_time", "damage" und "rage_per_hit").
## Erweiterung 1 "Kettenblitz": vom Getroffenen springt ein Blitz auf bis zu CHAIN_TARGETS
## Gegner (je CHAIN_DAMAGE des Schadens), jeweils höchstens CHAIN_RANGE Meter weit.
## Erweiterung 2 "Bollwerk": jeder Treffer +1 Stack Bollwerk (+5 Rüstung, ohne Obergrenze),
## alle Stacks weg nach 5 Sekunden ohne Angriff.

const CHAIN_TARGETS := 2
const CHAIN_DAMAGE := 0.4
const CHAIN_RANGE := 3.0


static func on_hit(player, target: Node3D, damage: int, upgrade: int) -> void:
	if upgrade == 1:
		var hit: Array[Node3D] = [target]
		var from: Vector3 = target.global_position
		var chain_damage := maxi(int(round(damage * CHAIN_DAMAGE)), 1)
		for i in CHAIN_TARGETS:
			var next: Node3D = null
			var best := CHAIN_RANGE
			for enemy in SkillEffects.enemies_around(player.get_tree(), from, CHAIN_RANGE):
				var distance := from.distance_to(enemy.global_position)
				if not enemy in hit and distance <= best:
					best = distance
					next = enemy
			if next == null:
				break
			SkillEffects.lightning(player.get_tree(), from + Vector3(0, 1.0, 0), next.global_position + Vector3(0, 1.0, 0))
			next.take_damage(chain_damage)
			hit.append(next)
			from = next.global_position
	elif upgrade == 2:
		player.add_buff_stacks("bollwerk", 1, PlayerClasses.BUFFS.bollwerk.hold)
