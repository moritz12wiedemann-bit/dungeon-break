extends PanelContainer
## Inventar-Fenster: links die angezogene Ausrüstung und die Werte des Spielers,
## rechts die Tasche, darunter der aufklappbare Reiter "Materialien" (Orbs usw.).
## Öffnen/Schließen mit Taste I oder Escape.
## Linksklick in der Tasche = anziehen, Linksklick auf Ausrüstung = ausziehen,
## Rechtsklick in der Tasche = auf den Boden werfen.
## Orbs: im Reiter rechtsklicken (Orb hängt dann am Mauszeiger), danach einen Gegenstand
## in Tasche oder Ausrüstung anklicken. Rechtsklick oder Escape bricht ab.

@onready var equipment_grid: GridContainer = %EquipmentGrid
@onready var bag_grid: GridContainer = %BagGrid
@onready var stats_label: Label = %StatsLabel
@onready var materials_toggle: Button = %MaterialsToggle
@onready var materials_box: HFlowContainer = %MaterialsBox
@onready var status_label: Label = %StatusLabel

var _player: Node = null
var _equipment_slots: Dictionary = {}
var _bag_slots: Array[ItemSlot] = []
## Material-Name → Kästchen im Reiter.
var _material_slots: Dictionary = {}
## Der ausgewählte Orb ("" = keiner).
var _selected_orb: String = ""
## Bild des ausgewählten Orbs, das dem Mauszeiger folgt.
var _cursor := TextureRect.new()


func _ready() -> void:
	hide()
	for slot in ItemData.Slot.values():
		var button := ItemSlot.new()
		button.empty_icon = ItemData.SLOT_ICONS[slot]
		button.pressed.connect(_on_equipment_pressed.bind(slot))
		button.right_clicked.connect(cancel_orb)
		equipment_grid.add_child(button)
		_equipment_slots[slot] = button
	for id in GameMaterials.INFO:
		var slot := MaterialSlot.new(id)
		slot.selected.connect(_select_orb.bind(id))
		materials_box.add_child(slot)
		_material_slots[id] = slot
	materials_toggle.pressed.connect(_toggle_materials)
	visibility_changed.connect(func(): if not visible: cancel_orb())
	_cursor.top_level = true
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cursor.size = Vector2(36, 36)
	_cursor.z_index = 10
	_cursor.hide()
	add_child(_cursor)


func _process(_delta: float) -> void:
	if _cursor.visible:
		_cursor.global_position = get_global_mouse_position() + Vector2(6, 6)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle()
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	# Rechtsklick irgendwo ins Fenster bricht die Orb-Auswahl ab.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		cancel_orb()


func toggle() -> void:
	visible = not visible
	if visible:
		status_label.text = ""
		refresh()


## Hebt die Orb-Auswahl auf. Gibt true zurück, wenn ein Orb ausgewählt war.
func cancel_orb() -> bool:
	if _selected_orb == "":
		return false
	_selected_orb = ""
	_cursor.hide()
	status_label.text = ""
	refresh()
	return true


## Verbindet das Fenster mit dem Inventar des Spielers.
func track_player(player: Node) -> void:
	_player = player
	var inventory: Inventory = player.inventory
	for i in inventory.bag_size:
		var button := ItemSlot.new()
		button.pressed.connect(_on_bag_pressed.bind(i))
		button.right_clicked.connect(_on_bag_right_clicked.bind(i))
		bag_grid.add_child(button)
		_bag_slots.append(button)
	inventory.changed.connect(refresh)
	player.health.changed.connect(func(_c, _m): refresh())
	refresh()


func refresh() -> void:
	if _player == null or not visible:
		return
	var inventory: Inventory = _player.inventory
	var orb_active := _selected_orb != ""
	for slot in _equipment_slots:
		_equipment_slots[slot].set_item(inventory.equipped.get(slot), orb_active)
	for i in _bag_slots.size():
		_bag_slots[i].set_item(inventory.bag[i], orb_active)
	for id in _material_slots:
		_material_slots[id].set_count(inventory.get_material_count(id), id == _selected_orb)
	stats_label.text = "Stufe %d\nLeben: %d\nSchaden: %d–%d\nRüstung: %d\nLeben/Sek.: %.1f\nAngriffe/Sek.: %.2f\nTempo: %.1f m/s" % [
		_player.experience.level,
		_player.health.max_health,
		_player.damage_min + _player.bonus_damage,
		_player.damage_max + _player.bonus_damage,
		_player.armor,
		_player.health.regen_per_second,
		1.0 / _player.attack_cooldown,
		_player.move_speed,
	]


func _toggle_materials() -> void:
	materials_box.visible = not materials_box.visible
	materials_toggle.text = ("▾ " if materials_box.visible else "▸ ") + "Materialien"
	if not materials_box.visible:
		cancel_orb()
	reset_size()


func _select_orb(id: String) -> void:
	if not GameMaterials.INFO[id].usable:
		return
	if _selected_orb == id:
		cancel_orb()
		return
	if _player.inventory.get_material_count(id) <= 0:
		_show_status("Du hast keinen %s." % GameMaterials.display_name(id), true)
		return
	_selected_orb = id
	_cursor.texture = GameMaterials.INFO[id].icon
	_cursor.show()
	_show_status("%s: Klicke auf einen Gegenstand (Rechtsklick oder Esc: abbrechen)" % GameMaterials.display_name(id))
	refresh()


## Wendet den ausgewählten Orb an. Gibt false zurück, wenn kein Orb ausgewählt war.
func _try_apply_orb(item: ItemData) -> bool:
	if _selected_orb == "":
		return false
	if item == null:
		return true
	var id := _selected_orb
	var old_name := item.item_name
	var error: String = _player.inventory.use_orb(id, item)
	_selected_orb = ""
	_cursor.hide()
	if error != "":
		_show_status(error, true)
	else:
		_show_status("%s benutzt: %s → %s" % [GameMaterials.display_name(id), old_name, item.item_name])
	refresh()
	return true


func _show_status(text: String, is_error: bool = false) -> void:
	status_label.text = text
	status_label.add_theme_color_override("font_color", Color(1, 0.45, 0.4) if is_error else Color(0.85, 0.7, 1))


func _on_bag_pressed(index: int) -> void:
	if _try_apply_orb(_player.inventory.bag[index]):
		return
	_player.inventory.equip_from_bag(index)


func _on_bag_right_clicked(index: int) -> void:
	if cancel_orb():
		return
	_player.drop_item_from_bag(index)


func _on_equipment_pressed(slot: ItemData.Slot) -> void:
	if _try_apply_orb(_player.inventory.equipped.get(slot)):
		return
	_player.inventory.unequip(slot)
