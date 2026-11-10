extends Node

## Ajustes do jogo feitos no painel de administração: números dos heróis e dos monstros, chances de drop
## (por raridade e por tipo de espólio) e multiplicadores gerais. Só guarda o que foi mudado em relação
## ao padrão do código; o resto continua como está. Fica salvo em user://ashveil_admin.json.

signal changed

## Hash (SHA-256) da senha do painel. É só uma trava de acesso: quem desmontar o app consegue contorná-la.
const PASSWORD_HASH := "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918"

## Campos editáveis dos heróis e dos monstros: {campo: [nome, mínimo, máximo, passo]}.
const HERO_FIELDS := {
	"health": ["Vida base", 10.0, 2000.0, 1.0],
	"damage": ["Dano base", 1.0, 500.0, 0.5],
	"defense": ["Defesa base", 0.0, 100.0, 0.5],
	"speed": ["Velocidade", 60.0, 400.0, 1.0],
	"energy": ["Energia", 10.0, 500.0, 1.0],
	"interval": ["Intervalo de ataque (s)", 0.1, 3.0, 0.05],
	"range": ["Alcance do ataque", 40.0, 800.0, 5.0],
	"accuracy": ["Precisão", 0.1, 1.0, 0.01],
	"projectile_speed": ["Velocidade do projétil", 0.0, 1500.0, 10.0],
}
const MONSTER_FIELDS := {
	"health": ["Vida", 1.0, 5000.0, 1.0],
	"damage": ["Dano", 0.0, 500.0, 0.5],
	"speed": ["Velocidade", 5.0, 400.0, 1.0],
	"radius": ["Tamanho (raio)", 5.0, 80.0, 0.5],
	"xp": ["XP ao morrer", 0.0, 100.0, 1.0],
	"dodge": ["Esquiva", 0.0, 0.9, 0.01],
	"block": ["Bloqueio", 0.0, 0.9, 0.01],
	"weight": ["Frequência no sorteio", 0.0, 50.0, 0.1],
}
## Chances de drop por monstro morto (0 a 1) e seus padrões (os mesmos do Game).
const DROP_FIELDS := {
	"item": ["Equipamento", 0.04],
	"gold": ["Ouro", 0.10],
	"stone": ["Pedra de forja", 0.05],
	"moonstone": ["Pedra da lua", 0.008],
	"scroll": ["Pergaminho de despertar", 0.003],
	"rune": ["Runa", 0.012],
}
const GLOBAL_FIELDS := {
	"monster_hp": ["Vida dos monstros (x)", 0.1, 10.0, 0.05],
	"monster_dmg": ["Dano dos monstros (x)", 0.1, 10.0, 0.05],
	"monster_speed": ["Velocidade dos monstros (x)", 0.3, 3.0, 0.05],
	"xp": ["XP ganho (x)", 0.1, 10.0, 0.05],
	"gold": ["Ouro ganho (x)", 0.1, 10.0, 0.05],
}

## Os 9 atributos que o herói distribui em pontos, e os nomes deles.
const ATTRIBUTES := ["hp", "defense", "attack", "speed", "luck", "dex", "crit", "aspd", "stamina"]
const ATTRIBUTE_NAMES := {
	"hp": "Vida", "defense": "Defesa", "attack": "Ataque", "speed": "Velocidade", "luck": "Sorte",
	"dex": "Destreza", "crit": "Crítico", "aspd": "Vel. de ataque", "stamina": "Resistência",
}


## Regras gerais dos atributos do herói: {chave: [nome, mínimo, máximo, passo, padrão]}. Os padrões vêm das
## constantes do Player, então o painel mostra sempre o valor original do código.
static func player_fields() -> Dictionary:
	return {
		"hp_per_point": ["Vida por ponto de Vida", 0.0, 200.0, 0.5, Player.HP_PER_POINT],
		"attack_per_point": ["Dano por ponto de Ataque (fração)", 0.0, 1.0, 0.005, Player.ATTACK_PER_POINT],
		"speed_per_point": ["Velocidade por ponto (fração)", 0.0, 0.5, 0.005, Player.SPEED_PER_POINT],
		"aspd_per_point": ["Vel. de ataque por ponto (fração)", 0.0, 0.5, 0.005, Player.ATTACK_SPEED_PER_POINT],
		"crit_per_point": ["Crítico por ponto de Crítico", 0.0, 0.2, 0.001, Player.CRIT_PER_POINT],
		"crit_per_luck": ["Crítico por ponto de Sorte", 0.0, 0.2, 0.001, Player.CRIT_PER_LUCK],
		"crit_per_dex": ["Crítico por ponto de Destreza", 0.0, 0.2, 0.001, Player.CRIT_PER_DEX],
		"dodge_per_dex": ["Esquiva por ponto de Destreza", 0.0, 0.2, 0.001, Player.DODGE_PER_DEX],
		"accuracy_per_dex": ["Precisão por ponto de Destreza", 0.0, 0.2, 0.001, Player.ACCURACY_PER_DEX],
		"xp_per_luck": ["XP por ponto de Sorte", 0.0, 1.0, 0.005, Player.XP_PER_LUCK],
		"drop_per_luck": ["Drops por ponto de Sorte", 0.0, 1.0, 0.005, Player.DROP_PER_LUCK],
		"base_crit": ["Chance de crítico inicial", 0.0, 1.0, 0.01, Player.BASE_CRIT],
		"base_crit_mult": ["Dano do crítico inicial (x)", 1.0, 10.0, 0.05, Player.BASE_CRIT_MULT],
		"max_speed_mult": ["Máximo de velocidade (x)", 1.0, 5.0, 0.05, Player.MAX_SPEED_MULT],
		"max_aspd_mult": ["Máximo de vel. de ataque (x)", 1.0, 8.0, 0.05, Player.MAX_ATTACK_SPEED_MULT],
		"max_dodge": ["Esquiva máxima", 0.0, 0.95, 0.01, Player.MAX_DODGE],
		"max_accuracy": ["Precisão máxima", 0.1, 1.0, 0.01, Player.MAX_ACCURACY],
		"lifesteal_cap": ["Roubo de vida máximo", 0.0, 1.0, 0.005, Player.LIFESTEAL_CAP],
		"max_attribute_points": ["Máximo de pontos gastos por atributo", 1.0, 999.0, 1.0, float(Player.MAX_ATTRIBUTE_POINTS)],
	}


## Valor geral do herói (ver player_fields) com o ajuste por cima.
func player(key: String, base: float) -> float:
	return float(data["player"].get(key, base))


## Pontos iniciais ("base"), mínimo ("min") e máximo ("max") de um atributo do herói.
func attr(stat: String, field: String, base: int) -> int:
	var overrides: Dictionary = data["attrs"].get(stat, {})
	return int(overrides.get(field, base))


## Preço (em diamantes, ou os campos dos pacotes) de um item pago, com o ajuste do painel admin por cima.
func price(id: String, base: float) -> float:
	return float(data["prices"].get(id, base))


func set_price(id: String, value: float, base: float) -> void:
	if is_equal_approx(value, base):
		data["prices"].erase(id)
	else:
		data["prices"][id] = value
	_commit()


func set_player(key: String, value: float) -> void:
	var base := float(player_fields()[key][4])
	if is_equal_approx(value, base):
		data["player"].erase(key)
	else:
		data["player"][key] = value
	_commit()


func set_attr(stat: String, field: String, value: int) -> void:
	var default := {"base": 0, "min": 0, "max": 100}
	var entry: Dictionary = data["attrs"].get(stat, {})
	if value == int(default[field]):
		entry.erase(field)
	else:
		entry[field] = value
	if entry.is_empty():
		data["attrs"].erase(stat)
	else:
		data["attrs"][stat] = entry
	_commit()


var save_enabled := true
var save_path := "user://ashveil_admin.json"
var unlocked := false
## Modo de teste do admin: compras de pacotes de diamantes entregam de graça (só com o painel liberado).
var test_purchases := true
## Só o que foi alterado: {"heroes": {id: {campo: valor}}, "monsters": {...}, "rarity": {"0": peso},
## "drops": {chave: valor}, "global": {chave: valor}}.
var data := {"heroes": {}, "monsters": {}, "rarity": {}, "drops": {}, "global": {}, "player": {}, "attrs": {}, "prices": {}}
var _hero_cache := {}
var _monster_cache := {}


func _ready() -> void:
	load_data()


func check_password(text: String) -> bool:
	return text.sha256_text() == PASSWORD_HASH


## Dados de um herói com os ajustes por cima (uma cópia; os do código ficam intactos).
func hero(id: String, base: Dictionary) -> Dictionary:
	var overrides: Dictionary = data["heroes"].get(id, {})
	if overrides.is_empty():
		return base
	if not _hero_cache.has(id):
		var merged := base.duplicate()
		for field in overrides:
			merged[field] = overrides[field]
		_hero_cache[id] = merged
	return _hero_cache[id]


func monster(kind: String, base: Dictionary) -> Dictionary:
	var overrides: Dictionary = data["monsters"].get(kind, {})
	if overrides.is_empty():
		return base
	if not _monster_cache.has(kind):
		var merged := base.duplicate()
		for field in overrides:
			merged[field] = overrides[field]
		_monster_cache[kind] = merged
	return _monster_cache[kind]


func rarity_weight(index: int, base: float) -> float:
	return float(data["rarity"].get(str(index), base))


func drop(key: String, base: float) -> float:
	return float(data["drops"].get(key, base))


func glob(key: String, base := 1.0) -> float:
	return float(data["global"].get(key, base))


# --- Edição ------------------------------------------------------------------------------------

func set_hero_field(id: String, field: String, value: float) -> void:
	_set_override("heroes", id, field, value, float(Heroes.DATA[id].get(field, value)))


func set_monster_field(kind: String, field: String, value: float) -> void:
	_set_override("monsters", kind, field, value, float(EnemyTypes.DATA[kind].get(field, 0.0)))


func set_rarity_weight(index: int, value: float) -> void:
	data["rarity"][str(index)] = value
	_commit()


func set_drop(key: String, value: float) -> void:
	data["drops"][key] = value
	_commit()


func set_global(key: String, value: float) -> void:
	data["global"][key] = value
	_commit()


func _set_override(group: String, id: String, field: String, value: float, base: float) -> void:
	var entry: Dictionary = data[group].get(id, {})
	if is_equal_approx(value, base):
		entry.erase(field)
	else:
		entry[field] = value
	if entry.is_empty():
		data[group].erase(id)
	else:
		data[group][id] = entry
	_commit()


func reset_all() -> void:
	data = {"heroes": {}, "monsters": {}, "rarity": {}, "drops": {}, "global": {}, "player": {}, "attrs": {}, "prices": {}}
	_commit()


func reset_group(group: String) -> void:
	data[group] = {}
	_commit()


func _commit() -> void:
	_hero_cache.clear()
	_monster_cache.clear()
	save_data()
	changed.emit()


# --- Disco -------------------------------------------------------------------------------------

func save_data() -> void:
	if not save_enabled:
		return
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))


func load_data() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not (parsed is Dictionary):
		return
	for group in data:
		var saved = parsed.get(group, {})
		if saved is Dictionary:
			data[group] = saved
	_hero_cache.clear()
	_monster_cache.clear()
