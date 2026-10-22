extends CanvasLayer
## Bildschirm-Anzeige: Lebensbalken, Erfahrungsbalken mit Stufe, Heiltrank-Knopf,
## Inventar-Fenster, Ort und übrige Gegner, kurze Meldungen und "Gestorben"-Fenster mit Wiederbeleben.

@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var xp_bar: ProgressBar = %XpBar
@onready var xp_label: Label = %XpLabel
@onready var potion_button: Button = %PotionButton
@onready var potion_cooldown: ColorRect = %PotionCooldown
@onready var potion_label: Label = %PotionLabel
@onready var enemies_label: Label = %EnemiesLabel
@onready var location_label: Label = %LocationLabel
@onready var toast_label: Label = %ToastLabel
@onready var message_panel: PanelContainer = %MessagePanel
@onready var message_label: Label = %MessageLabel
@onready var message_button: Button = %MessageButton
@onready var inventory_button: Button = %InventoryButton
@onready var inventory_panel: PanelContainer = %InventoryPanel

var _player: Node = null
## Was beim Klick auf den Knopf im Meldungsfenster passieren soll.
var _message_action: Callable
var _toast_tween: Tween


func _ready() -> void:
	message_panel.hide()
	toast_label.hide()
	enemies_label.hide()
	message_button.pressed.connect(_on_message_button_pressed)
	potion_button.pressed.connect(_on_potion_pressed)
	inventory_button.pressed.connect(inventory_panel.toggle)


func _process(_delta: float) -> void:
	if _player == null:
		return
	# Abklingzeit des Tranks: dunkle Fläche schrumpft von oben nach unten, Zahl zählt runter.
	var left: float = _player.potion_cooldown_left
	var ratio := clampf(left / _player.potion_cooldown, 0.0, 1.0)
	potion_cooldown.anchor_top = 1.0 - ratio
	potion_label.text = str(ceili(left)) if left > 0.0 else "1"


## Verbindet die Anzeige mit dem Spieler.
func track_player(player: Node) -> void:
	_player = player
	player.health.changed.connect(_on_player_health_changed)
	player.experience.changed.connect(_on_player_xp_changed)
	player.died.connect(_show_game_over)
	player.revived.connect(message_panel.hide)
	inventory_panel.track_player(player)
	_on_player_health_changed(player.health.current, player.health.max_health)
	var xp: Experience = player.experience
	_on_player_xp_changed(xp.level, xp.xp, xp.xp_for_next_level())


func set_enemies_left(count: int) -> void:
	enemies_label.show()
	enemies_label.text = "Gegner übrig: %d" % count


## Zeigt oben links, wo man gerade ist (z. B. "Stadt").
func set_location(text: String) -> void:
	location_label.text = text


## Zeigt oben in der Mitte kurz eine Meldung, die danach verblasst.
func show_toast(text: String, seconds: float = 4.0) -> void:
	toast_label.text = text
	toast_label.modulate.a = 1.0
	toast_label.show()
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(seconds)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 1.0)
	_toast_tween.tween_callback(toast_label.hide)


func _show_game_over() -> void:
	_show_message("Du bist gestorben!", "Wiederbeleben", _player.revive)


func _show_message(text: String, button_text: String, action: Callable) -> void:
	message_label.text = text
	message_button.text = button_text
	_message_action = action
	message_panel.show()


func _on_player_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d / %d" % [current, maximum]


func _on_player_xp_changed(level: int, xp: int, xp_needed: int) -> void:
	if _player.experience.is_max_level():
		xp_bar.max_value = 1
		xp_bar.value = 1
		xp_label.text = "Stufe %d (Maximum)" % level
		return
	xp_bar.max_value = xp_needed
	xp_bar.value = xp
	xp_label.text = "Stufe %d   %d / %d XP" % [level, xp, xp_needed]


func _on_potion_pressed() -> void:
	_player.drink_potion()


func _on_message_button_pressed() -> void:
	message_panel.hide()
	if _message_action.is_valid():
		_message_action.call()
