class_name Evolution
extends RefCounted

## Evolução individual de cada herói: três etapas, liberadas por nível do herói e pagas com ouro e
## pedras da lua. Cada herói evolui por um caminho próprio, com nomes e bônus diferentes.
## Os bônus são pontos de atributo (como os dos equipamentos); `skill_power` e `skill_range`
## reforçam as habilidades.

const TIERS := 3
const REQUIREMENTS := [
	{"level": 10, "gold": 300, "moonstone": 3},
	{"level": 25, "gold": 1200, "moonstone": 8},
	{"level": 50, "gold": 4000, "moonstone": 20},
]
const PATHS := {
	"mage": [
		{"name": "Mago Arcano", "bonus": {"attack": 3, "skill_power": 1}},
		{"name": "Arquimago", "bonus": {"attack": 5, "crit": 3, "skill_power": 2}},
		{"name": "Mestre dos Elementos", "bonus": {"attack": 8, "crit": 5, "skill_power": 3, "skill_range": 2}},
	],
	"archer": [
		{"name": "Patrulheiro", "bonus": {"dex": 3, "aspd": 2}},
		{"name": "Caçador Mestre", "bonus": {"dex": 5, "aspd": 4, "crit": 3}},
		{"name": "Lenda da Floresta", "bonus": {"dex": 8, "aspd": 6, "crit": 5, "speed": 3}},
	],
	"warrior": [
		{"name": "Cavaleiro", "bonus": {"defense": 4, "hp": 4}},
		{"name": "Paladino", "bonus": {"defense": 7, "hp": 8, "attack": 3}},
		{"name": "Senhor da Guerra", "bonus": {"defense": 10, "hp": 14, "attack": 6, "stamina": 4}},
	],
	"gnome": [
		{"name": "Engenheiro", "bonus": {"luck": 3, "stamina": 2}},
		{"name": "Inventor", "bonus": {"luck": 5, "attack": 3, "stamina": 4, "skill_power": 1}},
		{"name": "Mestre Artífice", "bonus": {"luck": 8, "attack": 5, "speed": 3, "skill_power": 2, "skill_range": 2}},
	],
}
const EXTRA_NAMES := {"skill_power": "Poder das habilidades", "skill_range": "Alcance das habilidades"}


## Dados da etapa `tier` (1 a 3) do herói; vazio se não existir.
static func tier_data(hero: String, tier: int) -> Dictionary:
	if not PATHS.has(hero) or tier < 1 or tier > TIERS:
		return {}
	return PATHS[hero][tier - 1]


## Nome da evolução atual ("" no começo).
static func title(hero: String, tier: int) -> String:
	return str(tier_data(hero, tier).get("name", ""))


## Bônus acumulados até a etapa `tier`. As etapas somam: a 3 inclui o que a 1 e a 2 davam.
static func bonus(hero: String, tier: int) -> Dictionary:
	var total := {}
	for i in range(1, mini(tier, TIERS) + 1):
		var step: Dictionary = tier_data(hero, i).get("bonus", {})
		for stat in step:
			total[stat] = int(total.get(stat, 0)) + int(step[stat])
	return total


static func bonus_text(step_bonus: Dictionary) -> String:
	var parts: Array = []
	for stat in step_bonus:
		var label: String = EXTRA_NAMES.get(stat, Pets.STAT_NAMES.get(stat, stat))
		parts.append("+%d %s" % [step_bonus[stat], label])
	return ", ".join(parts)
