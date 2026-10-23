class_name Heroes
extends RefCounted

## Catálogo dos heróis jogáveis. `attack` define o estilo de ataque:
## "magic" e "arrow" disparam projéteis, "melee" golpeia em área ao redor.

const DATA := {
	"mage": {
		"name": "Mago",
		"title": "Mestre dos elementos",
		"description": "Frágil, mas domina três magias. Ataca de longe com projéteis arcanos.",
		"art": "res://assets/characters/mage.svg",
		"color": Color("8a6bff"),
		"attack": "magic",
		"health": 70.0,
		"speed": 200.0,
		"defense": 0.0,
		"damage": 14.0,
		"interval": 0.75,
		"range": 340.0,
		"projectile_speed": 440.0,
		"projectile_color": Color("6ec6ff"),
		"skills": ["freeze", "fire", "wind"],
	},
	"archer": {
		"name": "Arqueiro",
		"title": "Atirador veloz",
		"description": "Ágil e preciso. Suas flechas atravessam o primeiro inimigo.",
		"art": "res://assets/characters/archer.svg",
		"color": Color("5fae6e"),
		"attack": "arrow",
		"health": 95.0,
		"speed": 235.0,
		"defense": 2.0,
		"damage": 11.0,
		"interval": 0.55,
		"range": 380.0,
		"projectile_speed": 660.0,
		"projectile_color": Color("f4e9d8"),
		"skills": ["double", "haste"],
	},
	"warrior": {
		"name": "Guerreiro",
		"title": "Muralha de aço",
		"description": "Resistente e corpo a corpo. Quanto mais perto do inimigo, mais dano causa.",
		"art": "res://assets/characters/warrior.svg",
		"color": Color("c4ccd8"),
		"attack": "melee",
		"health": 150.0,
		"speed": 215.0,
		"defense": 6.0,
		"damage": 18.0,
		"interval": 0.7,
		"range": 100.0,
		"projectile_speed": 0.0,
		"projectile_color": Color("e8edf5"),
		"skills": ["shield"],
	},
}


static func ids() -> Array:
	return ["mage", "archer", "warrior"]


static func get_hero(id: String) -> Dictionary:
	return DATA.get(id, DATA["warrior"])
