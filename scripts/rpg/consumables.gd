class_name Consumables
extends RefCounted

## Poção de vida e comidas. As comidas curam ou dão um bônus temporário.

const FOOD_IDS := ["bread", "roast", "stew"]
const DATA := {
	"potion": {
		"name": "Poção de vida",
		"desc": "Cura 40% da vida máxima.",
		"price": 50,
		"heal": 0.4,
		"icon": "potion",
		"color": Color("e0452d"),
	},
	"bread": {
		"name": "Pão",
		"desc": "Cura 25% da vida máxima.",
		"price": 20,
		"heal": 0.25,
		"icon": "bread",
		"color": Color("d9a05a"),
	},
	"roast": {
		"name": "Carne assada",
		"desc": "Cura 60% da vida máxima.",
		"price": 55,
		"heal": 0.6,
		"icon": "meat",
		"color": Color("b8643a"),
	},
	"stew": {
		"name": "Sopa de cogumelo",
		"desc": "+25% de velocidade de ataque por 30s.",
		"price": 45,
		"buff_time": 30.0,
		"icon": "stew",
		"color": Color("9a6fd0"),
	},
}


static func def(id: String) -> Dictionary:
	return DATA[id]
