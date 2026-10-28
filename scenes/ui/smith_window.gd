extends GameWindow
## Schmied: zerlegt Gegenstände aus der Tasche in Altmetall (und mit Glück einen Orb).
## Angezogene Ausrüstung wird nie zerlegt.

var _grid: GridContainer
var _scrap_label: Label


func _init() -> void:
	super("Schmied")


func _build() -> void:
	content.add_child(make_label("Klicke auf einen Gegenstand in deiner Tasche, um ihn zu zerlegen.\nGute Gegenstände geben mehr Altmetall und manchmal einen Orb."))
	_grid = make_bag_grid(30, _salvage_one)
	content.add_child(_grid)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	buttons.add_child(make_button("Alle Normalen", _salvage_all.bind(ItemData.Rarity.NORMAL)))
	buttons.add_child(make_button("Alle Magischen", _salvage_all.bind(ItemData.Rarity.MAGIC)))
	buttons.add_child(make_button("Alle Seltenen", _salvage_all.bind(ItemData.Rarity.RARE)))
	content.add_child(buttons)
	_scrap_label = make_label("", 14, Color(0.75, 0.8, 0.85))
	content.add_child(_scrap_label)


func refresh() -> void:
	fill_bag_grid(_grid)
	_scrap_label.text = "Altmetall: %d" % player.inventory.get_material_count(GameMaterials.SCRAP)


func _salvage_one(index: int) -> void:
	var item: ItemData = player.inventory.bag[index]
	if item == null:
		return
	var gained := _salvage(index)
	show_status("%s zerlegt: %s" % [item.item_name, _describe(gained)])


func _salvage_all(rarity: ItemData.Rarity) -> void:
	var total := {}
	var count := 0
	for i in player.inventory.bag.size():
		var item: ItemData = player.inventory.bag[i]
		if item and item.rarity == rarity:
			var gained := _salvage(i)
			for id in gained:
				total[id] = total.get(id, 0) + gained[id]
			count += 1
	if count == 0:
		show_status("Keine Gegenstände dieser Seltenheit in der Tasche.", true)
	else:
		show_status("%d Gegenstände zerlegt: %s" % [count, _describe(total)])


func _salvage(index: int) -> Dictionary:
	var item: ItemData = player.inventory.remove_item(index)
	var gained := Loot.salvage(item)
	for id in gained:
		player.inventory.add_material(id, gained[id])
	return gained


func _describe(gained: Dictionary) -> String:
	var parts: Array[String] = []
	for id in gained:
		parts.append("%d× %s" % [gained[id], GameMaterials.display_name(id)])
	return ", ".join(parts)
