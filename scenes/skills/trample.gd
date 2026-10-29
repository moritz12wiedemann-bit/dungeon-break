class_name Trample
extends RefCounted
## Templer: Trampeln (Ultimate). Braucht Stacks (je getötetem Gegner einer, player.gd
## _on_enemy_killed): erst mit NEEDED einsetzbar, verbraucht alle. Beschwört RIDERS Reiter, die
## nebeneinander über ein großes Gebiet in Richtung Mauszeiger preschen (siehe trample_rider.gd).
## Erweiterung 1 "Endlose Herde": Abklingzeit 10 s ("upgrade_cooldown"), braucht NEEDED_FAST Stacks.
## Erweiterung 2 "Niedergeritten": Getroffene machen 10 s lang 50 % weniger Schaden.
## Die Pferde: HorseModel (Farm-Animals-Pack, grau).

const NEEDED := 20
const NEEDED_FAST := 30
const RIDERS := 5
const LANE_GAP := 2.0
const LENGTH := 16.0
const SECONDS := 0.9
const DAMAGE := 3.0
const WEAKEN := 0.5
const WEAKEN_SECONDS := 10.0


## So viele Stacks braucht man mit der gewählten Erweiterung.
static func stacks_needed() -> int:
	return NEEDED_FAST if GameState.skill_upgrade("templer_trampeln") == 1 else NEEDED


static func cast(player, aim: Vector3, _target: Node3D, upgrade: int, _charge: float) -> bool:
	var needed := stacks_needed()
	if player.buff_stacks("trampeln") < needed:
		DamageNumber.spawn_text(player, "Trampeln: %d / %d" % [player.buff_stacks("trampeln"), needed], Color(0.7, 0.7, 0.7))
		return false
	player.end_buff("trampeln")
	var direction: Vector3 = aim - player.global_position
	direction.y = 0.0
	if direction.length() < 0.1:
		direction = player.global_transform.basis.z
	direction = direction.normalized()
	var side := direction.cross(Vector3.UP)
	# Die Herde kommt von hinten und prescht am Spieler vorbei nach vorne.
	var start: Vector3 = player.global_position - direction * (LENGTH * 0.35)
	for i in RIDERS:
		var offset := (i - (RIDERS - 1) / 2.0) * LANE_GAP
		var rider := TrampleRider.new(player, start + side * offset, direction, LENGTH, SECONDS, randf() * 0.15,
				DAMAGE, WEAKEN if upgrade == 2 else 0.0, WEAKEN_SECONDS)
		player.get_tree().current_scene.add_child(rider)
	player.animator.play_action("Spell_Shoot", 0.4)
	SkillEffects.burst_ring(player, Color(1.0, 0.85, 0.45, 0.8), 6.0, 0.6)
	return true
