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

var current: int


func _ready() -> void:
	current = max_health


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
