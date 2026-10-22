extends PanelContainer
## Inventar-Fenster: links die angezogene Ausrüstung und die Werte des Spielers,
## rechts die Tasche. Öffnen/Schließen mit Taste I.
## Linksklick in der Tasche = anziehen, Linksklick auf Ausrüstung = ausziehen,
## Rechtsklick in der Tasche = auf den Boden werfen.

@onready var equipment_grid: GridContainer = %EquipmentGrid
@onready var bag_grid: GridContainer = %BagGrid
@onready var stats_label: Label = %StatsLabel

var _player: Node = null
var _equipment_slots: Dictionary = {}
var _bag_slots: Array[ItemSlot] = []


func _ready() -> void:
	hide()
	for slot in ItemData.Slot.values():
		var button := ItemSlot.new()
		button.empty_text = ItemData.SLOT_NAMES[slot]
		button.pressed.connect(_on_equipment_pressed.bind(slot))
		equipment_grid.add_child(button)
		_equipment_slots[slot] = button


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	visible = not visible
	if visible:
		refresh()


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
	for slot in _equipment_slots:
		_equipment_slots[slot].set_item(inventory.equipped.get(slot))
	for i in _bag_slots.size():
		_bag_slots[i].set_item(inventory.bag[i])
	stats_label.text = "Stufe %d\nLeben: %d\nSchaden: %d–%d\nRüstung: %d\nLeben/Sek.: %.1f\nTempo: %.1f m/s" % [
		_player.experience.level,
		_player.health.max_health,
		_player.damage_min + _player.bonus_damage,
		_player.damage_max + _player.bonus_damage,
		_player.armor,
		_player.health.regen_per_second,
		_player.move_speed,
	]


func _on_bag_pressed(index: int) -> void:
	_player.inventory.equip_from_bag(index)


func _on_bag_right_clicked(index: int) -> void:
	_player.drop_item_from_bag(index)


func _on_equipment_pressed(slot: ItemData.Slot) -> void:
	_player.inventory.unequip(slot)
