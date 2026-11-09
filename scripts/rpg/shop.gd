class_name Shop
extends RefCounted

## Mercado do castelo: poções e comidas sempre à venda, equipamentos sorteados
## a cada missão. Aqui fica só a lógica, sem interface.

const STOCK_SIZE := 6
const MAX_SHOP_RARITY := 2
const CATEGORIES := ["potions", "food", "weapons", "armor", "accessories", "materials", "sell"]
const CATEGORY_NAMES := {
	"potions": "Poções",
	"food": "Comida",
	"weapons": "Armas",
	"armor": "Armaduras",
	"accessories": "Acessórios",
	"materials": "Materiais",
	"sell": "Vender",
}


## Estoque de equipamentos: {"weapons": [{item, price}], "armor": [...], "accessories": [...]}.
## O mesmo seed sempre gera o mesmo estoque, e missões cumpridas melhoram os itens.
static func generate_stock(shop_seed: int, missions_done: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = shop_seed
	var power := 1 + missions_done * 4
	return {
		"weapons": _stock(rng, Item.GROUPS["weapons"], power),
		"armor": _stock(rng, Item.GROUPS["armor"], power),
		"accessories": _stock(rng, Item.GROUPS["accessories"], power),
		"materials": _materials_stock(rng),
	}


static func _stock(rng: RandomNumberGenerator, slots: Array, power: int) -> Array:
	var entries: Array = []
	for i in STOCK_SIZE:
		var slot: String = slots[rng.randi() % slots.size()]
		var item := Item.create(rng, slot, 0, power, MAX_SHOP_RARITY)
		entries.append({"item": item, "price": item.buy_price()})
	return entries


## Compra um equipamento do estoque. Devolve "" se deu certo, ou o motivo da recusa.
static func buy_item(inventory: Inventory, stock: Array, index: int) -> String:
	if index < 0 or index >= stock.size():
		return "Item indisponível"
	var entry: Dictionary = stock[index]
	if inventory.gold < entry["price"]:
		return "Ouro insuficiente"
	if inventory.bag.size() >= inventory.bag_capacity:
		return "Mochila cheia"
	inventory.gold -= entry["price"]
	inventory.bag.append(entry["item"])
	stock.remove_at(index)
	inventory.changed.emit()
	return ""


static func buy_consumable(inventory: Inventory, id: String, count := 1) -> String:
	var price := pack_price(id, count)
	if inventory.gold < price:
		return "Ouro insuficiente"
	inventory.gold -= price
	inventory.add_consumable(id, count)
	return ""


## Preço de `count` unidades: pacotes de 5 ou mais saem com desconto.
static func pack_price(id: String, count := 1) -> int:
	var price: int = Consumables.def(id)["price"] * count
	return int(price * PACK_DISCOUNT) if count >= 5 else price


## Vende todos os equipamentos comuns da mochila. Devolve o ouro recebido.
static func sell_commons(inventory: Inventory) -> int:
	var earned := 0
	var released: Array = []
	for item in inventory.bag.duplicate():
		if item.rarity == 0:
			released.append_array(inventory.release_runes(item).duplicate())
			earned += item.sell_value()
			inventory.bag.erase(item)
	inventory.last_released_runes = released
	inventory.gold += earned
	inventory.changed.emit()
	return earned


## Preços dos materiais (ouro). As pedras são sempre vendidas; o resto muda a cada missão e acaba quando se compra.
const STONE_PRICE := 40
const MOONSTONE_PRICE := 700
const SCROLL_PRICE := 1100
const KEY_PRICE := 1800
const RUNE_PRICE := 260
const FRAGMENT_PACK := 10
const FRAGMENT_PRICE := [8, 22, 60, 160, 420]
const PACK_DISCOUNT := 0.9


## O estoque de materiais: [{kind, payload, amount, price, name, unlimited}].
static func _materials_stock(rng: RandomNumberGenerator) -> Array:
	var entries: Array = []
	entries.append({"kind": "stone", "payload": "", "amount": 1, "price": STONE_PRICE, "name": "Pedra", "unlimited": true})
	entries.append({"kind": "stone", "payload": "", "amount": 5, "price": int(STONE_PRICE * 5 * PACK_DISCOUNT), "name": "Pacote de 5 pedras", "unlimited": true})
	for i in 2:
		entries.append({"kind": "moonstone", "payload": "", "amount": 1, "price": MOONSTONE_PRICE, "name": "Pedra da lua", "unlimited": false})
	entries.append({"kind": "scroll", "payload": "", "amount": 1, "price": SCROLL_PRICE, "name": "Pergaminho de despertar", "unlimited": false})
	entries.append({"kind": "key", "payload": "", "amount": 1, "price": KEY_PRICE, "name": "Chave de espaço", "unlimited": false})

	for i in 5:
		var id: String = Runes.roll(rng, 0, 2)
		entries.append({"kind": "rune", "payload": id, "amount": 1, "price": Runes.price(id), "name": Runes.DATA[id]["name"], "unlimited": false})
	for i in 3:
		var rarity := 0 if rng.randf() < 0.5 else (1 if rng.randf() < 0.65 else 2)
		entries.append({
			"kind": "fragment", "payload": rarity, "amount": FRAGMENT_PACK, "price": int(FRAGMENT_PACK * FRAGMENT_PRICE[rarity]),
			"name": "%d fragmentos %s" % [FRAGMENT_PACK, Item.RARITIES[rarity]["name"].to_lower()], "unlimited": false})
	return entries


## Compra um material do estoque. Devolve "" se deu certo ou o motivo da recusa. O que não é
## ilimitado sai do estoque.
static func buy_material(inventory: Inventory, stock: Array, index: int) -> String:
	if index < 0 or index >= stock.size():
		return "Item indisponível"
	var entry: Dictionary = stock[index]
	if inventory.gold < int(entry["price"]):
		return "Ouro insuficiente"
	if entry["kind"] == "key" and inventory.bag_capacity >= Inventory.MAX_BAG_SIZE:
		return "A mochila já tem o máximo de espaços"
	inventory.gold -= int(entry["price"])
	match entry["kind"]:
		"stone", "moonstone", "scroll", "key":
			inventory.add_material(entry["kind"], int(entry["amount"]))
		"rune":
			inventory.add_rune(str(entry["payload"]), int(entry["amount"]))
		"fragment":
			inventory.add_fragments(int(entry["payload"]), int(entry["amount"]))
	if not entry.get("unlimited", false):
		stock.remove_at(index)
	inventory.changed.emit()
	return ""
