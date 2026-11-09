class_name Achievements
extends RefCounted

## Conquistas do catálogo de monstros: quanto mais monstros de uma espécie o herói derrota, mais
## títulos ele ganha daquela espécie.

const TIERS := [
	{"kills": 10, "title": "Aprendiz"},
	{"kills": 50, "title": "Caçador"},
	{"kills": 100, "title": "Veterano"},
	{"kills": 250, "title": "Mestre"},
	{"kills": 500, "title": "Lenda"},
	{"kills": 1000, "title": "Exterminador"},
]


## Quantos títulos a espécie já deu com `kills` abates.
static func tier_for(kills: int) -> int:
	var reached := 0
	for tier in TIERS:
		if kills >= int(tier["kills"]):
			reached += 1
	return reached


## Abates necessários para o próximo título (0 quando já tem todos).
static func next_goal(kills: int) -> int:
	for tier in TIERS:
		if kills < int(tier["kills"]):
			return int(tier["kills"])
	return 0


static func title_for(kind: String, tier_index: int) -> String:
	var species: String = EnemyTypes.DATA[kind]["name"] if EnemyTypes.DATA.has(kind) else kind
	return "%s de %s" % [TIERS[clampi(tier_index, 0, TIERS.size() - 1)]["title"], species]
