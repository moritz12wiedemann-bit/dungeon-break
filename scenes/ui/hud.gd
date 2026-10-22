extends CanvasLayer
## Bildschirm-Anzeige: Lebensbalken des Spielers, übrige Gegner,
## "Gestorben"-Fenster mit Neustart und Siegesmeldung.

@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var enemies_label: Label = %EnemiesLabel
@onready var message_panel: PanelContainer = %MessagePanel
@onready var message_label: Label = %MessageLabel
@onready var restart_button: Button = %RestartButton


func _ready() -> void:
	message_panel.hide()
	restart_button.pressed.connect(_on_restart_pressed)


## Verbindet die Anzeige mit dem Lebenspunkte-Knoten des Spielers.
func track_player(health: Health) -> void:
	health.changed.connect(_on_player_health_changed)
	_on_player_health_changed(health.current, health.max_health)


func set_enemies_left(count: int) -> void:
	enemies_label.text = "Gegner übrig: %d" % count


func show_game_over() -> void:
	message_label.text = "Du bist gestorben!"
	message_panel.show()


func show_victory() -> void:
	message_label.text = "Dungeon gesäubert!"
	message_panel.show()


func _on_player_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d / %d" % [current, maximum]


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
