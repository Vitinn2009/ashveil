class_name Item
extends RefCounted

## Equipamento com raridade e atributos aleatórios. Os valores de `stats` são "pontos",
## os mesmos usados pelos atributos do herói (ver Player). A arma ainda pode ser forjada (até o
## nível 20, com pedras) e despertada (até 3 vezes, com pergaminhos), o que soma mais pontos.

const RARITIES := [
	{"name": "Comum", "color": Color("b8b8c8"), "mult": 1, "weight": 62.0},
	{"name": "Raro", "color": Color("4aa3ff"), "mult": 2, "weight": 26.0},
	{"name": "Épico", "color": Color("b36bff"), "mult": 3, "weight": 10.0},
	{"name": "Lendário", "color": Color("ffb02e"), "mult": 5, "weight": 0.6},
	{"name": "Insano", "color": Color("ff2d3d"), "mult": 8, "weight": 0.03},
]
## Ordem das casas de equipamento na janela da mochila (3 por linha).
const SLOTS := ["helmet", "necklace", "cloak", "weapon", "armor", "offhand", "gloves", "ring", "boots", "mask"]
## Casas de equipamento: os tipos acima mais a segunda casa de anel (o item continua do tipo "ring").
const EQUIP_KEYS := ["weapon", "offhand", "cloak", "mask", "helmet", "armor", "gloves", "boots", "ring", "necklace", "ring2"]
const SLOT_NAMES := {
	"weapon": "Arma", "offhand": "Escudo", "helmet": "Elmo", "armor": "Armadura", "gloves": "Luvas",
	"boots": "Botas", "cloak": "Capa", "ring": "Anel", "necklace": "Colar", "mask": "Máscara", "ring2": "Anel",
}
const STAT_NAMES := {
	"hp": "Vida", "defense": "Defesa", "attack": "Ataque", "speed": "Rapidez", "luck": "Sorte",
	"dex": "Destreza", "critdmg": "Dano crítico", "crit": "Crítico", "aspd": "Vel. de ataque", "stamina": "Resistência",
	"lifesteal": "Roubo de vida", "reflect": "Refletir",
	"penetration": "Penetração", "hp_regen": "Regen de HP", "energy_regen": "Regen de energia", "range": "Alcance",
}
## Atributos que podem sair como bônus aleatório de um item. O dano crítico só vem nos lendários.
const BONUS_STATS := ["hp", "defense", "attack", "speed", "luck", "dex", "crit", "aspd", "stamina", "penetration", "energy_regen", "range"]
## Cada ponto de dano crítico vale +4% no multiplicador do crítico.
const CRIT_DAMAGE_PER_POINT := 4
const PRIMARY := {
	"weapon": "attack", "offhand": "defense", "helmet": "hp", "armor": "defense", "gloves": "attack",
	"boots": "speed", "cloak": "speed", "ring": "luck", "necklace": "hp", "mask": "dex",
}
const BASES := {
	"weapon": ["Espada", "Cajado", "Arco", "Adaga", "Machado", "Lança", "Martelo", "Grimório", "Besta"],
	"offhand": ["Escudo", "Broquel", "Égide", "Tomo"],
	"helmet": ["Elmo", "Capuz", "Coifa", "Coroa", "Máscara"],
	"armor": ["Túnica", "Peitoral", "Manto", "Cota de malha", "Couraça"],
	"gloves": ["Luvas", "Manoplas", "Braçadeiras"],
	"boots": ["Botas", "Sandálias", "Grevas"],
	"cloak": ["Capa", "Capote", "Estola"],
	"ring": ["Anel", "Amuleto", "Sinete"],
	"necklace": ["Colar", "Medalhão", "Talismã", "Pingente"],
	"mask": ["Máscara", "Véu", "Tapa-olho"],
}
## Grupos do filtro da mochila e das lojas.
const GROUPS := {
	"weapons": ["weapon", "offhand"],
	"armor": ["helmet", "armor", "gloves", "boots", "cloak"],
	"accessories": ["ring", "necklace", "mask"],
}
const PREFIXES := ["Rúnico", "Antigo", "Sombrio", "Flamejante", "Gélido", "Ventoso", "Sagrado", "Venenoso", "Tempestuoso", "Lunar"]
## Épicos e lendários ganham também um sufixo.
const SUFFIXES := ["da Aurora", "do Lobo", "da Víbora", "do Trovão", "das Cinzas", "da Lua", "do Dragão", "da Névoa"]

## A cada tantos níveis do item, +1 ponto base nos atributos.
const LEVEL_PER_POINT := 5.0
const MAX_FORGE := 20
const MAX_AWAKEN := 4
## Nível de raridade: cada equipamento sobe até 20 com fragmentos da sua raridade; cada nível soma +6%
## aos atributos base do item.
const MAX_RANK := 20
const RANK_BONUS := 0.06
## Pergaminho de despertar: chance de falhar, de vir negativo (entre os que dão certo) e de vir super raro.
const AWAKEN_FAIL := 0.5
const AWAKEN_NEGATIVE := 0.2
const AWAKEN_SUPER := 0.01
## Status especiais de despertar, muito difíceis de cair: roubo de vida (arma, lendário) e refletir (armadura).
const AWAKEN_LIFESTEAL := 0.012
const AWAKEN_REFLECT := 0.025
## Regen de HP só vem de despertar (armas e armaduras), e é raro.
const AWAKEN_REGEN := 0.03
const AWAKEN_SLOTS := SLOTS
const PERCENT_STATS := ["lifesteal", "reflect", "critdmg"]
## Cada nível de forja soma +1 de ataque na arma, e a cada 5 níveis +1 de crítico.
const FORGE_CRIT_EVERY := 5

var item_name := ""
var slot := "weapon"
var rarity := 0
var stats := {}
## Nível de forja (só armas) e pontos extras dos despertares (um sorteio por pergaminho).
var forge := 0
var awake_stats := {}
var awakenings := 0
var rank := 0
## Nível do item: vem do nível do herói e da fase onde caiu; quanto maior, mais fortes os atributos.
var level := 1
## Runas incrustadas, uma por casa ("" = casa vazia). A quantidade de casas vem da raridade.
var sockets: Array = []


static func roll(luck_points: int, player_level: int, min_rarity := 0) -> Item:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return create(rng, SLOTS[rng.randi() % SLOTS.size()], luck_points, player_level, RARITIES.size() - 1, min_rarity)


## Cria um item de um slot. `max_rarity` limita a raridade (a loja não vende lendários) e
## `min_rarity` garante um mínimo (tesouros de elites e chefes). Os atributos são sorteados:
## o principal do tipo de peça e de 0 a 4 extras diferentes, conforme a raridade.
static func create(rng: RandomNumberGenerator, item_slot: String, luck_points: int, player_level: int, max_rarity := 4, min_rarity := 0) -> Item:
	var item := Item.new()
	item.slot = item_slot
	item.rarity = clampi(_roll_rarity(rng, luck_points), mini(min_rarity, max_rarity), max_rarity)
	var mult: int = RARITIES[item.rarity]["mult"]
	item.level = maxi(player_level, 1)
	var base_value := 1 + floori(item.level / LEVEL_PER_POINT)
	var primary: String = PRIMARY[item_slot]
	item.stats[primary] = maxi(1, roundi(base_value * mult * rng.randf_range(0.85, 1.2)))
	var extra_ranges := [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5]]
	var extra_count := rng.randi_range(extra_ranges[item.rarity][0], extra_ranges[item.rarity][1])
	var pool: Array = BONUS_STATS.duplicate()
	pool.erase(primary)
	for i in extra_count:
		var key: String = pool[rng.randi() % pool.size()]
		pool.erase(key)
		item.stats[key] = maxi(1, roundi((base_value + 1) * mult * rng.randf_range(0.35, 0.8)))
	if item.rarity >= 3:
		item.stats["critdmg"] = 3 + floori(player_level / 12.0) + rng.randi_range(0, 2)
	var bases: Array = BASES[item_slot]
	item.item_name = "%s %s" % [bases[rng.randi() % bases.size()], PREFIXES[rng.randi() % PREFIXES.size()]]
	if item.rarity >= 2:
		item.item_name += " " + SUFFIXES[rng.randi() % SUFFIXES.size()]
	return item


static func _roll_rarity(rng: RandomNumberGenerator, luck_points: int) -> int:
	var weights: Array = []
	var total := 0.0
	for i in RARITIES.size():
		var weight: float = RARITIES[i]["weight"] * (1.0 + 0.1 * luck_points * i)
		weights.append(weight)
		total += weight
	var pick := rng.randf() * total
	for i in weights.size():
		pick -= weights[i]
		if pick <= 0.0:
			return i
	return 0


func to_dict() -> Dictionary:
	return {
		"name": item_name, "slot": slot, "rarity": rarity, "stats": stats.duplicate(),
		"forge": forge, "awake": awake_stats.duplicate(), "awakenings": awakenings, "rank": rank, "level": level, "sockets": sockets.duplicate(),
	}


## Reconstrói um item salvo. Valores inválidos viram valores seguros.
static func from_dict(data: Dictionary) -> Item:
	var item := Item.new()
	item.item_name = str(data.get("name", "Item"))
	var saved_slot := str(data.get("slot", "weapon"))
	item.slot = saved_slot if SLOTS.has(saved_slot) else "weapon"
	item.rarity = clampi(int(data.get("rarity", 0)), 0, RARITIES.size() - 1)
	item.rank = clampi(int(data.get("rank", 0)), 0, MAX_RANK)
	item.level = maxi(int(data.get("level", 1)), 1)
	var saved_sockets = data.get("sockets", [])
	if saved_sockets is Array:
		for id in saved_sockets:
			item.sockets.append(Runes.migrate(str(id)))
	while item.sockets.size() > item.socket_count():
		item.sockets.pop_back()
	var saved_stats = data.get("stats", {})
	if saved_stats is Dictionary:
		for stat in saved_stats:
			if STAT_NAMES.has(stat):
				item.stats[stat] = clampi(int(saved_stats[stat]), 0, 99)
	item.forge = clampi(int(data.get("forge", 0)), 0, MAX_FORGE)
	if AWAKEN_SLOTS.has(item.slot):
		item.awakenings = clampi(int(data.get("awakenings", 0)), 0, MAX_AWAKEN)
		var saved_awake = data.get("awake", {})
		if saved_awake is Dictionary:
			for stat in saved_awake:
				if STAT_NAMES.has(stat):
					item.awake_stats[stat] = clampi(int(saved_awake[stat]), -99, 99)
	return item


## Pontos de um atributo, contando a forja e os despertares.
func stat_total(stat: String) -> int:
	var base := int(stats.get(stat, 0))
	var total := base + int(round(base * rank * RANK_BONUS)) + int(awake_stats.get(stat, 0))
	for id in sockets:
		if id != "" and Runes.DATA.has(id) and Runes.DATA[id]["stat"] == stat:
			total += Runes.value(id)
	total += forge_points(stat)
	return total


## Pontos que a forja dá a um atributo: +1 por nível no atributo principal da peça (ataque nas armas,
## vida no elmo e no colar, defesa na armadura e no escudo...) e, nas armas, +1 de crítico a cada 5 níveis.
func forge_points(stat: String) -> int:
	if stat == PRIMARY[slot]:
		return forge
	if slot == "weapon" and stat == "crit":
		return forge / FORGE_CRIT_EVERY
	return 0


## Todos os atributos do item somados (base + forja + despertar).
func all_stats() -> Dictionary:
	var merged := {}
	for stat in STAT_NAMES:
		var value := stat_total(stat)
		if value != 0:
			merged[stat] = value
	return merged


## Soma dos pontos: serve para ordenar a mochila e comparar itens.
func power() -> int:
	var total := 0
	for value in all_stats().values():
		total += int(value)
	return total


## Nome com o nível de forja e as estrelas de despertar.
func display_name() -> String:
	var text := item_name
	if rank > 0:
		text += " R%d" % rank
	if forge > 0:
		text += " +%d" % forge
	if awakenings > 0:
		text += " " + "★".repeat(awakenings)
	return text


## Custo para levar a arma do nível de forja `level` ao seguinte: pedras, ouro e, dos níveis 10 em
## diante, pedras da lua.
static func forge_cost(level: int) -> Dictionary:
	return {
		"stone": 2 + level,
		"gold": 30 * (level + 1),
		"moonstone": (1 + (level - 10) / 3) if level >= 10 else 0,
	}


## Resultado de um pergaminho de despertar: "fail" (50%, o pergaminho se perde), "negative" (20% dos que
## dão certo: o atributo vem negativo), "super" (1%: ganho triplo) ou "normal". `force` fixa o resultado
## (testes). Devolve também o atributo e o valor sorteados.
func roll_awakening(rng: RandomNumberGenerator, force := "") -> Dictionary:
	var result := "normal" if (force == "special" or force == "regen") else force
	if result == "":
		if rng.randf() < AWAKEN_FAIL:
			result = "fail"
		else:
			var luck := rng.randf()
			result = "super" if luck < AWAKEN_SUPER else ("negative" if luck < AWAKEN_SUPER + AWAKEN_NEGATIVE else "normal")
	var stat: String = BONUS_STATS[rng.randi() % BONUS_STATS.size()]
	var amount := rng.randi_range(2, 4) + awakenings * 2 + rarity
	if stat == "crit" or stat == "aspd":
		amount = maxi(1, amount / 2)
	if result == "super":
		amount *= 3
	elif result == "negative":
		amount = -maxi(1, amount / 2)
	# Status especiais, muito difíceis de cair (só nos despertares que dão certo e não são negativos).
	var special := false
	if result != "fail" and result != "negative":
		var special_chance := AWAKEN_LIFESTEAL if slot == "weapon" else (AWAKEN_REFLECT if slot == "armor" else 0.0)
		if (force == "special" and special_chance > 0.0) or rng.randf() < special_chance:
			special = true
			stat = "lifesteal" if slot == "weapon" else "reflect"
			amount = rng.randi_range(1, 2) if slot == "weapon" else rng.randi_range(3, 8)
		elif (force == "regen" and AWAKEN_SLOTS.has(slot)) or (force == "" and AWAKEN_SLOTS.has(slot) and rng.randf() < AWAKEN_REGEN):
			special = true
			stat = "hp_regen"
			amount = rng.randi_range(1, 3)
	return {"result": result, "stat": stat, "amount": amount, "special": special}


static func group_of(item_slot: String) -> String:
	for group in GROUPS:
		if GROUPS[group].has(item_slot):
			return group
	return "weapons"


func color() -> Color:
	return RARITIES[rarity]["color"]


func rarity_name() -> String:
	return RARITIES[rarity]["name"]


## Valor de referência do item (raridade, atributos, forja, despertares e nível de raridade).
func base_value() -> int:
	return maxi(1, 5 * (rarity + 1) + power() * 2 + forge * 12 + awakenings * 60 + rank * 10)


## Ouro ao vender: 60% do valor de referência (vender não pode render mais do que a loja cobra).
func sell_value() -> int:
	return maxi(1, int(round(base_value() * 0.6)))


## Preço na loja: oito vezes o valor de referência.
func buy_price() -> int:
	return base_value() * 8


## Valor mostrado ao jogador: o dano crítico aparece em porcentagem.
static func display_value(stat: String, value: int) -> int:
	return value * CRIT_DAMAGE_PER_POINT if stat == "critdmg" else value


static func stat_line(stat: String, value: int) -> String:
	if stat == "critdmg":
		return "+%d%% %s" % [display_value(stat, value), STAT_NAMES[stat]]
	if stat == "lifesteal" or stat == "reflect":
		return "%+d%% %s" % [value, STAT_NAMES[stat]]
	return "%+d %s" % [value, STAT_NAMES[stat]]


func stats_text() -> String:
	var parts: Array = []
	var merged := all_stats()
	for stat in merged:
		parts.append(stat_line(stat, int(merged[stat])))
	return ", ".join(parts)


func describe() -> String:
	return "%s\n%s · %s · Nv %d\n%s%s" % [display_name(), rarity_name(), SLOT_NAMES[slot], level, stats_text(), runes_text()]


## O tipo de item que vai numa casa de equipamento ("ring2" também recebe anéis).
static func type_of(key: String) -> String:
	return "ring" if key == "ring2" else key


## Fragmentos da raridade do item para levá-lo do nível de raridade `level` ao seguinte.
static func rank_cost(level: int) -> int:
	return 4 + level * 2


## Fragmentos que um item vira ao ser convertido (pela raridade e pelo poder dele).
func fragment_value() -> int:
	return (rarity + 1) * 2 + maxi(power(), 0) / 6


## Casas de runa: 1 (comum), 2 (raro), 3 (épico), 4 (lendário) ou 5 (insano).
func socket_count() -> int:
	return rarity + 1


## Coloca a runa na primeira casa vazia. Devolve false se não há casa livre.
func insert_rune(id: String) -> bool:
	while sockets.size() < socket_count():
		sockets.append("")
	for i in socket_count():
		if sockets[i] == "":
			sockets[i] = id
			return true
	return false


func rune_in(index: int) -> String:
	return str(sockets[index]) if index < sockets.size() else ""


## Tira a runa da casa (ela se perde).
func remove_rune(index: int) -> void:
	if index < sockets.size():
		sockets[index] = ""


## "Runas: Ataque, vazia" (vazio se a peça não tem runa).
func runes_text() -> String:
	var parts: Array = []
	var any := false
	for i in socket_count():
		var id := rune_in(i)
		any = any or id != ""
		parts.append(Runes.DATA[id]["name"].replace("Runa de ", "") if id != "" else "vazia")
	return ("\nRunas: " + ", ".join(parts)) if any else ""


## Índice da primeira casa de runa livre (-1 se todas estão ocupadas).
func rune_in_free() -> int:
	for i in socket_count():
		if rune_in(i) == "":
			return i
	return -1


## De onde vêm os pontos de um atributo: base, nível de raridade, forja, despertar e runas.
func stat_sources(stat: String) -> Dictionary:
	var base := int(stats.get(stat, 0))
	var sources := {"base": base, "rarity": int(round(base * rank * RANK_BONUS)), "awake": int(awake_stats.get(stat, 0)), "forge": 0, "runes": 0}
	sources["forge"] = forge_points(stat)
	for id in sockets:
		if id != "" and Runes.DATA.has(id) and Runes.DATA[id]["stat"] == stat:
			sources["runes"] += Runes.value(id)
	return sources


## Texto das origens: "base 12 · raridade +2 · forja +6" (só o que existe).
func stat_sources_text(stat: String) -> String:
	var sources := stat_sources(stat)
	var parts := PackedStringArray()
	if sources["base"] != 0:
		parts.append("base %d" % sources["base"])
	var labels := {"rarity": "raridade", "forge": "forja", "awake": "despertar", "runes": "runas"}
	for key in ["rarity", "forge", "awake", "runes"]:
		if sources[key] != 0:
			parts.append("%s %+d" % [labels[key], sources[key]])
	return " · ".join(parts)


## Os atributos separados pela origem: base (com nível de raridade e forja), despertar e runas.
func stat_groups() -> Dictionary:
	var groups := {"base": {}, "awake": {}, "runes": {}}
	for stat in STAT_NAMES:
		var s := stat_sources(stat)
		var base_part := int(s["base"]) + int(s["rarity"]) + int(s["forge"])
		if base_part != 0:
			groups["base"][stat] = base_part
		if int(s["awake"]) != 0:
			groups["awake"][stat] = int(s["awake"])
		if int(s["runes"]) != 0:
			groups["runes"][stat] = int(s["runes"])
	return groups


const GROUP_TITLES := {"base": "Atributos", "awake": "Despertar", "runes": "Runas"}
const GROUP_COLORS := {"base": "7ee08a", "awake": "d9a8ff", "runes": "9fd0ff"}


## Linhas BBCode: um bloco por origem, cada um com título e cor próprios (atributos, despertar e runas).
func sections_bbcode() -> PackedStringArray:
	var lines := PackedStringArray()
	var groups := stat_groups()
	for key in ["base", "awake", "runes"]:
		var group: Dictionary = groups[key]
		if group.is_empty():
			continue
		var color: String = GROUP_COLORS[key]
		lines.append("[color=#%s][b]%s[/b][/color]" % [color, GROUP_TITLES[key]])
		for stat in group:
			var value := int(group[stat])
			var shown := stat_line(stat, value)
			lines.append("  [color=#%s]%s[/color]" % [color if value > 0 else "ff7a6a", shown])
	return lines
