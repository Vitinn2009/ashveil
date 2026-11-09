class_name EnemyTypes
extends RefCounted

## Catálogo dos inimigos. Cada tipo tem uma característica própria,
## implementada em Enemy (ver `kind`). `from` é o segundo em que o tipo
## começa a aparecer e `weight` o peso relativo no sorteio.
## Tipos com `minion` não entram no sorteio: só são invocados por outros inimigos.

const DATA := {
	"slime": {
		"name": "Gosma",
		"trait": "Ao morrer, se divide em quatro gosminhas.",
		"color": Color("5fbf6a"),
		"radius": 15.0, "health": 24.0, "speed": 48.0, "damage": 6.0, "xp": 1,
		"from": 0.0, "weight": 10.0,
	},
	"bat": {
		"name": "Morcego",
		"trait": "Voa em zigue-zague e é muito rápido, mas frágil. Esquiva de 1 em cada 4 golpes.",
		"color": Color("8a5fc9"),
		"radius": 10.0, "health": 11.0, "speed": 125.0, "damage": 4.0, "xp": 1, "dodge": 0.25,
		"from": 25.0, "weight": 5.0,
	},
	"skeleton": {
		"name": "Esqueleto Arqueiro",
		"trait": "Mantém distância e atira ossos de longe. Bloqueia com o escudo de osso.",
		"color": Color("e8e2d0"),
		"radius": 14.0, "health": 20.0, "speed": 62.0, "damage": 5.0, "xp": 2, "block": 0.2,
		"from": 50.0, "weight": 4.0,
	},
	"spider": {
		"name": "Aranha Venenosa",
		"trait": "Mantém distância e cospe teias que deixam o herói lento.",
		"color": Color("4d2a63"),
		"radius": 13.0, "health": 22.0, "speed": 72.0, "damage": 5.0, "xp": 2,
		"from": 55.0, "weight": 3.5,
	},
	"bomber": {
		"name": "Bomba-viva",
		"trait": "Corre até você e explode em área depois de uma contagem.",
		"color": Color("3a3a4a"),
		"radius": 13.0, "health": 14.0, "speed": 88.0, "damage": 0.0, "xp": 2,
		"from": 75.0, "weight": 3.0,
	},
	"wolf": {
		"name": "Lobo Selvagem",
		"trait": "Avisa e depois dá uma investida rápida em linha reta. Esquiva de vez em quando.",
		"color": Color("8a919e"),
		"radius": 14.0, "health": 34.0, "speed": 80.0, "damage": 11.0, "xp": 3, "dodge": 0.12,
		"from": 85.0, "weight": 3.0,
	},
	"brute": {
		"name": "Bruto",
		"trait": "Enorme e resistente: reduz 25% do dano, bloqueia golpes e ignora empurrões.",
		"color": Color("a8452a"),
		"radius": 26.0, "health": 120.0, "speed": 36.0, "damage": 14.0, "xp": 5, "block": 0.3,
		"from": 100.0, "weight": 2.5,
		"knockback_immune": true, "damage_taken_mult": 0.75,
	},
	"ghost": {
		"name": "Fantasma",
		"trait": "Alterna entre sólido e etéreo; etéreo, ignora todo dano.",
		"color": Color("cfe6ff"),
		"radius": 15.0, "health": 26.0, "speed": 62.0, "damage": 7.0, "xp": 3,
		"from": 115.0, "weight": 2.5,
	},
	"mushroom": {
		"name": "Cogumelo Tóxico",
		"trait": "Solta nuvens venenosas pelo caminho e uma grande ao morrer.",
		"color": Color("8a62b8"),
		"radius": 19.0, "health": 55.0, "speed": 34.0, "damage": 6.0, "xp": 3,
		"from": 130.0, "weight": 2.5,
	},
	"necromancer": {
		"name": "Necromante",
		"trait": "Mantém distância e invoca caveirinhas a cada poucos segundos.",
		"color": Color("3b2a5a"),
		"radius": 15.0, "health": 40.0, "speed": 55.0, "damage": 4.0, "xp": 5,
		"from": 150.0, "weight": 2.0,
	},
	"thief": {
		"name": "Ladrão de Ouro",
		"trait": "Rouba seu ouro ao encostar e foge, esquivando-se. Mate-o para recuperar tudo, com juros.",
		"color": Color("c9a24a"),
		"radius": 12.0, "health": 26.0, "speed": 112.0, "damage": 2.0, "xp": 3, "dodge": 0.2,
		"from": 30.0, "weight": 2.5,
	},
	"mimic": {
		"name": "Mímico",
		"trait": "Finge ser um tesouro no chão. Quando você chega perto, morde, e a tampa bloqueia golpes. Solta muito loot.",
		"color": Color("8a5a2a"),
		"radius": 16.0, "health": 70.0, "speed": 125.0, "damage": 13.0, "xp": 6, "block": 0.15,
		"from": 60.0, "weight": 1.6,
	},
	"totem": {
		"name": "Totem Curandeiro",
		"trait": "Cura e protege os monstros por perto com pulsos. Derrube-o primeiro.",
		"color": Color("4fbf8a"),
		"radius": 17.0, "health": 60.0, "speed": 26.0, "damage": 0.0, "xp": 6,
		"from": 90.0, "weight": 1.8,
		"knockback_immune": true,
	},
	"shade": {
		"name": "Sombra",
		"trait": "Some e reaparece nas suas costas, avisa e golpeia. Esquiva às vezes.",
		"color": Color("2b2342"),
		"radius": 14.0, "health": 38.0, "speed": 78.0, "damage": 12.0, "xp": 5, "dodge": 0.15,
		"from": 110.0, "weight": 2.0,
	},
	"vortex": {
		"name": "Vórtice",
		"trait": "Cria um poço de gravidade que puxa o herói para perto da horda.",
		"color": Color("7a5ad8"),
		"radius": 18.0, "health": 50.0, "speed": 38.0, "damage": 5.0, "xp": 6,
		"from": 120.0, "weight": 1.6,
		"knockback_immune": true,
	},
	"frost": {
		"name": "Fada do Gelo",
		"trait": "Mantém distância e atira estilhaços de gelo que congelam o herói: ele quase para por alguns segundos.",
		"color": Color("8fe3ff"),
		"radius": 14.0, "health": 30.0, "speed": 58.0, "damage": 4.0, "xp": 4,
		"from": 140.0, "weight": 2.0,
	},
	"golem": {
		"name": "Golem Sísmico",
		"trait": "Lento e enorme: bate o punho no chão, marca a área e solta uma onda de choque que machuca e atrasa.",
		"color": Color("8a8478"),
		"radius": 24.0, "health": 130.0, "speed": 30.0, "damage": 12.0, "xp": 6,
		"from": 160.0, "weight": 1.6,
		"knockback_immune": true,
	},
	"imp": {
		"name": "Diabrete",
		"trait": "Rápido e brincalhão: deixa um rastro de brasas queimando o chão por onde passa.",
		"color": Color("ff6a2a"),
		"radius": 12.0, "health": 22.0, "speed": 95.0, "damage": 5.0, "xp": 3,
		"from": 70.0, "weight": 2.5,
	},
	"vampire": {
		"name": "Conde Sanguessuga",
		"trait": "Cura-se com o sangue de quem fere: cada mordida devolve parte da vida dele.",
		"color": Color("9c1f3a"),
		"radius": 14.0, "health": 42.0, "speed": 82.0, "damage": 9.0, "xp": 5,
		"from": 170.0, "weight": 1.8,
	},
	"illusionist": {
		"name": "Ilusionista",
		"trait": "Some num pufe de fumaça, reaparece em outro lugar e deixa caveirinhas de isca no lugar de onde saiu.",
		"color": Color("d46bd8"),
		"radius": 14.0, "health": 36.0, "speed": 60.0, "damage": 4.0, "xp": 5, "dodge": 0.1,
		"from": 180.0, "weight": 1.6,
	},
	"storm": {
		"name": "Elemental do Trovão",
		"trait": "Marca o chão sob os seus pés e chama uma sequência de raios depois de um instante. Ande sem parar.",
		"color": Color("ffe85a"),
		"radius": 15.0, "health": 44.0, "speed": 50.0, "damage": 4.0, "xp": 6,
		"from": 200.0, "weight": 1.6,
	},
	"hedgehog": {
		"name": "Ouriço Espinhoso",
		"trait": "Resistente e teimoso: cada vez que perde um quarto da vida, dispara espinhos para todos os lados.",
		"color": Color("8a6a4a"),
		"radius": 17.0, "health": 80.0, "speed": 44.0, "damage": 8.0, "xp": 4, "block": 0.15,
		"from": 100.0, "weight": 2.0,
	},
	"banshee": {
		"name": "Banshee",
		"trait": "Respira fundo e solta um grito que empurra o herói para longe, atrasa e machuca.",
		"color": Color("e6e6ff"),
		"radius": 15.0, "health": 38.0, "speed": 52.0, "damage": 4.0, "xp": 5,
		"from": 190.0, "weight": 1.6,
	},
	"gargoyle": {
		"name": "Gárgula",
		"trait": "Vira pedra e quase não sofre dano; depois acorda e mergulha rápido sobre você.",
		"color": Color("6e7280"),
		"radius": 18.0, "health": 70.0, "speed": 70.0, "damage": 11.0, "xp": 6,
		"from": 210.0, "weight": 1.5,
		"knockback_immune": true,
	},
	"worm": {
		"name": "Verme das Dunas",
		"trait": "Mergulha na terra, fica intocável e corre por baixo até você, então explode do chão em área.",
		"color": Color("c99a5a"),
		"radius": 17.0, "health": 60.0, "speed": 66.0, "damage": 10.0, "xp": 6,
		"from": 220.0, "weight": 1.4,
	},
	"skull": {
		"name": "Caveirinha",
		"trait": "Invocada pelo necromante: rápida e frágil, não solta nada.",
		"color": Color("efe8d8"),
		"radius": 9.0, "health": 8.0, "speed": 100.0, "damage": 4.0, "xp": 0,
		"from": 99999.0, "weight": 0.0,
		"minion": true, "loot": false,
	},
}


static func get_type(kind: String) -> Dictionary:
	return DATA[kind]


## Tipos que podem aparecer no sorteio (sem as criaturas invocadas).
static func spawnable_kinds() -> Array:
	var kinds: Array = []
	for kind in DATA:
		if not DATA[kind].get("minion", false):
			kinds.append(kind)
	return kinds


## Quantos nascem juntos: bandos de morcegos e duplas de lobos e ladrões deixam a tela mais viva
## com menos sorteios.
const PACKS := {"bat": 3, "wolf": 2, "slime": 2}


static func pack_size(kind: String) -> int:
	return int(PACKS.get(kind, 1))


## Sorteia um tipo pelo peso. Sem `allowed`, só entram os que já apareceram no segundo `elapsed`;
## com `allowed` (os tipos já liberados da fase), sorteia entre eles, sem olhar o tempo.
static func pick(elapsed: float, allowed: Array = []) -> String:
	var kinds: Array = allowed if not allowed.is_empty() else spawnable_kinds()
	var by_time := allowed.is_empty()
	var total := 0.0
	for kind in kinds:
		if not by_time or DATA[kind]["from"] <= elapsed:
			total += DATA[kind]["weight"]
	var roll := randf() * total
	for kind in kinds:
		if by_time and DATA[kind]["from"] > elapsed:
			continue
		roll -= DATA[kind]["weight"]
		if roll <= 0.0:
			return kind
	return kinds[0] if not kinds.is_empty() else "slime"
