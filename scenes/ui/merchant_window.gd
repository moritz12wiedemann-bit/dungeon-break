extends GameWindow
## Händler: verkauft 3 Gegenstände (neue Ware nach jedem geschafften Dungeon)
## und kauft Gegenstände aus der Tasche. Bessere Gegenstände sind teurer.

## Wie oft welche Seltenheit im Angebot ist: Normal, Magisch, Selten, Legendär, Set.
const STOCK_WEIGHTS := [10.0, 45.0, 35.0, 5.0, 5.0]
const STOCK_SIZE := 3

var _offer_box: HBoxContainer
var _grid: GridContainer
var _gold_label: Label


func _init() -> void:
	super("Händler")


func _build() -> void:
	_gold_label = make_label("", 18, Color(1.0, 0.85, 0.3))
	content.add_child(_gold_label)
	content.add_child(make_label("Angebot (klicken zum Kaufen) – neue Ware nach jedem geschafften Dungeon:"))
	_offer_box = HBoxContainer.new()
	_offer_box.add_theme_constant_override("separation", 8)
	for i in STOCK_SIZE:
		var slot := ItemSlot.new()
		slot.custom_minimum_size = Vector2(72, 72)
		slot.pressed.connect(_buy.bind(i))
		_offer_box.add_child(slot)
	content.add_child(_offer_box)
	content.add_child(make_label("Verkaufen: klicke auf einen Gegenstand in deiner Tasche."))
	_grid = make_bag_grid(30, _sell)
	content.add_child(_grid)


func refresh() -> void:
	if GameState.shop_items.is_empty():
		_restock()
	_gold_label.text = "Dein Gold: %d" % player.inventory.gold
	for i in STOCK_SIZE:
		var slot: ItemSlot = _offer_box.get_child(i)
		var item: ItemData = GameState.shop_items[i] if i < GameState.shop_items.size() else null
		slot.caption = "%d Gold" % Loot.buy_price(item) if item else ""
		slot.set_item(item)
	fill_bag_grid(_grid, func(item: ItemData): return "%d G" % Loot.sell_price(item))


## Neue Ware passend zur Stufe des Spielers.
func _restock() -> void:
	GameState.shop_items.clear()
	for i in STOCK_SIZE:
		GameState.shop_items.append(ItemGenerator.create_item(_roll_rarity(), player.experience.level))


func _roll_rarity() -> ItemData.Rarity:
	var total := 0.0
	for w in STOCK_WEIGHTS:
		total += w
	var roll := randf() * total
	for i in STOCK_WEIGHTS.size():
		roll -= STOCK_WEIGHTS[i]
		if roll <= 0.0:
			return i as ItemData.Rarity
	return ItemData.Rarity.MAGIC


func _buy(index: int) -> void:
	if index >= GameState.shop_items.size() or GameState.shop_items[index] == null:
		return
	var item: ItemData = GameState.shop_items[index]
	var price := Loot.buy_price(item)
	if player.inventory.is_full():
		show_status("Deine Tasche ist voll.", true)
		return
	if not player.inventory.spend_gold(price):
		show_status("Nicht genug Gold (%d nötig)." % price, true)
		return
	# Gekaufter Platz bleibt leer, bis neue Ware kommt.
	GameState.shop_items[index] = null
	player.inventory.add_item(item)
	show_status("%s für %d Gold gekauft." % [item.item_name, price])


func _sell(index: int) -> void:
	var item: ItemData = player.inventory.bag[index]
	if item == null:
		return
	var price := Loot.sell_price(item)
	player.inventory.remove_item(index)
	player.inventory.add_gold(price)
	show_status("%s für %d Gold verkauft." % [item.item_name, price])
