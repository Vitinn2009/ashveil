class_name Stages
extends RefCounted

## As fases do Ashveil, infinitas: a cada 10 fases vem uma fase de chefe (a 10ª, a 20ª...) e os monstros ficam
## cada vez mais fortes. As fases são montadas a partir de modelos (DATA) que se repetem. Cada fase comum
## tem 2 tipos de monstro a mais que a anterior, eventos no meio da missão (hordas, elites e um mini
## chefe), 2 minutos até o primeiro chefe e 3 minutos depois dele, e acaba
## quando o tempo passa e o último monstro cai. Na fase de chefe o chefe entra logo no começo e a fase
## acaba quando ele morre. Ganhar uma fase libera a próxima; a nota vai de 1 a 3 estrelas: 1 por
## vencer, 2 por bater a meta de abates e 3 por vencer com a vida alta.
##
## `interval` é o tempo entre grupos no começo e no fim da fase, `max` o limite de inimigos vivos
## (também do começo ao fim), `hp_growth` e `dmg_growth` quanto os inimigos ficam mais fortes por
## segundo, e `events` o momento (fração do tempo) de cada evento.

const STAR_HEALTH := 0.4
## A cada quantas fases vem um chefe: 9 comuns e a 10ª é o chefe.
const BOSS_EVERY := 10
## Modelos (posições em DATA) das fases comuns e de chefe, em ordem; depois do último voltam ao primeiro.
const NORMAL_TEMPLATES := [0, 1, 2, 3, 5, 6, 7, 8]
const BOSS_TEMPLATES := [4, 9]
## Por fase, a recompensa e a meta de abates crescem.
const REWARD_PER_STAGE := 0.12
const KILLS_PER_STAGE := 4
const HP_MULT_PER_STAGE := 0.015
const DMG_MULT_PER_STAGE := 0.012
const ROMAN := ["", "", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]

const DATA := [
	{
		"id": "forest", "name": "Floresta Sombria",
		"blurb": "Gosmas e morcegos. Um começo tranquilo, sem habilidades: só você e o botão de ataque.",
		"duration": 120.0, "reward": 20, "kill_goal": 300,
		"kinds": ["slime", "bat"],
		"interval": [2.0, 1.1], "max": [14, 34], "hp_mult": 1.0, "hp_growth": 0.010, "dmg_mult": 1.0, "dmg_growth": 0.003,
		"events": [[0.35, "horde"], [0.5, "miniboss"], [0.75, "elite"]],
		"tint": Color(1, 1, 1),
	},
	{
		"id": "swamp", "name": "Pântano Venenoso",
		"blurb": "Teias e esporos venenosos. Sua primeira habilidade é liberada aqui.",
		"duration": 120.0, "reward": 35, "kill_goal": 340,
		"kinds": ["slime", "bat", "spider", "mushroom"],
		"interval": [1.9, 1.0], "max": [16, 38], "hp_mult": 1.15, "hp_growth": 0.011, "dmg_mult": 1.1, "dmg_growth": 0.003,
		"events": [[0.3, "horde"], [0.5, "miniboss"], [0.7, "elite"], [0.85, "horde"]],
		"tint": Color(0.86, 1.0, 0.82),
	},
	{
		"id": "ruins", "name": "Ruínas Esquecidas",
		"blurb": "Mortos-vivos, lobos e ladrões de ouro. Fique de olho no seu bolso.",
		"duration": 120.0, "reward": 50, "kill_goal": 380,
		"kinds": ["spider", "mushroom", "skeleton", "ghost", "wolf", "thief"],
		"interval": [1.8, 0.95], "max": [18, 42], "hp_mult": 1.3, "hp_growth": 0.012, "dmg_mult": 1.2, "dmg_growth": 0.0035,
		"events": [[0.25, "horde"], [0.45, "elite"], [0.55, "miniboss"], [0.7, "horde"], [0.85, "elite"]],
		"tint": Color(0.9, 0.9, 1.0),
	},
	{
		"id": "fortress", "name": "Fortaleza de Pedra",
		"blurb": "Brutos, bombas e totens que curam os monstros: derrube-os primeiro.",
		"duration": 120.0, "reward": 70, "kill_goal": 420,
		"kinds": ["bat", "skeleton", "ghost", "wolf", "thief", "bomber", "brute", "totem"],
		"interval": [1.7, 0.9], "max": [20, 46], "hp_mult": 1.5, "hp_growth": 0.013, "dmg_mult": 1.35, "dmg_growth": 0.004,
		"events": [[0.2, "horde"], [0.4, "elite"], [0.55, "miniboss"], [0.7, "horde"], [0.85, "elite"]],
		"tint": Color(1.0, 0.92, 0.86),
	},
	{
		"id": "slime_king", "name": "Covil do Rei Gosma", "boss_stage": true,
		"blurb": "CHEFE: o Rei Gosma chega logo no começo. Vença para liberar o ataque automático.",
		"duration": 600.0, "reward": 120, "kill_goal": 80,
		"kinds": ["slime", "bat", "skeleton", "wolf"],
		"interval": [3.2, 2.2], "max": [8, 14], "hp_mult": 1.6, "hp_growth": 0.006, "dmg_mult": 1.4, "dmg_growth": 0.002,
		"events": [[0.07, "miniboss"]],
		"boss": {"kind": "slime", "name": "Rei Gosma", "hp": 75.0, "scale": 3.0, "damage": 3.0},
		"tint": Color(0.88, 1.0, 0.85),
	},
	{
		"id": "hills", "name": "Colinas Ventosas",
		"blurb": "Agora com necromantes que invocam caveirinhas e mímicos disfarçados de tesouro.",
		"duration": 180.0, "reward": 100, "kill_goal": 600,
		"kinds": ["wolf", "ghost", "skeleton", "necromancer", "thief", "brute", "bomber", "mimic", "totem", "spider"],
		"interval": [1.6, 0.85], "max": [22, 50], "hp_mult": 1.8, "hp_growth": 0.013, "dmg_mult": 1.5, "dmg_growth": 0.0045,
		"events": [[0.2, "horde"], [0.4, "elite"], [0.55, "miniboss"], [0.7, "horde"], [0.85, "elite"]],
		"tint": Color(1.0, 0.97, 0.88),
	},
	{
		"id": "crypt", "name": "Cripta Esquecida",
		"blurb": "Sombras surgem nas suas costas e vórtices puxam você para a horda.",
		"duration": 180.0, "reward": 120, "kill_goal": 650,
		"kinds": ["necromancer", "shade", "vortex", "ghost", "brute", "bomber", "mimic", "totem", "wolf", "thief", "skeleton", "mushroom"],
		"interval": [1.5, 0.8], "max": [24, 54], "hp_mult": 2.0, "hp_growth": 0.014, "dmg_mult": 1.65, "dmg_growth": 0.005,
		"events": [[0.18, "horde"], [0.36, "elite"], [0.5, "miniboss"], [0.65, "horde"], [0.85, "elite"]],
		"tint": Color(0.85, 0.85, 1.0),
	},
	{
		"id": "black_swamp", "name": "Pântano Negro",
		"blurb": "Quase tudo o que existe, e todos querem você.",
		"duration": 180.0, "reward": 140, "kill_goal": 700,
		"kinds": ["bat", "spider", "mushroom", "skeleton", "ghost", "wolf", "thief", "bomber", "brute", "totem", "necromancer", "mimic", "shade", "vortex"],
		"interval": [1.4, 0.75], "max": [26, 58], "hp_mult": 2.2, "hp_growth": 0.015, "dmg_mult": 1.8, "dmg_growth": 0.0055,
		"events": [[0.16, "horde"], [0.32, "elite"], [0.5, "miniboss"], [0.66, "horde"], [0.85, "elite"]],
		"tint": Color(0.78, 0.95, 0.8),
	},
	{
		"id": "citadel", "name": "Cidadela em Ruínas",
		"blurb": "Todos os 15 tipos de monstro, juntos. Última parada antes do Senhor das Cinzas.",
		"duration": 180.0, "reward": 160, "kill_goal": 750,
		"kinds": ["slime", "bat", "spider", "mushroom", "skeleton", "ghost", "wolf", "thief", "bomber", "brute", "totem", "necromancer", "mimic", "shade", "vortex"],
		"interval": [1.3, 0.7], "max": [28, 60], "hp_mult": 2.5, "hp_growth": 0.016, "dmg_mult": 2.0, "dmg_growth": 0.006,
		"events": [[0.15, "horde"], [0.3, "elite"], [0.5, "miniboss"], [0.65, "horde"], [0.85, "elite"]],
		"tint": Color(1.0, 0.86, 0.84),
	},
	{
		"id": "ash_throne", "name": "Trono das Cinzas", "boss_stage": true,
		"blurb": "CHEFE: o Senhor das Cinzas e seus servos. O fim da primeira jornada.",
		"duration": 600.0, "reward": 300, "kill_goal": 100,
		"kinds": ["wolf", "shade", "necromancer", "brute", "vortex", "totem"],
		"interval": [2.8, 1.8], "max": [10, 18], "hp_mult": 2.7, "hp_growth": 0.007, "dmg_mult": 2.1, "dmg_growth": 0.003,
		"events": [[0.07, "miniboss"]],
		"boss": {"kind": "necromancer", "name": "Senhor das Cinzas", "hp": 240.0, "scale": 3.4, "damage": 4.5},
		"tint": Color(1.0, 0.82, 0.8),
	},
]


## Monstros novos, na ordem em que entram nas voltas seguintes pelas fases.
const LATE_KINDS := ["imp", "hedgehog", "frost", "banshee", "vampire", "golem", "illusionist", "storm", "gargoyle", "worm"]

static var _cache := {}


## Quantas fases existem: nenhuma é a última (a lista é infinita).
static func count() -> int:
	return 1 << 30


## A fase de índice `index` (0 = fase 1). Monta a partir do modelo e guarda o resultado.
static func get_stage(index: int) -> Dictionary:
	index = maxi(index, 0)
	if _cache.has(index):
		return _cache[index]
	var number := index + 1
	var boss := number % BOSS_EVERY == 0
	var template_index: int
	var cycle: int
	if boss:
		var boss_number := number / BOSS_EVERY - 1
		template_index = BOSS_TEMPLATES[boss_number % BOSS_TEMPLATES.size()]
		cycle = boss_number / BOSS_TEMPLATES.size()
	else:
		var normal_number := index - number / BOSS_EVERY
		template_index = NORMAL_TEMPLATES[normal_number % NORMAL_TEMPLATES.size()]
		cycle = normal_number / NORMAL_TEMPLATES.size()
	var stage: Dictionary = DATA[template_index].duplicate(true)
	stage["index"] = index
	stage["number"] = number
	stage["duration"] = 600.0 if boss else (120.0 if number < BOSS_EVERY else 180.0)
	# Quanto mais longe, mais forte: a vida e o dano crescem de forma contínua (sem depender do modelo da fase).
	stage["hp_mult"] = 1.0 + HP_MULT_PER_STAGE * index
	stage["dmg_mult"] = 1.0 + DMG_MULT_PER_STAGE * index
	stage["reward"] = int(round(float(stage["reward"]) * (1.0 + REWARD_PER_STAGE * index)))
	stage["kill_goal"] = int(round((int(stage["kill_goal"]) + index * KILLS_PER_STAGE) * (0.45 + 0.55 * easiness(index))))
	if cycle > 0 and not boss:
		# A cada volta pelas fases, mais monstros novos entram (4, depois 7, depois todos os 10).
		var extra := mini(1 + cycle * 3, LATE_KINDS.size())
		for i in extra:
			if not stage["kinds"].has(LATE_KINDS[i]):
				stage["kinds"].append(LATE_KINDS[i])
	if cycle > 0:
		var suffix: String = ROMAN[mini(cycle + 1, ROMAN.size() - 1)] if cycle + 1 < ROMAN.size() else str(cycle + 1)
		stage["name"] = "%s %s" % [stage["name"], suffix]
		if boss:
			stage["boss"]["name"] = "%s %s" % [stage["boss"]["name"], suffix]
	_cache[index] = stage
	return stage


## Fase de chefe: o chefe entra no começo e a fase acaba quando ele morre.
static func is_boss_stage(stage: Dictionary) -> bool:
	return bool(stage.get("boss_stage", false))


## Tipos de monstro da fase. Todos já aparecem desde o começo: o que muda de uma fase para a
## outra é a lista (2 a mais por fase comum).
static func unlocked_kinds(stage: Dictionary, _elapsed: float = 0.0) -> Array:
	return stage["kinds"]


## O tempo "de dificuldade" que o catálogo de inimigos usa: a fase inteira equivale a 240 s.
static func difficulty_time(stage: Dictionary, elapsed: float) -> float:
	return clampf(elapsed / float(stage["duration"]), 0.0, 1.0) * 240.0


static func spawn_interval(stage: Dictionary, elapsed: float) -> float:
	var progress := clampf(elapsed / float(stage["duration"]), 0.0, 1.0)
	return lerpf(stage["interval"][0], stage["interval"][1], progress)


static func max_enemies(stage: Dictionary, elapsed: float) -> int:
	var progress := clampf(elapsed / float(stage["duration"]), 0.0, 1.0)
	return int(round(lerpf(stage["max"][0], stage["max"][1], progress) * (0.5 + 0.5 * easiness(index_of(stage)))))


## Reforço geral da vida dos inimigos e, a cada fase, mais vida e mais dano (somados sobre o da fase).
const HP_BOOST := 2.8
## Reforço geral do dano dos inimigos.
const DAMAGE_BOOST := 2.0
const HP_STEP_PER_STAGE := 0.22
const DAMAGE_STEP_PER_STAGE := 0.18


static func index_of(stage: Dictionary) -> int:
	return int(stage.get("index", 0))


static func hp_scale(stage: Dictionary, elapsed: float) -> float:
	return float(stage["hp_mult"]) * HP_BOOST * easiness(index_of(stage)) * (1.0 + HP_STEP_PER_STAGE * index_of(stage)) * (1.0 + float(stage["hp_growth"]) * elapsed)


static func damage_scale(stage: Dictionary, elapsed: float) -> float:
	return float(stage["dmg_mult"]) * DAMAGE_BOOST * easiness(index_of(stage)) * (1.0 + DAMAGE_STEP_PER_STAGE * index_of(stage)) * (1.0 + float(stage["dmg_growth"]) * elapsed)


## Nota da fase, de 0 (perdeu) a 3.
static func stars(stage: Dictionary, won: bool, kills: int, health_ratio: float) -> int:
	if not won:
		return 0
	var result := 1
	if kills >= int(stage["kill_goal"]):
		result += 1
	if health_ratio >= STAR_HEALTH:
		result += 1
	return result


## Facilidade das primeiras fases: a fase 1 tem só 35% da força (vida, dano e defesa) e a quantidade de
## inimigos e a meta de abates também são menores; sobe de forma contínua até a fase 13, que já vale 100%.
const EASE_START := 0.35
const EASE_STAGES := 12.0


static func easiness(index: int) -> float:
	return EASE_START + (1.0 - EASE_START) * clampf(index / EASE_STAGES, 0.0, 1.0)


## Esquiva dos inimigos: nenhuma até a fase 5; depois cresce devagar (5% do valor cheio por fase) e
## nunca passa do teto, porque esquiva em excesso torna o jogo injusto.
const DODGE_FROM_STAGE := 6
const DODGE_RAMP_PER_STAGE := 0.05
const DODGE_CAP := 0.15


static func enemy_dodge(base_dodge: float, index: int) -> float:
	var number := index + 1
	if number < DODGE_FROM_STAGE or base_dodge <= 0.0:
		return 0.0
	var ramp := clampf((number - DODGE_FROM_STAGE + 1) * DODGE_RAMP_PER_STAGE, 0.0, 1.0)
	return minf(base_dodge * ramp, DODGE_CAP)
