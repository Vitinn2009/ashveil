class_name Inventory
extends RefCounted

## Ouro, poções, mochila e equipamentos do herói.

signal changed

const BAG_SIZE := 12
const POTION_HEAL := 0.4

var gold := 0
var potions := 1
var bag: Array = []
var equipped := {}


func add_gold(amount: int) -> void:
	gold += amount
	changed.emit()


func add_potion() -> void:
	potions += 1
	changed.emit()


## Devolve false se a mochila estava cheia (o item é vendido na hora).
func add_item(item: Item) -> bool:
	if bag.size() >= BAG_SIZE:
		gold += item.sell_value()
		changed.emit()
		return false
	bag.append(item)
	changed.emit()
	return true


func equip(item: Item) -> void:
	var index := bag.find(item)
	if index < 0:
		return
	bag.remove_at(index)
	var previous = equipped.get(item.slot)
	if previous:
		bag.append(previous)
	equipped[item.slot] = item
	changed.emit()


func unequip(slot: String) -> void:
	if not equipped.has(slot) or bag.size() >= BAG_SIZE:
		return
	bag.append(equipped[slot])
	equipped.erase(slot)
	changed.emit()


func sell(item: Item) -> void:
	if bag.find(item) < 0:
		return
	bag.erase(item)
	gold += item.sell_value()
	changed.emit()


func bonus(stat: String) -> int:
	var total := 0
	for item in equipped.values():
		total += int(item.stats.get(stat, 0))
	return total


func use_potion(player: Player) -> bool:
	if potions <= 0 or player.health >= player.max_health:
		return false
	potions -= 1
	player.heal(player.max_health * POTION_HEAL)
	changed.emit()
	return true
