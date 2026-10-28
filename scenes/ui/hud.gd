extends CanvasLayer
## Bildschirm-Anzeige: Lebensbalken, Erfahrungsbalken mit Stufe, Skill-Leiste darüber,
## Heiltrank-Knopf, Manabalken, Inventar-Fenster, Ort und übrige Gegner, kurze Meldungen und
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
## Ist das gesetzt, ruft der Tod des Spielers das hier auf statt das normale "Gestorben"-Fenster
## (der Endlos-Modus zeigt dort seine Belohnung).
var death_handler: Callable
## Karte oben rechts (nur im Dungeon sichtbar, siehe setup_minimap).
var minimap := Minimap.new()
## Fähigkeiten über dem Erfahrungsbalken (Q, W, E, R, Linksklick, Rechtsklick).
var skill_bar := SkillBar.new()
## Aktive Buffs (z. B. Stacks von 1000 Schläge) über der Skill-Leiste.
var buff_bar := BuffBar.new()


func _ready() -> void:
	add_to_group("hud")
	_windows = {
		"smith": preload("res://scenes/ui/smith_window.gd").new(),
		"merchant": preload("res://scenes/ui/merchant_window.gd").new(),
		"altar": preload("res://scenes/ui/altar_window.gd").new(false),
		"endless": preload("res://scenes/ui/altar_window.gd").new(true),
		"mystic": preload("res://scenes/ui/mystic_window.gd").new(),
		"elder": preload("res://scenes/ui/elder_window.gd").new(),
	}
	add_child(minimap)
	# Ganz nach hinten, damit Inventar und Fenster darüber liegen.
	move_child(minimap, 0)
	add_child(skill_bar)
	move_child(skill_bar, 1)
	add_child(buff_bar)
	move_child(buff_bar, 2)
	_add_level_up_button()
	for window in _windows.values():
		add_child(window)
	# Fenster unter dem Meldungsfenster ("Gestorben") halten.
	move_child(message_panel, -1)
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
	elif event.is_action_pressed("big_map"):
		minimap.toggle_big()
		get_viewport().set_input_as_handled()


## Mana-Leiste in Farbe und Namen der Klassen-Ressource (beim Krieger: dunkelroter Zorn).
func _apply_class_resource() -> void:
	var fill: StyleBoxFlat = mana_bar.get_theme_stylebox("fill").duplicate()
	fill.bg_color = PlayerClasses.resource_color(GameState.player_class)
	mana_bar.add_theme_stylebox_override("fill", fill)
	mana_bar.tooltip_text = "%s (für Fähigkeiten)" % PlayerClasses.resource_name(GameState.player_class)


## Nur zum Testen: Knopf über "Inventar", der sofort eine Stufe aufsteigen lässt.
func _add_level_up_button() -> void:
	var button := Button.new()
	button.text = "Test: Stufe +1"
	button.tooltip_text = "Nur zum Testen: sofort eine Stufe aufsteigen"
	button.focus_mode = Control.FOCUS_NONE
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	button.offset_left = -136
	button.offset_right = -16
	button.offset_top = -112
	button.offset_bottom = -82
	button.pressed.connect(func():
		var xp: Experience = _player.experience
		if not xp.is_max_level():
			xp.add_xp(xp.xp_for_next_level() - xp.xp))
	add_child(button)


## Schließt das oberste offene Fenster (z. B. Inventar). Gibt false zurück, wenn keins offen war.
func close_top_window() -> bool:
	if skill_bar.close_picker():
		return true
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
	skill_bar.track_player(player)
	buff_bar.track_player(player)
	_apply_class_resource()
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


## Zeigt oben rechts die Karte des Dungeons. `boss` darf null sein.
func setup_minimap(generator: DungeonGenerator, cell_size: float, player: Node3D, boss: Node3D) -> void:
	minimap.setup(generator, cell_size, player, boss)


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
	if death_handler.is_valid():
		death_handler.call()
		return
	show_message("Du bist gestorben!", "Wiederbeleben", _player.revive,
		"In der Stadt neu starten", _player.restart_in_town)


## Zeigt das Meldungsfenster in der Mitte. Der zweite Knopf ist optional.
func show_message(text: String, button_text: String, action: Callable,
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
