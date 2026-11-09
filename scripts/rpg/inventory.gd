class_name Inventory
extends RefCounted

## Ouro, poções, comidas, mochila e equipamentos. O mesmo inventário vale em
## todas as missões e no castelo (ver Session), e é salvo no disco.

signal changed

const BASE_BAG_SIZE := 18
## Chaves de espaço (soltas pelos chefes) liberam +1 espaço cada, até este total.
const MAX_BAG_SIZE := 50

var gold := 60
var potions := 2
var foods := {"bread": 1}
## Materiais do ferreiro: pedras e pedras da lua forjam a arma; pergaminhos de despertar dão atributos extras.
var stone := 0
var moonstone := 0
var scrolls := 0
var slot_keys := 0
## Fragmentos de raridade (comum, raro, épico, lendário), que sobem o nível de raridade dos itens.
var fragments := [0, 0, 0, 0, 0]
## Runas guardadas (para incrustar nos equipamentos).
var runes := {}
var extra_slots := 0
var hero_bag_bonus := 0
var bag_capacity := BASE_BAG_SIZE
var bag: Array = []
var equipped := {}


func add_gold(amount: int) -> void:
	gold += amount
	changed.emit()


func add_potion() -> void:
	potions += 1
	changed.emit()


## Quantas unidades de um consumível (poção ou comida) existem.
func count(id: String) -> int:
	if id == "potion":
		return potions
	return int(foods.get(id, 0))


func add_consumable(id: String, amount := 1) -> void:
	if id == "potion":
		potions += amount
	else:
		foods[id] = int(foods.get(id, 0)) + amount
	changed.emit()


## Devolve false se a mochila estava cheia (o item é vendido na hora).
func add_item(item: Item) -> bool:
	if bag.size() >= bag_capacity:
		gold += item.sell_value()
		changed.emit()
		return false
	bag.append(item)
	changed.emit()
	return true


## A casa onde o item vai: a sua, e para anéis a primeira casa de anel livre (ou a do anel mais fraco).
func key_for(item: Item) -> String:
	if item.slot != "ring":
		return item.slot
	if not equipped.has("ring"):
		return "ring"
	if not equipped.has("ring2"):
		return "ring2"
	return "ring" if equipped["ring"].power() <= equipped["ring2"].power() else "ring2"


## A casa em que o item vestido está ("" se não está vestido).
func key_of(item: Item) -> String:
	for key in equipped:
		if equipped[key] == item:
			return key
	return ""


func equip(item: Item) -> void:
	equip_to(key_for(item), item)


## Soma fragmentos de uma raridade.
func add_fragments(rarity: int, amount: int) -> void:
	fragments[clampi(rarity, 0, 4)] += amount
	changed.emit()


## Transforma o item da mochila em fragmentos da raridade dele. Devolve quantos.
func convert_to_fragments(item: Item) -> int:
	if bag.find(item) < 0:
		return 0
	var amount := item.fragment_value()
	release_runes(item)
	bag.erase(item)
	add_fragments(item.rarity, amount)
	return amount


## Sobe o nível de raridade do item vestido na casa `key`, gastando fragmentos da raridade dele.
## Devolve "" se deu certo ou o motivo da recusa.
func upgrade_rank(key: String) -> String:
	return upgrade_rank_item(equipped.get(key))


## Sobe o nível de raridade de um item (vestido ou na mochila), gastando fragmentos da raridade dele.
func upgrade_rank_item(item: Item) -> String:
	if item == null:
		return "Escolha um equipamento"
	if item.rank >= Item.MAX_RANK:
		return "Nível de raridade máximo"
	var cost := Item.rank_cost(item.rank)
	if int(fragments[item.rarity]) < cost:
		return "Faltam fragmentos %s" % Item.RARITIES[item.rarity]["name"].to_lower()
	fragments[item.rarity] -= cost
	item.rank += 1
	changed.emit()
	return ""


## Forja um equipamento (vestido ou na mochila) em um nível: +1 no atributo principal dele.
func forge_item(weapon: Item) -> String:
	if weapon == null:
		return "Escolha um equipamento"
	if weapon.forge >= Item.MAX_FORGE:
		return "A forja já está no nível máximo"
	var cost := Item.forge_cost(weapon.forge)
	if stone < cost["stone"]:
		return "Faltam pedras"
	if moonstone < cost["moonstone"]:
		return "Faltam pedras da lua"
	if gold < cost["gold"]:
		return "Ouro insuficiente"
	stone -= cost["stone"]
	moonstone -= cost["moonstone"]
	gold -= cost["gold"]
	weapon.forge += 1
	changed.emit()
	return ""


func add_rune(id: String, amount := 1) -> void:
	if Runes.is_valid(id):
		runes[id] = int(runes.get(id, 0)) + amount
		changed.emit()


## Incrusta uma runa da mochila numa casa livre do item vestido em `key`. Devolve "" ou o motivo da recusa.
func socket_rune(key: String, id: String) -> String:
	var item: Item = equipped.get(key)
	if item == null:
		return "Casa vazia"
	if int(runes.get(id, 0)) <= 0:
		return "Você não tem essa runa"
	if not item.insert_rune(id):
		return "Sem casa de runa livre"
	runes[id] = int(runes[id]) - 1
	changed.emit()
	return ""


## Tira a runa de uma casa do item vestido (a runa se perde).
func remove_rune_from(key: String, index: int) -> void:
	var item: Item = equipped.get(key)
	if item != null:
		item.remove_rune(index)
		changed.emit()


## Veste o item numa casa específica (o item volta à mochila se a casa estava ocupada).
func equip_to(key: String, item: Item) -> void:
	var index := bag.find(item)
	if index < 0 or Item.type_of(key) != item.slot:
		return
	bag.remove_at(index)
	var previous = equipped.get(key)
	if previous:
		bag.append(previous)
	equipped[key] = item
	changed.emit()


## Equipa, em cada casa, o item da mochila de maior poder (se for melhor que o vestido).
## Devolve quantas peças foram trocadas.
func equip_best() -> int:
	var swapped := 0
	for key in Item.EQUIP_KEYS:
		var best: Item = equipped.get(key)
		for item in bag:
			if item.slot == Item.type_of(key) and (best == null or item.power() > best.power()):
				best = item
		if best != null and best != equipped.get(key):
			equip_to(key, best)
			swapped += 1
	return swapped


func unequip(slot: String) -> void:
	if not equipped.has(slot) or bag.size() >= bag_capacity:
		return
	bag.append(equipped[slot])
	equipped.erase(slot)
	changed.emit()


## Move o item da mochila para outra posição (arrastar e soltar). Devolve false se algo estiver fora.
func move_in_bag(from_index: int, to_index: int) -> bool:
	if from_index < 0 or from_index >= bag.size() or to_index < 0 or to_index >= bag_capacity or from_index == to_index:
		return false
	var item = bag[from_index]
	bag.remove_at(from_index)
	bag.insert(mini(to_index, bag.size()), item)
	changed.emit()
	return true


## Joga fora, sem receber ouro.
func trash(item: Item) -> void:
	if bag.find(item) < 0:
		return
	release_runes(item)
	bag.erase(item)
	changed.emit()


## Ordena por raridade (maior primeiro), depois por grupo, pontos e nome.
func sort_bag() -> void:
	bag.sort_custom(func(a: Item, b: Item) -> bool:
		if a.rarity != b.rarity:
			return a.rarity > b.rarity
		if a.slot != b.slot:
			return Item.SLOTS.find(a.slot) < Item.SLOTS.find(b.slot)
		if a.power() != b.power():
			return a.power() > b.power()
		return a.item_name < b.item_name)
	changed.emit()


func sell(item: Item) -> void:
	if bag.find(item) < 0:
		return
	release_runes(item)
	bag.erase(item)
	gold += item.sell_value()
	changed.emit()


## Recalcula o tamanho da mochila: base, bônus do herói e as chaves já usadas (no máximo 50).
func recalc_capacity(hero_bonus: int) -> void:
	hero_bag_bonus = hero_bonus
	bag_capacity = mini(BASE_BAG_SIZE + hero_bonus + extra_slots, MAX_BAG_SIZE)


## Usa uma chave de espaço: +1 espaço na mochila. Devolve "" ou o motivo da recusa.
func use_slot_key() -> String:
	if slot_keys <= 0:
		return "Sem chaves de espaço"
	if bag_capacity >= MAX_BAG_SIZE:
		return "A mochila já tem o máximo de %d espaços" % MAX_BAG_SIZE
	slot_keys -= 1
	extra_slots += 1
	recalc_capacity(hero_bag_bonus)
	changed.emit()
	return ""


## Soma um material ("stone", "moonstone" ou "scroll").
func add_material(kind: String, amount := 1) -> void:
	match kind:
		"stone":
			stone += amount
		"moonstone":
			moonstone += amount
		"key":
			slot_keys += amount
		"scroll":
			scrolls += amount
	changed.emit()


## Forja a arma vestida em um nível. Devolve "" se deu certo, ou o motivo da recusa.
func forge_weapon() -> String:
	return forge_item(equipped.get("weapon"))


## Desperta a arma vestida com um pergaminho: sorteia um atributo extra. Devolve "" ou o motivo da recusa.
## `last_awakening` guarda o resultado do último pergaminho (result, stat, amount); `force` fixa o
## resultado (testes).
var last_awakening := {}


func awaken_weapon(rng: RandomNumberGenerator = null, force := "") -> String:
	return awaken_item("weapon", rng, force)


## Desperta a arma ou a armadura vestida (`key`) com um pergaminho.
func awaken_item(key: String, rng: RandomNumberGenerator = null, force := "") -> String:
	return awaken_target(equipped.get(key), rng, force)


## Desperta uma arma ou armadura (vestida ou na mochila) com um pergaminho.
func awaken_target(target: Item, rng: RandomNumberGenerator = null, force := "") -> String:
	if target == null or not Item.AWAKEN_SLOTS.has(target.slot):
		return "Vista uma arma ou armadura para despertar"
	if target.awakenings >= Item.MAX_AWAKEN:
		return "Esta peça já despertou %d vezes" % Item.MAX_AWAKEN
	if scrolls <= 0:
		return "Sem pergaminhos de despertar"
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var gain := target.roll_awakening(rng, force)
	scrolls -= 1
	last_awakening = gain
	if gain["result"] != "fail":
		target.awakenings += 1
		target.awake_stats[gain["stat"]] = int(target.awake_stats.get(gain["stat"], 0)) + int(gain["amount"])
	changed.emit()
	return ""


func bonus(stat: String) -> int:
	var total := 0
	for item in equipped.values():
		total += item.stat_total(stat)
	return total


func use_potion(player: Player) -> bool:
	return use_consumable("potion", player)


func use_food(id: String, player: Player) -> bool:
	return use_consumable(id, player)


## Usa uma poção ou comida. Não gasta se não teria efeito (vida cheia, bônus ativo).
func use_consumable(id: String, player: Player) -> bool:
	if count(id) <= 0:
		return false
	var data := Consumables.def(id)
	if data.has("heal"):
		if player.health >= player.max_health:
			return false
		player.heal(player.max_health * data["heal"])
	elif data.has("buff_time"):
		if player.attack_buff_time > 0.0:
			return false
		player.attack_buff_time = data["buff_time"]
	if id == "potion":
		potions -= 1
	else:
		foods[id] = count(id) - 1
		if foods[id] <= 0:
			foods.erase(id)
	changed.emit()
	return true


func to_dict() -> Dictionary:
	var saved_bag: Array = []
	for item in bag:
		saved_bag.append(item.to_dict())
	var saved_equipped := {}
	for slot in equipped:
		saved_equipped[slot] = equipped[slot].to_dict()
	return {
		"gold": gold,
		"potions": potions,
		"stone": stone,
		"moonstone": moonstone,
		"scrolls": scrolls,
		"slot_keys": slot_keys,
		"fragments": fragments.duplicate(),
		"runes": runes.duplicate(),
		"extra_slots": extra_slots,
		"foods": foods.duplicate(),
		"bag": saved_bag,
		"equipped": saved_equipped,
	}


## Reconstrói o inventário salvo, descartando o que estiver inválido.
static func from_dict(data: Dictionary) -> Inventory:
	var inventory := Inventory.new()
	inventory.gold = maxi(0, int(data.get("gold", inventory.gold)))
	inventory.potions = maxi(0, int(data.get("potions", inventory.potions)))
	inventory.stone = maxi(0, int(data.get("stone", 0)))
	inventory.moonstone = maxi(0, int(data.get("moonstone", 0)))
	inventory.scrolls = maxi(0, int(data.get("scrolls", 0)))
	inventory.slot_keys = maxi(0, int(data.get("slot_keys", 0)))
	var saved_fragments = data.get("fragments", [])
	if saved_fragments is Array:
		for i in mini(saved_fragments.size(), 5):
			inventory.fragments[i] = maxi(0, int(saved_fragments[i]))
	var saved_runes = data.get("runes", {})
	if saved_runes is Dictionary:
		for id in saved_runes:
			var migrated := Runes.migrate(str(id))
			if migrated != "":
				inventory.runes[migrated] = int(inventory.runes.get(migrated, 0)) + maxi(0, int(saved_runes[id]))
	inventory.extra_slots = clampi(int(data.get("extra_slots", 0)), 0, MAX_BAG_SIZE - BASE_BAG_SIZE)
	inventory.foods = {}
	var saved_foods = data.get("foods", {})
	if saved_foods is Dictionary:
		for id in saved_foods:
			if Consumables.DATA.has(id) and id != "potion" and int(saved_foods[id]) > 0:
				inventory.foods[id] = int(saved_foods[id])
	var saved_bag = data.get("bag", [])
	if saved_bag is Array:
		for entry in saved_bag:
			if entry is Dictionary:
				inventory.bag.append(Item.from_dict(entry))
	var saved_equipped = data.get("equipped", {})
	if saved_equipped is Dictionary:
		for slot in saved_equipped:
			if Item.EQUIP_KEYS.has(slot) and saved_equipped[slot] is Dictionary:
				var item := Item.from_dict(saved_equipped[slot])
				item.slot = Item.type_of(slot)
				inventory.equipped[slot] = item
	return inventory


## Funde 3 runas iguais numa da raridade seguinte. Devolve "" ou o motivo da recusa.
func fuse_rune(id: String) -> String:
	if not Runes.is_valid(id):
		return "Runa desconhecida"
	var next := Runes.next_tier_id(id)
	if next == "":
		return "Já é a raridade máxima"
	if int(runes.get(id, 0)) < Runes.FUSE_COST:
		return "Precisa de %d runas iguais" % Runes.FUSE_COST
	runes[id] = int(runes[id]) - Runes.FUSE_COST
	runes[next] = int(runes.get(next, 0)) + 1
	changed.emit()
	return ""


## Runas devolvidas pelo último item vendido, desmantelado ou descartado (ids), para avisar o jogador.
var last_released_runes: Array = []


## Tira as runas incrustadas de um item que vai sair da mochila e as devolve ao estoque de runas.
func release_runes(item: Item) -> Array:
	last_released_runes = []
	for i in item.socket_count():
		var id := item.rune_in(i)
		if id != "":
			runes[id] = int(runes.get(id, 0)) + 1
			last_released_runes.append(id)
			item.remove_rune(i)
	return last_released_runes


## "Runas devolvidas à mochila: Ataque [C], Vida [B]" (vazio se o item não tinha runas).
func released_text(ids: Array = []) -> String:
	var list: Array = ids if not ids.is_empty() else last_released_runes
	if list.is_empty():
		return ""
	var names := PackedStringArray()
	for id in list:
		names.append(str(Runes.DATA[id]["name"]).replace("Runa de ", ""))
	return "Runas devolvidas à mochila: " + ", ".join(names)


## Funde tudo o que dá: de cada runa, 3 iguais viram 1 da raridade seguinte, da C para cima. Devolve
## quantas fusões foram feitas.
func fuse_all_runes() -> int:
	var fusions := 0
	for tier in Runes.TIERS.size() - 1:
		for stat in Runes.STATS:
			var id := Runes.make_id(stat, tier)
			var batches := int(runes.get(id, 0)) / Runes.FUSE_COST
			if batches <= 0:
				continue
			runes[id] = int(runes[id]) - batches * Runes.FUSE_COST
			var next := Runes.make_id(stat, tier + 1)
			runes[next] = int(runes.get(next, 0)) + batches
			fusions += batches
	if fusions > 0:
		changed.emit()
	return fusions
