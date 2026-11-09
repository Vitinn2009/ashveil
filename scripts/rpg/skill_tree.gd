class_name SkillTree
extends RefCounted

## Árvore de habilidades de cada herói (pontos de habilidade ganhos a cada nível). Uma raiz leva a 4 ramos
## de 4 nós em fila; cada nó tem até 5 níveis. Os 4 nós finais abrem o Mestre e o Mestre no máximo abre o
## Herói. Cada nível de um nó soma pontos de um atributo, como os equipamentos (ver Player.tree_bonus).

const MAX_LEVEL := 5
const BRANCHES := 4
const TIERS := 4
const MASTER_COST := 5
const HERO_COST := 8
const STAT_COLORS := {
	"attack": Color("ff9a3a"), "crit": Color("ff5a4a"), "critdmg": Color("c9302c"), "hp": Color("ec6a78"),
	"defense": Color("4aa3ff"), "speed": Color("5fd0c8"), "aspd": Color("f2d24a"), "luck": Color("7ee08a"),
	"dex": Color("b8e04a"), "stamina": Color("e8c64a"), "skill_power": Color("b36bff"),
	"skill_range": Color("6ec6ff"), "lifesteal": Color("d02050"), "reflect": Color("c8d0dc"),
}
const STAT_NAMES := {
	"attack": "Ataque", "crit": "Crítico", "critdmg": "Dano crítico", "hp": "Vida", "defense": "Defesa",
	"speed": "Vel. de movimento", "aspd": "Vel. de ataque", "luck": "Sorte", "dex": "Destreza",
	"stamina": "Resistência", "skill_power": "Poder das habilidades", "skill_range": "Alcance das habilidades",
	"lifesteal": "Roubo de vida", "reflect": "Refletir",
}
## Por herói: a raiz, os 4 ramos (nome e 4 nós [nome, atributo, pontos por nível]), o Mestre e o Herói.
const TREES := {
	"mage": {
		"root": ["Chama Interior", "hp", 3],
		"branches": [
			["Arcano", [["Poder Arcano", "attack", 1], ["Raio Concentrado", "crit", 1], ["Fúria Mística", "critdmg", 1], ["Tempestade", "skill_power", 1]]],
			["Elementos", [["Fogo Vivo", "attack", 1], ["Gelo Eterno", "skill_range", 1], ["Vento Veloz", "aspd", 1], ["Trovão", "crit", 1]]],
			["Proteção", [["Barreira", "defense", 1], ["Vitalidade Arcana", "hp", 3], ["Manto de Energia", "stamina", 2], ["Escudo Espelhado", "reflect", 1]]],
			["Sabedoria", [["Foco", "dex", 1], ["Sorte do Estudioso", "luck", 1], ["Passo Leve", "speed", 1], ["Sifão de Vida", "lifesteal", 1]]],
		],
		"master": ["Mestre dos Elementos", {"attack": 2, "defense": 1, "hp": 4}],
		"hero": ["Herói Arcano", {"attack": 3, "crit": 1, "aspd": 1, "critdmg": 1}],
	},
	"archer": {
		"root": ["Olhar Atento", "dex", 1],
		"branches": [
			["Precisão", [["Mira Firme", "dex", 1], ["Olho de Águia", "crit", 1], ["Tiro Mortal", "critdmg", 1], ["Chuva de Flechas", "skill_power", 1]]],
			["Agilidade", [["Passo Leve", "speed", 1], ["Disparo Rápido", "aspd", 1], ["Fôlego", "stamina", 2], ["Esquiva", "dex", 1]]],
			["Caça", [["Presa", "attack", 1], ["Rastreador", "luck", 1], ["Veneno", "lifesteal", 1], ["Armadilha", "skill_range", 1]]],
			["Sobrevivência", [["Couro Reforçado", "defense", 1], ["Vigor", "hp", 3], ["Camuflagem", "reflect", 1], ["Instinto", "crit", 1]]],
		],
		"master": ["Mestre Arqueiro", {"dex": 2, "crit": 1, "hp": 4}],
		"hero": ["Herói da Floresta", {"attack": 3, "dex": 2, "aspd": 1, "critdmg": 1}],
	},
	"warrior": {
		"root": ["Coração de Aço", "hp", 3],
		"branches": [
			["Força", [["Golpe Pesado", "attack", 1], ["Lâmina Afiada", "critdmg", 1], ["Ira", "attack", 1], ["Fúria de Batalha", "aspd", 1]]],
			["Muralha", [["Pele de Ferro", "defense", 1], ["Corpo Robusto", "hp", 3], ["Postura Firme", "defense", 1], ["Contra-ataque", "reflect", 1]]],
			["Fúria", [["Olho do Guerreiro", "crit", 1], ["Sede de Sangue", "lifesteal", 1], ["Frenesi", "aspd", 1], ["Pancada Sísmica", "skill_power", 1]]],
			["Resistência", [["Fôlego de Ferro", "stamina", 2], ["Vitalidade", "hp", 3], ["Couraça", "defense", 1], ["Marcha Forçada", "speed", 1]]],
		],
		"master": ["Mestre de Armas", {"attack": 2, "defense": 2, "hp": 4}],
		"hero": ["Herói de Aço", {"attack": 3, "defense": 2, "crit": 1, "lifesteal": 1}],
	},
	"gnome": {
		"root": ["Mente Inventiva", "luck", 1],
		"branches": [
			["Engenharia", [["Bacamarte Reforçado", "attack", 1], ["Pólvora Pura", "skill_power", 1], ["Alcance Extra", "skill_range", 1], ["Detonação", "skill_power", 1]]],
			["Fortuna", [["Faro de Tesouro", "luck", 1], ["Olhos de Gnomo", "luck", 1], ["Mão Leve", "dex", 1], ["Golpe de Sorte", "crit", 1]]],
			["Mochilão", [["Fôlego", "stamina", 2], ["Corpo Compacto", "hp", 3], ["Capa Grossa", "defense", 1], ["Passinhos", "speed", 1]]],
			["Explosivos", [["Estopim Curto", "attack", 1], ["Estilhaços", "critdmg", 1], ["Recarga Rápida", "aspd", 1], ["Remédio Caseiro", "lifesteal", 1]]],
		],
		"master": ["Mestre Artífice", {"attack": 2, "luck": 2, "hp": 4}],
		"hero": ["Herói Pirata", {"attack": 3, "luck": 2, "crit": 1, "aspd": 1}],
	},
}


## Todos os nós do herói: raiz, 16 nós dos ramos, mestre e herói. Cada um tem
## id, name, stat/per (efeito por nível), tier (1 a 4, 0 raiz), branch (-1 fora dos ramos), requires (ids).
static func nodes(hero: String) -> Array:
	var tree: Dictionary = TREES.get(hero, TREES["warrior"])
	var list: Array = []
	list.append({"id": "root", "name": tree["root"][0], "bonus": {tree["root"][1]: tree["root"][2]}, "tier": 0, "branch": -1, "requires": [], "base_cost": 1})
	var last_ids: Array = []
	for b in BRANCHES:
		var previous := "root"
		for t in TIERS:
			var data: Array = tree["branches"][b][1][t]
			var id := "b%d_%d" % [b, t + 1]
			list.append({"id": id, "name": data[0], "bonus": {data[1]: data[2]}, "tier": t + 1, "branch": b, "requires": [previous], "base_cost": t + 1})
			previous = id
		last_ids.append(previous)
	list.append({"id": "master", "name": tree["master"][0], "bonus": tree["master"][1], "tier": 5, "branch": -1, "requires": last_ids, "base_cost": MASTER_COST})
	list.append({"id": "hero", "name": tree["hero"][0], "bonus": tree["hero"][1], "tier": 6, "branch": -1, "requires": ["master"], "base_cost": HERO_COST})
	return list


static func node(hero: String, id: String) -> Dictionary:
	for entry in nodes(hero):
		if entry["id"] == id:
			return entry
	return {}


static func branch_name(hero: String, branch: int) -> String:
	return str(TREES.get(hero, TREES["warrior"])["branches"][branch][0])


## Pontos para subir o nó do nível `level` ao seguinte.
static func cost(entry: Dictionary, level: int) -> int:
	return int(entry["base_cost"]) if level < MAX_LEVEL else 0


## O nó está liberado? Os ramos pedem o nó anterior com 1 nível; o Mestre pede os 4 nós finais; o Herói
## pede o Mestre no máximo.
static func unlocked(hero: String, id: String, levels: Dictionary) -> bool:
	var entry := node(hero, id)
	if entry.is_empty():
		return false
	for requirement in entry["requires"]:
		var needed := MAX_LEVEL if id == "hero" else 1
		if int(levels.get(requirement, 0)) < needed:
			return false
	return true


## Atributos somados por todos os níveis da árvore.
static func bonus(hero: String, levels: Dictionary) -> Dictionary:
	var total := {}
	for entry in nodes(hero):
		var level := clampi(int(levels.get(entry["id"], 0)), 0, MAX_LEVEL)
		if level <= 0:
			continue
		for stat in entry["bonus"]:
			total[stat] = int(total.get(stat, 0)) + int(entry["bonus"][stat]) * level
	return total


static func bonus_text(entry: Dictionary, level := 1) -> String:
	var parts: Array = []
	for stat in entry["bonus"]:
		var suffix := "%" if stat == "lifesteal" or stat == "reflect" else ""
		parts.append("+%d%s %s" % [int(entry["bonus"][stat]) * level, suffix, STAT_NAMES.get(stat, stat)])
	return ", ".join(parts)


static func color_of(entry: Dictionary) -> Color:
	for stat in entry["bonus"]:
		return STAT_COLORS.get(stat, Color.WHITE)
	return Color.WHITE
