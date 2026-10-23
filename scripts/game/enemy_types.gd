class_name EnemyTypes
extends RefCounted

## Catálogo dos inimigos. Cada tipo tem uma característica própria,
## implementada em Enemy (ver `kind`). `from` é o segundo em que o tipo
## começa a aparecer e `weight` o peso relativo no sorteio.

const DATA := {
	"slime": {
		"name": "Gosma",
		"trait": "Ao morrer, se divide em duas gosmas menores.",
		"color": Color("5fbf6a"),
		"radius": 15.0,
		"health": 24.0,
		"speed": 48.0,
		"damage": 6.0,
		"xp": 1,
		"from": 0.0,
		"weight": 10.0,
	},
	"bat": {
		"name": "Morcego",
		"trait": "Voa em zigue-zague e é muito rápido, mas frágil.",
		"color": Color("8a5fc9"),
		"radius": 10.0,
		"health": 11.0,
		"speed": 125.0,
		"damage": 4.0,
		"xp": 1,
		"from": 25.0,
		"weight": 5.0,
	},
	"skeleton": {
		"name": "Esqueleto Arqueiro",
		"trait": "Mantém distância e atira ossos de longe.",
		"color": Color("e8e2d0"),
		"radius": 14.0,
		"health": 20.0,
		"speed": 62.0,
		"damage": 5.0,
		"xp": 2,
		"from": 50.0,
		"weight": 4.0,
	},
	"bomber": {
		"name": "Bomba-viva",
		"trait": "Corre até você e explode em área depois de uma contagem.",
		"color": Color("3a3a4a"),
		"radius": 13.0,
		"health": 14.0,
		"speed": 88.0,
		"damage": 0.0,
		"xp": 2,
		"from": 75.0,
		"weight": 3.0,
	},
	"brute": {
		"name": "Bruto",
		"trait": "Enorme e resistente: reduz 25% do dano e ignora empurrões.",
		"color": Color("a8452a"),
		"radius": 26.0,
		"health": 120.0,
		"speed": 36.0,
		"damage": 14.0,
		"xp": 5,
		"from": 100.0,
		"weight": 2.5,
		"knockback_immune": true,
		"damage_taken_mult": 0.75,
	},
}


static func get_type(kind: String) -> Dictionary:
	return DATA[kind]


## Sorteia um tipo entre os que já apareceram no segundo `elapsed`.
static func pick(elapsed: float) -> String:
	var total := 0.0
	for kind in DATA:
		if DATA[kind]["from"] <= elapsed:
			total += DATA[kind]["weight"]
	var roll := randf() * total
	for kind in DATA:
		if DATA[kind]["from"] > elapsed:
			continue
		roll -= DATA[kind]["weight"]
		if roll <= 0.0:
			return kind
	return "slime"
