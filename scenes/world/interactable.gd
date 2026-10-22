class_name Interactable
extends StaticBody3D
## Etwas, das der Spieler anklicken und benutzen kann (Altar, Portal, später Truhen usw.).
## Der Spieler läuft hin und ruft interact() auf, sobald er nah genug ist.
## Eigene Objekte erben von diesem Skript und überschreiben interact().

## Aus dieser Entfernung (Meter) kann der Spieler es benutzen.
@export var interact_range: float = 2.5


func interact(_player: Node) -> void:
	pass
