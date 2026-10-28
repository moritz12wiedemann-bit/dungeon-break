extends CanvasLayer
## Bildschirm-Anzeige: Lebensbalken, Erfahrungsbalken mit Stufe, Heiltrank-Knopf,
## Manabalken, Inventar-Fenster, Ort und übrige Gegner, kurze Meldungen und
## "Gestorben"-Fenster (Wiederbeleben oder in der Stadt neu starten).
## Escape schließt das oberste offene Fenster.

@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var mana_bar: ProgressBar = %ManaBar
@onready var mana_label: Label = %ManaLabel
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
@onready var second_button: Button = %SecondButton
@onready var inventory_button: Button = %InventoryButton
@onready var inventory_panel: PanelContainer = %InventoryPanel

var _player: Node = null
## Was beim Klick auf den Knopf im Meldungsfenster passieren soll.
var _message_action: Callable
var _second_action: Callable
var _toast_tween: Tween
## Fenster der Stadt-Figuren: Name → GameWindow (siehe open_window).
var _windows: Dictionary = {}
var _gold_label := Label.new()


func _ready() -> void:
	add_to_group("hud")
	_windows = {
		"smith": preload("res://scenes/ui/smith_window.gd").new(),
		"merchant": preload("res://scenes/ui/merchant_window.gd").new(),
	}
	for window in _windows.values():
		add_child(window)
	# Fenster unter dem Meldungsfenster ("Gestorben") halten.
	move_child(message_panel, -1)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_gold_label.add_theme_constant_override("outline_size", 4)
	_gold_label.add_theme_font_size_override("font_size", 16)
	_gold_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gold_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_gold_label.offset_left = 212
	_gold_label.offset_right = 360
	_gold_label.offset_top = -88
	_gold_label.offset_bottom = -64
	add_child(_gold_label)
	message_panel.hide()
	toast_label.hide()
	enemies_label.hide()
	message_button.pressed.connect(_on_message_button_pressed)
	second_button.pressed.connect(_on_second_button_pressed)
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
	mana_bar.max_value = _player.max_mana
	mana_bar.value = _player.mana
	mana_label.text = "%d / %d" % [int(_player.mana), _player.max_mana]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and close_top_window():
		get_viewport().set_input_as_handled()


## Schließt das oberste offene Fenster (z. B. Inventar). Gibt false zurück, wenn keins offen war.
func close_top_window() -> bool:
	if inventory_panel.cancel_orb():
		return true
	for window in _windows.values():
		if window.visible:
			window.hide()
			return true
	if inventory_panel.visible:
		inventory_panel.hide()
		return true
	return false


## Verbindet die Anzeige mit dem Spieler.
func track_player(player: Node) -> void:
	_player = player
	player.health.changed.connect(_on_player_health_changed)
	player.experience.changed.connect(_on_player_xp_changed)
	player.died.connect(_show_game_over)
	player.revived.connect(message_panel.hide)
	inventory_panel.track_player(player)
	player.inventory.changed.connect(_update_gold)
	_update_gold()
	_on_player_health_changed(player.health.current, player.health.max_health)
	var xp: Experience = player.experience
	_on_player_xp_changed(xp.level, xp.xp, xp.xp_for_next_level())


## Öffnet das Fenster `window_name` (z. B. "smith") für die Figur `source`. Andere Figuren-Fenster schließen sich.
func open_window(window_name: String, player: Node, source: Node3D) -> void:
	for other in _windows:
		if other != window_name:
			_windows[other].hide()
	if _windows.has(window_name):
		_windows[window_name].open(player, source)


func _update_gold() -> void:
	_gold_label.text = "Gold: %d" % _player.inventory.gold


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
	_show_message("Du bist gestorben!", "Wiederbeleben", _player.revive,
		"In der Stadt neu starten", _player.restart_in_town)


## Zeigt das Meldungsfenster in der Mitte. Der zweite Knopf ist optional.
func _show_message(text: String, button_text: String, action: Callable,
		second_text: String = "", second_action: Callable = Callable()) -> void:
	message_label.text = text
	message_button.text = button_text
	_message_action = action
	second_button.text = second_text
	second_button.visible = second_text != ""
	_second_action = second_action
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


func _on_second_button_pressed() -> void:
	message_panel.hide()
	if _second_action.is_valid():
		_second_action.call()
