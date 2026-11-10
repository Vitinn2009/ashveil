class_name Premium
extends RefCounted

## Loja premium: tudo o que se compra com diamantes (herói Viking, pet Lobo Sombrio, equipamentos de alta
## raridade e pacotes de itens) e os pacotes de diamantes que se compram com dinheiro de verdade. Todos os
## preços podem ser editados no painel admin (ver Tuning.price).

## Pacotes de diamantes: quantidade e preço em reais. O pagamento real passa por Billing.
const PACKS := [
	{"id": "pack_s", "name": "Punhado de diamantes", "diamonds": 80, "brl": 4.99},
	{"id": "pack_m", "name": "Bolsa de diamantes", "diamonds": 450, "brl": 24.99},
	{"id": "pack_l", "name": "Baú de diamantes", "diamonds": 1000, "brl": 49.99},
	{"id": "pack_xl", "name": "Cofre de diamantes", "diamonds": 2200, "brl": 99.99},
]

## Produtos pagos com diamantes. `kind`: hero, pet, gear (equipamento novo), item (materiais e pacotes).
const ENTRIES := [
	{"id": "hero_viking", "kind": "hero", "hero": "viking", "name": "Viking",
		"desc": "Guerreiro do norte: machado, escudo redondo, muita vida e 9 habilidades novas.", "price": 800},
	{"id": "pet_dire_wolf", "kind": "pet", "pet": "dire_wolf", "name": "Lobo Sombrio",
		"desc": "Um lobo de pelo escuro que ataca de perto e traz bônus de ataque, crítico e vida.", "price": 500},
	{"id": "gear_epic_weapon", "kind": "gear", "slot": "weapon", "rarity": 2, "name": "Arma Épica", "desc": "Uma arma épica na hora.", "price": 120},
	{"id": "gear_epic_armor", "kind": "gear", "slot": "armor", "rarity": 2, "name": "Armadura Épica", "desc": "Uma armadura épica na hora.", "price": 120},
	{"id": "gear_legend_weapon", "kind": "gear", "slot": "weapon", "rarity": 3, "name": "Arma Lendária", "desc": "Uma arma lendária, com dano crítico.", "price": 400},
	{"id": "gear_legend_armor", "kind": "gear", "slot": "armor", "rarity": 3, "name": "Armadura Lendária", "desc": "Uma armadura lendária.", "price": 400},
	{"id": "gear_legend_helmet", "kind": "gear", "slot": "helmet", "rarity": 3, "name": "Elmo Lendário", "desc": "Um elmo lendário.", "price": 350},
	{"id": "gear_legend_boots", "kind": "gear", "slot": "boots", "rarity": 3, "name": "Botas Lendárias", "desc": "Botas lendárias.", "price": 300},
	{"id": "gear_insane_weapon", "kind": "gear", "slot": "weapon", "rarity": 4, "name": "Arma Insana", "desc": "A raridade mais alta: uma arma Insana.", "price": 2500},
	{"id": "gear_insane_armor", "kind": "gear", "slot": "armor", "rarity": 4, "name": "Armadura Insana", "desc": "A raridade mais alta: uma armadura Insana.", "price": 2500},
	{"id": "item_potions", "kind": "item", "what": "potion", "amount": 10, "name": "10 Jarras de cura", "desc": "Dez jarras para a partida.", "price": 30},
	{"id": "item_gold", "kind": "item", "what": "gold", "amount": 5000, "name": "Bolsa de 5.000 de ouro", "desc": "Ouro para o mercado e o ferreiro.", "price": 60},
	{"id": "item_stone", "kind": "item", "what": "stone", "amount": 20, "name": "20 Pedras de forja", "desc": "Para forjar equipamentos.", "price": 40},
	{"id": "item_moon", "kind": "item", "what": "moonstone", "amount": 5, "name": "5 Pedras da lua", "desc": "Material raro de forja.", "price": 80},
	{"id": "item_scrolls", "kind": "item", "what": "scroll", "amount": 3, "name": "3 Pergaminhos de despertar", "desc": "Despertam atributos extras na arma.", "price": 150},
	{"id": "item_key", "kind": "item", "what": "key", "amount": 3, "name": "3 Chaves de espaço", "desc": "Cada chave abre mais uma casa na mochila.", "price": 100},
	{"id": "item_frag_epic", "kind": "item", "what": "fragments", "rarity": 2, "amount": 50, "name": "50 Fragmentos épicos", "desc": "Sobem o nível de raridade dos equipamentos épicos.", "price": 90},
	{"id": "item_frag_legend", "kind": "item", "what": "fragments", "rarity": 3, "amount": 30, "name": "30 Fragmentos lendários", "desc": "Sobem o nível de raridade dos equipamentos lendários.", "price": 250},
]

const KINDS := ["hero", "pet", "gear", "item"]


static func entry(id: String) -> Dictionary:
	for e in ENTRIES:
		if e["id"] == id:
			return e
	return {}


static func entries_of(kind: String) -> Array:
	return ENTRIES.filter(func(e: Dictionary) -> bool: return e["kind"] == kind)


## Preço atual em diamantes (com o ajuste do painel admin).
static func price(id: String) -> int:
	var e := entry(id)
	return maxi(int(round(Tuning.price(id, float(e.get("price", 0))))), 0)


## Pacote de diamantes com quantidade e preço em reais já ajustados pelo admin.
static func pack(id: String) -> Dictionary:
	for p in PACKS:
		if p["id"] == id:
			return {
				"id": id, "name": p["name"],
				"diamonds": maxi(int(round(Tuning.price(id + "_dia", float(p["diamonds"])))), 1),
				"brl": maxf(Tuning.price(id + "_brl", float(p["brl"])), 0.0),
			}
	return {}


static func owned(id: String) -> bool:
	var e := entry(id)
	match e.get("kind", ""):
		"hero":
			return Session.hero_owned(e["hero"])
		"pet":
			return Session.pets.has(e["pet"])
	return false


## Compra com diamantes. Devolve "" se deu certo ou o motivo da recusa.
static func buy(id: String) -> String:
	var e := entry(id)
	if e.is_empty():
		return "Produto inexistente"
	if owned(id):
		return "Você já tem este produto"
	var cost := price(id)
	if Session.diamonds < cost:
		return "Faltam %d diamantes" % (cost - Session.diamonds)
	var inventory := Session.inventory
	if e["kind"] == "gear" and inventory.bag.size() >= inventory.bag_capacity:
		return "Mochila cheia: abra espaço antes de comprar"
	Session.spend_diamonds(cost)
	grant(id)
	return ""


## Entrega o produto (sem cobrar). Usado pela compra e pelo painel admin.
static func grant(id: String) -> void:
	var e := entry(id)
	var inventory := Session.inventory
	match e.get("kind", ""):
		"hero":
			Session.unlock_hero(e["hero"])
		"pet":
			Session.grant_pet(e["pet"])
		"gear":
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			var level := int(Session.progress_for(Session.hero_id)["level"]) + 6 * Session.stage_index
			inventory.add_item(Item.create(rng, e["slot"], 0, maxi(level, 1), int(e["rarity"]), int(e["rarity"])))
		"item":
			match e["what"]:
				"potion":
					inventory.add_consumable("potion", int(e["amount"]))
				"gold":
					inventory.add_gold(int(e["amount"]))
				"fragments":
					inventory.add_fragments(int(e["rarity"]), int(e["amount"]))
				_:
					inventory.add_material(String(e["what"]), int(e["amount"]))
	Session.save_game()


## Compra de um pacote de diamantes com dinheiro de verdade: passa pelo Google Play. Sem o plugin de
## cobrança instalado, a compra não acontece (só o modo de teste do admin entrega de graça).
## Devolve "" se os diamantes foram entregues ou o motivo de não terem sido.
static func buy_pack(id: String) -> String:
	var p := pack(id)
	if p.is_empty():
		return "Pacote inexistente"
	if Tuning.unlocked and Tuning.test_purchases:
		Session.add_diamonds(int(p["diamonds"]))
		Session.save_game()
		return ""
	return Billing.purchase(id)
