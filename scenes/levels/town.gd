extends Node3D
## Stadt (Hub): sicherer Ort ohne Gegner. Der Dungeon-Altar öffnet einen neuen Dungeon.
## Mit Taste T kommt man aus jedem Dungeon hierher zurück.

@onready var nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	nav_region.bake_navigation_mesh(false)
	hud.track_player(player)
	hud.set_location("Stadt")
	hud.show_toast("Klicke auf den Dungeon-Altar, um einen Dungeon zu betreten.")
