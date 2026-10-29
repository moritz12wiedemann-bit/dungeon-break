class_name ShieldWall
extends RefCounted
## Templer: Schildwall. Gedrückt halten ("hold" in PlayerClasses): stehen bleiben, doppelte
## Rüstung, kostet jede Sekunde Zorn (5, mit "Unerschütterlich" 25). Endet beim Loslassen
## oder wenn der Zorn nicht mehr reicht.
## Erweiterung 1 "Dornenschild": Angreifer erleiden THORNS ihres Schadens (player.gd take_damage).
## Erweiterung 2 "Unerschütterlich": unverwundbar (player.gd take_damage).

const ARMOR_PERCENT := 100.0
const THORNS := 0.5


static func cast(player, _aim: Vector3, _target: Node3D, _upgrade: int, _charge: float) -> bool:
	# Läuft "für immer", bis man loslässt oder der Zorn ausgeht.
	player.add_timed_buff("schildwall", 100000.0, {"armor_percent": ARMOR_PERCENT}, 1.0)
	player.animator.play_action("Sword_Block")
	BuffRing.attach(player, "schildwall", Color(0.45, 0.65, 1.0, 0.7), 0.9)
	return true


## Jede Sekunde: Zorn bezahlen. false = nicht genug, Schildwall endet.
static func tick(player) -> bool:
	var cost := PlayerClasses.skill_cost("templer_schildwall", GameState.skill_upgrade("templer_schildwall"))
	if player.mana < cost:
		return false
	player.mana -= cost
	return true
