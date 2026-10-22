extends Node3D
## Test-Dungeon: vier Räume mit Gängen, Gegner und ein großer Brocken als "Boss".
## Berechnet beim Start das Navigations-Netz, verbindet die Bildschirm-Anzeige
## mit dem Spieler und zählt, wie viele Gegner noch leben.

@onready var nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $HUD

var _enemies_left: int = 0


func _ready() -> void:
	nav_region.bake_navigation_mesh(false)

	hud.track_player(player.health)
	player.died.connect(hud.show_game_over)

	for enemy in get_tree().get_nodes_in_group("enemies"):
		_enemies_left += 1
		enemy.died.connect(_on_enemy_died)
	hud.set_enemies_left(_enemies_left)


func _on_enemy_died() -> void:
	_enemies_left -= 1
	hud.set_enemies_left(_enemies_left)
	if _enemies_left == 0 and not player.is_dead():
		hud.show_victory()
