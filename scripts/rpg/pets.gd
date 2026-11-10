class_name Pets
extends RefCounted

## Pets: acompanham o herói, somam atributos fixos enquanto estão ativos e atiram projéteis nos inimigos.
## O nível do pet (sem limite, melhorado com ouro) só aumenta o dano dos tiros dele; os atributos são
## sempre os mesmos. Há dois pets de chefe (Rei Gosma e Senhor das Cinzas) e um pet para cada monstro do
## jogo (menos a gosma), conquistado ao derrotar 1000 daquele monstro.

const KILLS_TO_UNLOCK := 1000
## Tiros do pet: dano do nível 1, dano extra por nível, tempo entre tiros e alcance.
const BASE_DAMAGE := 8.0
const DAMAGE_PER_LEVEL := 5.0
const SHOT_INTERVAL := 1.5
const SHOT_RANGE := 440.0
const UPGRADE_COST_PER_LEVEL := 100

const BOSS_PETS := {
	"slime_king": {
		"name": "Gosminha Real",
		"boss": "Rei Gosma",
		"stage_id": "slime_king",
		"stats": {"hp": 3, "defense": 2, "luck": 1},
		"color": Color("6fd06f"),
	},
	"ash_lord": {
		"name": "Fagulha das Cinzas",
		"boss": "Senhor das Cinzas",
		"stage_id": "ash_throne",
		"stats": {"attack": 3, "crit": 2, "dex": 2},
		"color": Color("ff8a3a"),
	},
}

## Pets pagos (comprados com diamantes na loja premium, ver Premium).
const PREMIUM_PETS := {
	"dire_wolf": {
		"name": "Lobo Sombrio",
		"premium": true,
		"stats": {"attack": 4, "crit": 3, "hp": 4, "speed": 1},
		"color": Color("6a7388"),
	},
}

## Atributos (pontos) do pet de cada monstro.
const MONSTER_STATS := {
	"bat": {"speed": 2, "aspd": 2, "dex": 1},
	"skeleton": {"defense": 2, "attack": 1, "crit": 1},
	"spider": {"dex": 2, "crit": 1, "aspd": 1},
	"bomber": {"attack": 3, "crit": 1},
	"wolf": {"speed": 2, "attack": 2, "crit": 1},
	"brute": {"hp": 6, "defense": 3},
	"ghost": {"dex": 3, "speed": 1, "stamina": 1},
	"mushroom": {"hp": 4, "stamina": 3, "luck": 1},
	"necromancer": {"attack": 3, "stamina": 2, "aspd": 1},
	"skull": {"attack": 2, "crit": 2},
	"thief": {"luck": 4, "dex": 2},
	"shade": {"crit": 3, "dex": 2, "speed": 1},
	"totem": {"defense": 3, "hp": 4, "stamina": 2},
	"vortex": {"aspd": 3, "attack": 1, "stamina": 1},
	"mimic": {"luck": 3, "hp": 4, "attack": 1},
	"frost": {"aspd": 2, "dex": 2, "crit": 1},
	"golem": {"hp": 6, "defense": 4},
	"imp": {"speed": 2, "attack": 2, "aspd": 1},
	"vampire": {"attack": 2, "hp": 3, "crit": 1},
	"illusionist": {"dex": 3, "luck": 2},
	"storm": {"attack": 3, "crit": 2, "aspd": 1},
	"hedgehog": {"defense": 3, "hp": 3, "stamina": 2},
	"banshee": {"stamina": 3, "dex": 2, "speed": 1},
	"gargoyle": {"defense": 4, "hp": 3, "attack": 1},
	"worm": {"hp": 4, "attack": 2, "speed": 1},
}

## Nomes dos atributos (equipamentos e pets usam estes).
const STAT_NAMES := {
	"hp": "Vida", "defense": "Defesa", "attack": "Ataque", "speed": "Veloc. de movimento", "luck": "Sorte",
	"dex": "Destreza", "crit": "Crítico", "aspd": "Veloc. de ataque", "stamina": "Resistência",
}

static var DATA := _build()


static func _build() -> Dictionary:
	var data := BOSS_PETS.duplicate(true)
	data.merge(PREMIUM_PETS.duplicate(true))
	for kind in MONSTER_STATS:
		var monster: Dictionary = EnemyTypes.DATA[kind]
		data[monster_pet_id(kind)] = {
			"name": "Mini %s" % monster["name"],
			"kind": kind,
			"monster": monster["name"],
			"stats": MONSTER_STATS[kind],
			"color": monster["color"],
		}
	return data


static func monster_pet_id(kind: String) -> String:
	return "m_%s" % kind


static func ids() -> Array:
	return DATA.keys()


static func is_valid(id: String) -> bool:
	return DATA.has(id)


static func get_pet(id: String) -> Dictionary:
	return DATA.get(id, {})


## Atributos do pet: sempre os mesmos, em qualquer nível (o nível só aumenta o dano dos tiros).
static func stats(id: String, _level := 1) -> Dictionary:
	return DATA[id]["stats"] if DATA.has(id) else {}


## Dano de cada tiro do pet no nível `level` (sem nível máximo).
static func attack_damage(level: int) -> float:
	return BASE_DAMAGE + DAMAGE_PER_LEVEL * (maxi(level, 1) - 1)


## Ouro para levar o pet do nível `level` ao seguinte.
static func upgrade_cost(level: int) -> int:
	return UPGRADE_COST_PER_LEVEL * maxi(level, 1)


## O pet que o chefe de uma fase dá (vazio se a fase não tem pet).
static func for_stage(stage_id: String) -> String:
	for id in DATA:
		if DATA[id].get("stage_id", "") == stage_id:
			return id
	return ""


## O pet de um monstro (vazio para a gosma e para quem não tem pet).
static func for_kind(kind: String) -> String:
	var id := monster_pet_id(kind)
	return id if DATA.has(id) else ""


## Como o pet é conquistado ("Derrote 1000 Morcegos" ou "Derrote o chefe Rei Gosma").
static func unlock_text(id: String) -> String:
	var data := get_pet(id)
	if data.get("premium", false):
		return "Compre na loja de diamantes"
	if data.has("kind"):
		return "Derrote %d %s" % [KILLS_TO_UNLOCK, data["monster"]]
	return "Derrote o chefe %s" % data.get("boss", "?")


static func stats_text(id: String, _level := 1) -> String:
	var parts: Array = []
	var values := stats(id)
	for stat in values:
		parts.append("+%d %s" % [values[stat], STAT_NAMES.get(stat, stat)])
	return ", ".join(parts)
