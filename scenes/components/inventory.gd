class_name Inventory
extends Node
## Inventar des Spielers: eine Tasche mit festen Plätzen und die angezogene Ausrüstung.
## Wer die Werte der Ausrüstung braucht (z. B. der Spieler für Schaden und Leben),
## fragt get_stat_total() und hört auf das Signal `changed`.

## Wird ausgelöst, wenn sich in Tasche oder Ausrüstung etwas ändert.
signal changed

## Wie viele Plätze die Tasche hat.
@export var bag_size: int = 30

## Tasche: jeder Platz ist ein ItemData oder null (leer).
var bag: Array[ItemData] = []
## Angezogene Ausrüstung: ItemData.Slot → ItemData.
var equipped: Dictionary = {}
## Materialien und Orbs: Name (siehe GameMaterials) → Anzahl. Liegen nicht in der Tasche.
var materials: Dictionary = GameMaterials.STARTING.duplicate()


func _ready() -> void:
	bag.resize(bag_size)


func get_material_count(id: String) -> int:
	return materials.get(id, 0)


func add_material(id: String, amount: int = 1) -> void:
	materials[id] = get_material_count(id) + amount
	changed.emit()


## Wendet den Orb `id` auf `item` an (in der Tasche oder angezogen) und verbraucht ihn.
## Gibt eine Fehlermeldung zurück oder "" bei Erfolg.
func use_orb(id: String, item: ItemData) -> String:
	if get_material_count(id) <= 0:
		return "Du hast keinen %s mehr." % GameMaterials.display_name(id)
	var error := GameMaterials.apply_orb(id, item)
	if error == "":
		materials[id] -= 1
		changed.emit()
	return error


func is_full() -> bool:
	return bag.find(null) == -1


## Legt einen Gegenstand in den ersten freien Platz. Gibt false zurück, wenn die Tasche voll ist.
func add_item(item: ItemData) -> bool:
	var index := bag.find(null)
	if index == -1:
		return false
	bag[index] = item
	changed.emit()
	return true


## Nimmt den Gegenstand aus Platz `index` heraus und gibt ihn zurück.
func remove_item(index: int) -> ItemData:
	var item := bag[index]
	bag[index] = null
	changed.emit()
	return item


## Zieht den Gegenstand aus Platz `index` an. Was vorher dort angezogen war, kommt in die Tasche.
func equip_from_bag(index: int) -> void:
	var item := bag[index]
	if item == null:
		return
	bag[index] = equipped.get(item.slot)
	equipped[item.slot] = item
	changed.emit()


## Zieht den Gegenstand im Ausrüstungsplatz `slot` aus und legt ihn in die Tasche.
func unequip(slot: ItemData.Slot) -> bool:
	if not equipped.has(slot) or is_full():
		return false
	bag[bag.find(null)] = equipped[slot]
	equipped.erase(slot)
	changed.emit()
	return true


## Summe eines Werts (z. B. "armor") über alle angezogenen Gegenstände.
func get_stat_total(stat: String) -> float:
	var total := 0.0
	for item: ItemData in equipped.values():
		total += item.get_stat(stat)
	return total
