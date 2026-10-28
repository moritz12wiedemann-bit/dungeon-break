extends GameWindow
## Mystikerin: Augment-Karten für Gold kaufen, mit Arcana ausrüsten und Arcana erhöhen.
## Die Karten sind vorerst Platzhalter mit einfachen Werten (siehe AugmentCards).

var _arcana_label: Label
var _gold_label: Label
var _upgrade_button: Button
var _card_rows: VBoxContainer


func _init() -> void:
	super("Mystikerin")


func _build() -> void:
	content.add_child(make_label("Augment-Karten geben dir dauerhafte Effekte. Jede ausgerüstete Karte kostet Arcana.\n(Platzhalter-Karten – die echten Karten kommen später.)"))
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	_arcana_label = make_label("", 18, Color(0.75, 0.55, 1.0))
	top.add_child(_arcana_label)
	_gold_label = make_label("", 18, Color(1.0, 0.85, 0.3))
	top.add_child(_gold_label)
	content.add_child(top)
	_card_rows = VBoxContainer.new()
	_card_rows.add_theme_constant_override("separation", 4)
	content.add_child(_card_rows)
	_upgrade_button = make_button("", _upgrade_arcana)
	content.add_child(_upgrade_button)


func refresh() -> void:
	var used := GameState.used_arcana()
	_arcana_label.text = "Arcana: %d / %d" % [used, GameState.max_arcana]
	_gold_label.text = "Gold: %d" % player.inventory.gold
	if GameState.max_arcana >= AugmentCards.MAX_ARCANA:
		_upgrade_button.text = "Arcana ist am Maximum (%d)" % AugmentCards.MAX_ARCANA
		_upgrade_button.disabled = true
	else:
		_upgrade_button.text = "Arcana erhöhen auf %d (%d Gold)" % [GameState.max_arcana + 1, AugmentCards.arcana_upgrade_price(GameState.max_arcana)]
		_upgrade_button.disabled = false
	for child in _card_rows.get_children():
		child.queue_free()
	for id in AugmentCards.CARDS:
		_card_rows.add_child(_make_row(id))


func _make_row(id: String) -> Control:
	var card: Dictionary = AugmentCards.CARDS[id]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var cost := make_label("◆".repeat(card.arcana), 16, Color(0.75, 0.55, 1.0))
	cost.custom_minimum_size.x = 44
	cost.tooltip_text = "Kostet %d Arcana" % card.arcana
	cost.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(cost)
	var equipped: bool = id in GameState.equipped_cards
	var text := make_label("%s: %s" % [card.name, AugmentCards.describe(id)], 14,
		Color(0.85, 1.0, 0.85) if equipped else Color(0.85, 0.82, 0.75))
	text.custom_minimum_size.x = 340
	row.add_child(text)
	var button: Button
	if not id in GameState.owned_cards:
		button = make_button("Kaufen (%d Gold)" % card.price, _buy.bind(id))
	elif equipped:
		button = make_button("Ablegen", _unequip.bind(id))
	else:
		button = make_button("Ausrüsten", _equip.bind(id))
	button.custom_minimum_size.x = 140
	row.add_child(button)
	return row


func _buy(id: String) -> void:
	var card: Dictionary = AugmentCards.CARDS[id]
	if not player.inventory.spend_gold(card.price):
		show_status("Nicht genug Gold (%d nötig)." % card.price, true)
		return
	GameState.owned_cards.append(id)
	show_status("%s gekauft." % card.name)
	_changed()


func _equip(id: String) -> void:
	var card: Dictionary = AugmentCards.CARDS[id]
	if GameState.used_arcana() + card.arcana > GameState.max_arcana:
		show_status("Nicht genug Arcana frei (%d nötig). Lege eine Karte ab oder erhöhe dein Arcana." % card.arcana, true)
		return
	GameState.equipped_cards.append(id)
	show_status("%s ausgerüstet." % card.name)
	_changed()


func _unequip(id: String) -> void:
	GameState.equipped_cards.erase(id)
	show_status("%s abgelegt." % AugmentCards.CARDS[id].name)
	_changed()


func _upgrade_arcana() -> void:
	var price := AugmentCards.arcana_upgrade_price(GameState.max_arcana)
	if not player.inventory.spend_gold(price):
		show_status("Nicht genug Gold (%d nötig)." % price, true)
		return
	GameState.max_arcana += 1
	show_status("Dein Arcana ist jetzt %d." % GameState.max_arcana)
	_changed()


func _changed() -> void:
	GameState.progress_changed.emit()
	refresh()
