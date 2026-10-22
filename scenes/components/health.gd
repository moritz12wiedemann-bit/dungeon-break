class_name Health
extends Node
## Lebenspunkte. Kann an jede Figur (Spieler, Gegner, später Kisten usw.)
## als Kind-Knoten gehängt werden. Andere Skripte hören auf die Signale,
## z. B. um die Lebensanzeige zu aktualisieren oder die Figur sterben zu lassen.

## Wird ausgelöst, wenn sich die Lebenspunkte ändern (Schaden oder Heilung).
signal changed(current: int, maximum: int)
## Wird ausgelöst, wenn Schaden genommen wurde. amount = wie viel.
signal damaged(amount: int)
## Wird einmal ausgelöst, wenn die Lebenspunkte auf 0 fallen.
signal died

## Maximale Lebenspunkte.
@export var max_health: int = 100
## Wie viele Lebenspunkte pro Sekunde von selbst zurückkommen (0 = keine).
@export var regen_per_second: float = 0.0

var current: int
## Sammelt Bruchteile der Regeneration, bis ein ganzer Lebenspunkt voll ist.
var _regen_buffer: float = 0.0


func _ready() -> void:
	current = max_health


func _process(delta: float) -> void:
	if regen_per_second <= 0.0 or is_dead() or current >= max_health:
		_regen_buffer = 0.0
		return
	_regen_buffer += regen_per_second * delta
	if _regen_buffer >= 1.0:
		var whole := int(_regen_buffer)
		_regen_buffer -= whole
		heal(whole)


func is_dead() -> bool:
	return current <= 0


## Zieht Lebenspunkte ab. Tote nehmen keinen Schaden mehr.
func take_damage(amount: int) -> void:
	if is_dead() or amount <= 0:
		return
	current = maxi(current - amount, 0)
	damaged.emit(amount)
	changed.emit(current, max_health)
	if current == 0:
		died.emit()


## Füllt Lebenspunkte auf, höchstens bis zum Maximum.
func heal(amount: int) -> void:
	if is_dead() or amount <= 0:
		return
	current = mini(current + amount, max_health)
	changed.emit(current, max_health)


## Setzt das Maximum neu (z. B. beim Stufenaufstieg). Aktuelle Lebenspunkte bleiben, höchstens bis zum neuen Maximum.
func set_max_health(value: int) -> void:
	max_health = maxi(value, 1)
	current = mini(current, max_health)
	changed.emit(current, max_health)


## Holt eine tote Figur mit `amount` Lebenspunkten zurück.
func revive(amount: int) -> void:
	current = clampi(amount, 1, max_health)
	_regen_buffer = 0.0
	changed.emit(current, max_health)
