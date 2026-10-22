class_name Experience
extends Node
## Erfahrungspunkte (XP) und Stufe des Spielers.
## Je höher die Stufe, desto mehr XP braucht man für die nächste.
## Die Formel steht in xp_for_next_level() und lässt sich dort leicht anpassen.

## Wird ausgelöst, wenn sich XP oder Stufe ändern (für die Anzeige).
signal changed(level: int, xp: int, xp_needed: int)
## Wird bei jedem Stufenaufstieg ausgelöst.
signal leveled_up(new_level: int)

## Höchste erreichbare Stufe.
@export var max_level: int = 100
## So viele XP braucht man für Stufe 1 → 2.
@export var base_xp: int = 100
## Wie stark die benötigten XP mit der Stufe wachsen (1 = gleichmäßig, größer = steiler).
@export var growth: float = 1.6

var level: int = 1
## XP, die man in der aktuellen Stufe schon gesammelt hat.
var xp: int = 0


## Wie viele XP man auf Stufe `for_level` braucht, um aufzusteigen.
## Beispiele mit den Standardwerten: Stufe 1 = 100, Stufe 10 ≈ 3.981, Stufe 50 ≈ 52.250, Stufe 99 ≈ 156.700.
func xp_for_next_level(for_level: int = level) -> int:
	return int(round(base_xp * pow(for_level, growth)))


func is_max_level() -> bool:
	return level >= max_level


func add_xp(amount: int) -> void:
	if amount <= 0 or is_max_level():
		return
	xp += amount
	while not is_max_level() and xp >= xp_for_next_level():
		xp -= xp_for_next_level()
		level += 1
		leveled_up.emit(level)
	if is_max_level():
		xp = 0
	changed.emit(level, xp, xp_for_next_level())
