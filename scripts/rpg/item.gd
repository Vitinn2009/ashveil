class_name Item
extends RefCounted

## Equipamento com raridade e atributos. Os valores de `stats` são "pontos",
## os mesmos usados pelos atributos do herói (ver Player).

const RARITIES := [
	{"name": "Comum", "color": Color("b8b8c8"), "mult": 1, "weight": 62.0},
	{"name": "Raro", "color": Color("4aa3ff"), "mult": 2, "weight": 26.0},
	{"name": "Épico", "color": Color("b36bff"), "mult": 3, "weight": 10.0},
	{"name": "Lendário", "color": Color("ffb02e"), "mult": 5, "weight": 2.0},
]
const SLOTS := ["weapon", "armor", "boots", "ring"]
const SLOT_NAMES := {"weapon": "Arma", "armor": "Armadura", "boots": "Botas", "ring": "Anel"}
const STAT_NAMES := {"hp": "Vida", "defense": "Defesa", "attack": "Ataque", "speed": "Rapidez", "luck": "Sorte"}
const PRIMARY := {"weapon": "attack", "armor": "defense", "boots": "speed", "ring": "luck"}
const BASES := {
	"weapon": ["Espada", "Cajado", "Arco", "Adaga"],
	"armor": ["Túnica", "Peitoral", "Manto"],
	"boots": ["Botas", "Sandálias"],
	"ring": ["Anel", "Amuleto"],
}
const PREFIXES := ["Rúnico", "Antigo", "Sombrio", "Flamejante", "Gélido", "Ventoso"]

var item_name := ""
var slot := "weapon"
var rarity := 0
var stats := {}


static func roll(luck_points: int, player_level: int) -> Item:
	var item := Item.new()
	item.slot = SLOTS.pick_random()
	item.rarity = _roll_rarity(luck_points)
	var mult: int = RARITIES[item.rarity]["mult"]
	var base_value := 1 + floori(player_level / 6.0)
	item.stats[PRIMARY[item.slot]] = base_value * mult
	if item.rarity >= 1:
		var extra: String = STAT_NAMES.keys().pick_random()
		item.stats[extra] = item.stats.get(extra, 0) + mult
	item.item_name = "%s %s" % [BASES[item.slot].pick_random(), PREFIXES.pick_random()]
	return item


static func _roll_rarity(luck_points: int) -> int:
	var weights: Array = []
	var total := 0.0
	for i in RARITIES.size():
		var weight: float = RARITIES[i]["weight"] * (1.0 + 0.1 * luck_points * i)
		weights.append(weight)
		total += weight
	var pick := randf() * total
	for i in weights.size():
		pick -= weights[i]
		if pick <= 0.0:
			return i
	return 0


func color() -> Color:
	return RARITIES[rarity]["color"]


func rarity_name() -> String:
	return RARITIES[rarity]["name"]


func sell_value() -> int:
	var total := 0
	for value in stats.values():
		total += int(value)
	return 5 * (rarity + 1) + total * 2


func stats_text() -> String:
	var parts: Array = []
	for stat in stats:
		parts.append("+%d %s" % [stats[stat], STAT_NAMES[stat]])
	return ", ".join(parts)


func describe() -> String:
	return "%s\n%s · %s\n%s" % [item_name, rarity_name(), SLOT_NAMES[slot], stats_text()]
