extends Node3D
## Testlevel. Berechnet beim Start das Navigations-Netz (wo man laufen kann),
## damit wir es nach jeder Änderung am Level nicht von Hand neu "backen" müssen.

@onready var nav_region: NavigationRegion3D = $NavigationRegion3D


func _ready() -> void:
	nav_region.bake_navigation_mesh(false)
