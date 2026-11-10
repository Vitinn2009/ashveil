class_name Heroes
extends RefCounted

## Catálogo dos heróis jogáveis. `attack` define o estilo de ataque:
## "magic" e "arrow" disparam projéteis, "melee" golpeia em leque à frente e
## "blunderbuss" dispara 4 fragmentos de uma vez.
## `accuracy` é a chance de o golpe básico acertar (Destreza aumenta). `unlock` é a habilidade que só é liberada no nível indicado.

const UNLOCK_LEVEL := 20

const DATA := {
	"mage": {
		"id": "mage",
		"name": "Mago",
		"title": "Mestre dos elementos",
		"description": "Frágil, mas domina três magias. Ataca de longe com projéteis arcanos.",
		"art": "res://assets/characters/mage.svg",
		"color": Color("8a6bff"),
		"attack": "magic",
		"health": 70.0,
		"energy": 140.0,
		"speed": 162.0,
		"defense": 0.0,
		"damage": 14.0,
		"interval": 0.75,
		"accuracy": 0.8,
		"range": 340.0,
		"projectile_speed": 440.0,
		"projectile_color": Color("6ec6ff"),
		"skills": ["freeze", "fire", "wind"],
		"unlock": {"id": "lightning", "level": UNLOCK_LEVEL},
		"bag_bonus": 0,
		"base_luck": 0,
		"base_dex": 1,
	},
	"archer": {
		"id": "archer",
		"name": "Arqueiro",
		"title": "Atirador veloz",
		"description": "Ágil e preciso. Suas flechas atravessam o primeiro inimigo.",
		"art": "res://assets/characters/archer.svg",
		"color": Color("5fae6e"),
		"attack": "arrow",
		"health": 95.0,
		"energy": 100.0,
		"speed": 146.0,
		"max_speed": 186.0,
		"defense": 2.0,
		"damage": 11.0,
		"interval": 0.9,
		"accuracy": 0.62,
		"range": 380.0,
		"projectile_speed": 660.0,
		"projectile_color": Color("f4e9d8"),
		"skills": ["double", "haste"],
		"unlock": {"id": "fire_arrows", "level": UNLOCK_LEVEL},
		"bag_bonus": 0,
		"base_luck": 0,
	},
	"warrior": {
		"id": "warrior",
		"name": "Guerreiro",
		"title": "Muralha de aço",
		"description": "Resistente e corpo a corpo. Golpeia só à frente, na direção em que anda: quanto mais perto do inimigo, mais dano.",
		"art": "res://assets/characters/warrior.svg",
		"color": Color("c4ccd8"),
		"attack": "melee",
		"health": 150.0,
		"energy": 90.0,
		"speed": 167.0,
		"defense": 6.0,
		"damage": 18.0,
		"interval": 0.7,
		"accuracy": 0.88,
		"range": 100.0,
		"projectile_speed": 0.0,
		"projectile_color": Color("e8edf5"),
		"skills": ["slash", "shield"],
		"unlock": {"id": "ground_slam", "level": UNLOCK_LEVEL},
		"bag_bonus": 0,
		"base_luck": 0,
	},
	"gnome": {
		"id": "gnome",
		"name": "Gnomo",
		"title": "Velho engenheiro pirata",
		"description": "Lento, mas cheio de ferramentas. Seu bacamarte solta 4 fragmentos, a mochila carrega mais itens e a sorte é maior.",
		"art": "res://assets/characters/gnome.svg",
		"color": Color("c9954a"),
		"attack": "blunderbuss",
		"health": 85.0,
		"energy": 110.0,
		"speed": 135.0,
		"defense": 1.0,
		"damage": 7.0,
		"interval": 0.9,
		"accuracy": 0.7,
		"range": 290.0,
		"projectile_speed": 560.0,
		"projectile_color": Color("f4d58a"),
		"skills": ["bomb", "paralysis"],
		"unlock": {"id": "bomb_rain", "level": UNLOCK_LEVEL},
		"bag_bonus": 8,
		"base_luck": 3,
	},
}


static func ids() -> Array:
	return ["mage", "archer", "warrior", "gnome"]


static func get_hero(id: String) -> Dictionary:
	return Tuning.hero(id, DATA.get(id, DATA["warrior"]))


## As habilidades iniciais do herói em ordem: as liberadas desde o começo e, por último, a que destrava
## no nível 20. Cada entrada: {id, unlock_level}.
static func default_entries(hero: Dictionary) -> Array:
	var entries: Array = []
	for id in hero["skills"]:
		entries.append({"id": id, "unlock_level": 0})
	var unlock: Dictionary = hero["unlock"]
	entries.append({"id": unlock["id"], "unlock_level": unlock["level"]})
	return entries


## As casas de habilidade da partida, com o que o jogador equipou em cada uma (aba Habilidades). A trava
## de cada casa é a da posição dela: fase 2, 3... e a última, nível 20.
static func skill_entries(hero: Dictionary) -> Array:
	var entries := default_entries(hero)
	var hero_id: String = hero.get("id", "")
	if hero_id == "":
		return entries
	var loadout: Array = Session.loadout_for(hero_id)
	for i in entries.size():
		entries[i]["id"] = loadout[i]
	return entries


## Todas as habilidades que o herói pode equipar: as iniciais, a do nível 20 e as 6 do segundo leque.
static func skill_pool(hero: Dictionary) -> Array:
	var pool: Array = []
	for entry in default_entries(hero):
		pool.append(entry["id"])
	for id in SkillsExtra.for_hero(hero.get("id", "")):
		pool.append(id)
	return pool


## Nível mínimo do herói para usar a habilidade: o do segundo leque, ou o da habilidade de nível 20.
static func skill_req(hero: Dictionary, id: String) -> int:
	if SkillsExtra.DEFS.has(id):
		return int(SkillsExtra.DEFS[id]["req"])
	var unlock: Dictionary = hero["unlock"]
	return int(unlock["level"]) if unlock["id"] == id else 0
