class_name Runes
extends RefCounted

## Runas: caem dos monstros, são vendidas no mercado e se incrustam nos equipamentos e nas armas (de 1 a 4
## casas por peça, conforme a raridade do item). Existe uma runa para cada atributo, em cinco raridades:
## C, B, A, S e SS. A runa incrustada soma pontos daquele atributo à peça. Três runas iguais se fundem
## numa da raridade seguinte.

const TIERS := ["C", "B", "A", "S", "SS"]
const TIER_COLORS := [Color("b8b8c8"), Color("6fd06f"), Color("4aa3ff"), Color("b36bff"), Color("ffb02e")]
## Multiplicador do valor base de cada raridade.
const TIER_MULT := [1, 2, 3, 5, 8]
## Chance relativa de cada raridade nos drops.
const TIER_WEIGHTS := [78.0, 16.0, 5.0, 1.0, 0.2]
## Preço no mercado de cada raridade.
const TIER_PRICES := [200, 500, 1400, 4000, 12000]
const FUSE_COST := 3
## Atributo -> [nome, pontos base da raridade C].
const STATS := {
	"attack": ["Ataque", 1], "defense": ["Defesa", 1], "hp": ["Vida", 4], "speed": ["Velocidade", 1],
	"luck": ["Sorte", 1], "dex": ["Destreza", 1], "crit": ["Crítico", 1], "aspd": ["Vel. de ataque", 1],
	"stamina": ["Resistência", 2], "penetration": ["Penetração", 1], "energy_regen": ["Regen de energia", 1],
	"range": ["Alcance", 1], "critdmg": ["Dano crítico", 1],
}
## Runas do jogo antigo (4 espécies sem raridade) viram a raridade B da espécie equivalente.
const LEGACY := {"crit": "critdmg_B", "hp": "hp_B", "attack": "attack_B", "dex": "dex_B"}

static var DATA := _build()


static func _build() -> Dictionary:
	var data := {}
	for stat in STATS:
		for tier in TIERS.size():
			var id := make_id(stat, tier)
			data[id] = {
				"name": "Runa de %s [%s]" % [STATS[stat][0], TIERS[tier]],
				"stat": stat, "tier": tier,
				"value": int(STATS[stat][1]) * int(TIER_MULT[tier]),
				"color": TIER_COLORS[tier], "glyph": TIERS[tier],
			}
	return data


static func make_id(stat: String, tier: int) -> String:
	return "%s_%s" % [stat, TIERS[tier]]


## Todas as runas, em ordem (por atributo e raridade).
static func ids() -> Array:
	return DATA.keys()


static func is_valid(id: String) -> bool:
	return DATA.has(id)


## Aceita ids do jogo antigo e devolve o id novo ("" se não existe).
static func migrate(id: String) -> String:
	if LEGACY.has(id):
		return LEGACY[id]
	return id if DATA.has(id) else ""


static func tier_of(id: String) -> int:
	return int(DATA[id]["tier"]) if DATA.has(id) else 0


static func value(id: String) -> int:
	return int(DATA[id]["value"]) if DATA.has(id) else 0


static func price(id: String) -> int:
	return int(TIER_PRICES[tier_of(id)])


static func effect_text(id: String) -> String:
	return Item.stat_line(DATA[id]["stat"], value(id))


## A runa da raridade seguinte (do mesmo atributo), ou "" se já é SS.
static func next_tier_id(id: String) -> String:
	var tier := tier_of(id)
	if tier >= TIERS.size() - 1:
		return ""
	return make_id(str(DATA[id]["stat"]), tier + 1)


## Sorteia uma runa: o atributo ao acaso e a raridade pelos pesos (só entre `min_tier` e `max_tier`).
static func roll(rng: RandomNumberGenerator, min_tier := 0, max_tier := 4) -> String:
	var stats: Array = STATS.keys()
	var stat: String = stats[rng.randi() % stats.size()]
	var total := 0.0
	for tier in range(min_tier, max_tier + 1):
		total += TIER_WEIGHTS[tier]
	var pick := rng.randf() * total
	for tier in range(min_tier, max_tier + 1):
		pick -= TIER_WEIGHTS[tier]
		if pick <= 0.0:
			return make_id(stat, tier)
	return make_id(stat, max_tier)
