extends RefCounted
## Templer: Hammerwurf. Wirft einen Hammer, der um den Spieler kreist (siehe orbit_hammer.gd).
## Höchstens MAX_HAMMERS gleichzeitig, jeder mit eigener Zeit.
## Erweiterung 1 "Hammerschild": Hämmer blockieren Geschosse (Gruppe "projectile_blockers").
## Erweiterung 2 "Schwere Hämmer": doppelter Schaden, nur 5 statt 10 Sekunden.

const MAX_HAMMERS := 3
const SECONDS := 10.0
const HEAVY_SECONDS := 5.0
const DAMAGE := 0.8


static func cast(player, _aim: Vector3, _target: Node3D, upgrade: int, _charge: float) -> bool:
	var slot := OrbitHammer.free_slot(player, MAX_HAMMERS)
	if slot < 0:
		DamageNumber.spawn_text(player, "Schon %d Hämmer" % MAX_HAMMERS, Color(0.7, 0.7, 0.7))
		return false
	var heavy := upgrade == 2
	var hammer := OrbitHammer.new(player, slot, MAX_HAMMERS, HEAVY_SECONDS if heavy else SECONDS, DAMAGE * (2.0 if heavy else 1.0), upgrade == 1)
	player.get_tree().current_scene.add_child(hammer)
	player.animator.play_action("Throw", 0.4)
	return true
