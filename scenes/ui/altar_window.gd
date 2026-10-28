extends GameWindow
## Fenster am Altar: Monsterstufe 1–100 wählen und den Dungeon (oder den Endlos-Modus) betreten.
## Höhere Stufe = stärkere Monster, mehr Erfahrung und bessere Beute.

## true = Endlos-Altar, false = Dungeon-Altar.
var endless: bool

var _slider := HSlider.new()
var _level_label: Label
var _info_label: Label


func _init(is_endless: bool) -> void:
	endless = is_endless
	super("Endlos-Altar" if endless else "Dungeon-Altar")


func _build() -> void:
	var text := "Monster kommen ohne Ende von allen Seiten auf dich zu.\nAlle paar Kills werden sie eine Stufe stärker, bis du fällst.\nDie Belohnung bekommst du erst nach dem Tod." if endless \
		else "Ein neuer, zufälliger Dungeon. Besiege den Boss, um zurückzukehren."
	content.add_child(make_label(text))
	_level_label = make_label("", 20, Color(1.0, 0.85, 0.5))
	content.add_child(_level_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.add_child(make_button("-10", _change.bind(-10)))
	row.add_child(make_button("-1", _change.bind(-1)))
	_slider.min_value = 1
	_slider.max_value = GameState.MAX_MONSTER_LEVEL
	_slider.step = 1
	_slider.custom_minimum_size = Vector2(220, 24)
	_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_slider.focus_mode = Control.FOCUS_NONE
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.25, 0.2, 0.15)
	track.set_corner_radius_all(3)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	_slider.add_theme_stylebox_override("slider", track)
	var filled := track.duplicate()
	filled.bg_color = Color(0.85, 0.6, 0.25)
	_slider.add_theme_stylebox_override("grabber_area", filled)
	_slider.add_theme_stylebox_override("grabber_area_highlight", filled)
	_slider.value_changed.connect(func(_v): _update_labels())
	row.add_child(_slider)
	row.add_child(make_button("+1", _change.bind(1)))
	row.add_child(make_button("+10", _change.bind(10)))
	content.add_child(row)
	_info_label = make_label("", 13, Color(0.7, 0.68, 0.62))
	content.add_child(_info_label)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	buttons.add_child(make_button("Eigene Stufe", func(): _slider.value = player.experience.level))
	var start := make_button("Endlos-Lauf starten" if endless else "Dungeon betreten", _enter)
	start.add_theme_font_size_override("font_size", 18)
	buttons.add_child(start)
	content.add_child(buttons)


func open(for_player: Node, from: Node3D) -> void:
	super(for_player, from)
	# Vorschlag: zuletzt gewählte Stufe, beim ersten Mal die eigene.
	_slider.value = GameState.chosen_level if GameState.chosen_level > 0 else player.experience.level
	_update_labels()


func refresh() -> void:
	_update_labels()


func _change(amount: int) -> void:
	_slider.value += amount


func _update_labels() -> void:
	if player == null:
		return
	var level := int(_slider.value)
	_level_label.text = "Monsterstufe: %d" % level
	var difference := level - int(player.experience.level)
	var hint := "so stark wie du"
	if difference > 0:
		hint = "%d Stufen über dir – gefährlich, aber mehr XP und bessere Beute" % difference
	elif difference < 0:
		hint = "%d Stufen unter dir – leicht, aber weniger XP" % -difference
	_info_label.text = "%s\nXP pro Gegner: ×%d" % [hint, level]


func _enter() -> void:
	hide()
	if endless:
		GameState.enter_endless(player, int(_slider.value))
	else:
		GameState.enter_new_dungeon(player, int(_slider.value))
