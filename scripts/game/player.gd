class_name Player
extends Node2D

signal health_changed(current: float, maximum: float)
signal died
## O herói levou dano (já descontados defesa e escudo) ou esquivou do golpe.
signal hit_taken(amount: float)
signal dodged

const HP_PER_POINT := 12.0
const ATTACK_PER_POINT := 0.08
const SPEED_PER_POINT := 0.03
const ATTACK_SPEED_PER_POINT := 0.04
## Com até 100 pontos por atributo, a velocidade para de crescer em 2,5x o movimento e 3x o ataque.
const MAX_SPEED_MULT := 2.0
## Teto de velocidade de movimento dos heróis sem "max_speed" próprio.
const DEFAULT_MAX_SPEED := 232.0
const MAX_ATTACK_SPEED_MULT := 3.0
## Atributos do popup: crítico, acerto (Destreza) e vitalidade.
const CRIT_PER_POINT := 0.015
const ACCURACY_PER_DEX := 0.02
const MAX_ACCURACY := 0.97
const STAMINA_BASE := 100.0
const STAMINA_PER_POINT := 12.0
const STAMINA_DRAIN := 7.0
## Cada ponto de Resistência alivia 4% do gasto de vitalidade ao correr (no máximo 50%).
const STAMINA_RELIEF_PER_POINT := 0.04
const STAMINA_REGEN := 15.0
## Abaixo desta fração da vitalidade o herói começa a ficar lento; vazia, anda a 60% (queda de 40%).
const FATIGUE_START := 0.5
const FATIGUE_MIN_SPEED := 0.6
const XP_PER_LUCK := 0.08
const DROP_PER_LUCK := 0.10
const SPRITE_SCALE := 0.52
const SPRITE_BASE_Y := -24.0
## Limite de pontos gastos em cada atributo do herói.
const MAX_ATTRIBUTE_POINTS := 100
## Limite do total de um atributo, somando equipamentos.
const MAX_TOTAL_POINTS := 100
## Limite de pontos em cada atributo de habilidade.
const MAX_SKILL_POINTS := 5
const SKILL_RANGE_PER_POINT := 0.10
const SKILL_ECHO_PER_POINT := 0.10
const SKILL_COOLDOWN_PER_POINT := 0.05
const SKILL_POWER_PER_POINT := 0.12
## Energia: gasta pelas habilidades e recuperada com o tempo.
const ENERGY_REGEN := 6.0
const BASE_CRIT := 0.05
const CRIT_PER_LUCK := 0.01
## Destreza: cada ponto dá +1,2% de crítico e +1% de esquiva (esquiva máxima de 40%).
const CRIT_PER_DEX := 0.012
const DODGE_PER_DEX := 0.01
const MAX_DODGE := 0.4
## Contra ataques de perto o herói desvia com metade da chance.
const MELEE_DODGE_FACTOR := 0.5
const LIFESTEAL_PER_POINT := 0.004
const LIFESTEAL_CAP := 0.06
## Teto de cura por golpe (fração da vida máxima).
const LIFESTEAL_HIT_CAP := 0.02
## Raio do mapa (px) a partir do centro: o herói não passa dele.
const MAP_RADIUS := 1900.0
const BASE_CRIT_MULT := 1.3
const FOOD_ATTACK_BONUS := 1.25

var hero_id := "warrior"
var hero: Dictionary
var inventory := Inventory.new()
## Pontos permanentes do herói, escolhidos no popup que abre a cada 5 níveis (ver Session).
var attributes := {"hp": 0, "defense": 0, "attack": 0, "speed": 0, "luck": 0, "dex": 0, "crit": 0, "aspd": 0, "stamina": 0}
## Atributos que o pet ativo dá (ver Pets). Somam aos pontos e aos equipamentos.
var pet_stats := {}
## Bônus da evolução do herói (ver Evolution): pontos de atributo e reforço das habilidades.
var evolution_bonus := {}
## Bônus da árvore de habilidades (ver SkillTree).
var tree_bonus := {}
## Nível (0 a 5) de cada habilidade ativa do herói (ver Skills.MAX_LEVEL).
var skill_levels := {}
## Vitalidade: gasta ao correr, volta parado. Vazia, a velocidade de movimento cai até 40%.
var stamina := STAMINA_BASE
## Pontos distribuídos a cada 10 níveis: alcance, x2 (eco), recarga e poder das habilidades.
var skill_attributes := {"range": 0, "echo": 0, "cooldown": 0, "power": 0}
var card_health := 0.0
var card_speed_mult := 1.0
var card_crit := 0.0
var card_crit_mult := 0.0
## Bônus de acerto das melhorias (a carta Mira firme).
var accuracy_bonus := 0.0
var pickup_radius := 80.0
var radius := 16.0
var health := 0.0
var max_health := 1.0
var facing := Vector2.RIGHT
var double_time := 0.0
var haste_time := 0.0
var shield_time := 0.0
var shield_hp := 0.0
var energy := 0.0
## Bônus da Sopa de cogumelo (velocidade de ataque).
var attack_buff_time := 0.0
## Teia da aranha: deixa o herói mais lento por um tempo.
var slow_time := 0.0
var slow_factor := 1.0
var joystick: TouchJoystick
var _dead := false
var _sprite: Sprite2D
var _clock := 0.0
var _hurt_flash := 0.0
var _pull := Vector2.ZERO


func _ready() -> void:
	hero = Heroes.get_hero(hero_id)
	_sprite = Sprite2D.new()
	_sprite.texture = load(hero["art"])
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	_sprite.position = Vector2(0, SPRITE_BASE_Y)
	add_child(_sprite)
	inventory.changed.connect(refresh_stats)
	inventory.recalc_capacity(int(hero.get("bag_bonus", 0)))
	refresh_stats()
	health = max_health
	energy = get_max_energy()
	health_changed.emit(health, max_health)


## Pontos do atributo: gastos + equipamentos (+ a sorte própria do herói), com limite.
func stat_points(stat: String) -> int:
	var total := int(attributes[stat]) + inventory.bonus(stat)
	total += int(hero.get("base_" + stat, 0)) + int(pet_stats.get(stat, 0)) + int(evolution_bonus.get(stat, 0)) + int(tree_bonus.get(stat, 0))
	return clampi(total, 0, MAX_TOTAL_POINTS)


func get_max_energy() -> float:
	return hero["energy"]


## Gasta energia de uma habilidade. Devolve false (e não gasta) se faltar energia.
func spend_energy(cost: float) -> bool:
	if energy < cost:
		return false
	energy -= cost
	return true


func apply_slow(factor: float, duration: float) -> void:
	slow_factor = factor
	slow_time = maxf(slow_time, duration)


func get_points(group: String, stat: String) -> int:
	var source: Dictionary = skill_attributes if group == "skill" else attributes
	return int(source[stat])


func can_add_point(group: String, stat: String) -> bool:
	var cap := MAX_SKILL_POINTS if group == "skill" else MAX_ATTRIBUTE_POINTS
	return get_points(group, stat) < cap


func add_point(group: String, stat: String) -> bool:
	if not can_add_point(group, stat):
		return false
	if group == "skill":
		skill_attributes[stat] = int(skill_attributes[stat]) + 1
	else:
		attributes[stat] = int(attributes[stat]) + 1
	refresh_stats()
	return true


func skill_range_mult() -> float:
	return 1.0 + (int(skill_attributes["range"]) + int(evolution_bonus.get("skill_range", 0)) + int(tree_bonus.get("skill_range", 0))) * SKILL_RANGE_PER_POINT


func skill_echo_chance() -> float:
	return int(skill_attributes["echo"]) * SKILL_ECHO_PER_POINT


func skill_cooldown_mult() -> float:
	return 1.0 - int(skill_attributes["cooldown"]) * SKILL_COOLDOWN_PER_POINT


func skill_power_mult() -> float:
	return 1.0 + (int(skill_attributes["power"]) + int(evolution_bonus.get("skill_power", 0)) + int(tree_bonus.get("skill_power", 0))) * SKILL_POWER_PER_POINT


func get_max_health() -> float:
	return hero["health"] + card_health + stat_points("hp") * HP_PER_POINT


func get_defense() -> float:
	return hero["defense"] + stat_points("defense")


func get_damage_mult() -> float:
	return 1.0 + stat_points("attack") * ATTACK_PER_POINT


## Velocidade de movimento (px/s): base do herói, cartas, pontos e velocidade (com a magia Velocidade)
## nunca passam do teto do herói (o arqueiro tem o menor); teias e cansaço reduzem depois do teto.
func get_move_speed() -> float:
	var haste := 1.5 if haste_time > 0.0 else 1.0
	var web := slow_factor if slow_time > 0.0 else 1.0
	var raw: float = hero["speed"] * card_speed_mult * minf(1.0 + stat_points("speed") * SPEED_PER_POINT, MAX_SPEED_MULT) * haste
	var ceiling: float = float(hero.get("max_speed", DEFAULT_MAX_SPEED)) * (1.25 if haste_time > 0.0 else 1.0)
	return minf(raw, ceiling) * web * fatigue_factor()


func get_attack_speed_mult() -> float:
	var haste := 1.4 if haste_time > 0.0 else 1.0
	var food := FOOD_ATTACK_BONUS if attack_buff_time > 0.0 else 1.0
	return minf(1.0 + stat_points("aspd") * ATTACK_SPEED_PER_POINT, MAX_ATTACK_SPEED_MULT) * haste * food


## Chance de acerto crítico: 5% de base, +1% por ponto de sorte e o que as melhorias derem.
func get_crit_chance() -> float:
	return clampf(BASE_CRIT + get_luck() * CRIT_PER_LUCK + get_dexterity() * CRIT_PER_DEX + stat_points("crit") * CRIT_PER_POINT + card_crit, 0.0, 0.8 if card_crit < 1.0 else 1.0)


func crit_multiplier() -> float:
	return BASE_CRIT_MULT + card_crit_mult + (inventory.bonus("critdmg") + int(tree_bonus.get("critdmg", 0))) * Item.CRIT_DAMAGE_PER_POINT * 0.01


func get_dexterity() -> int:
	return stat_points("dex")


func get_dodge_chance() -> float:
	return minf(get_dexterity() * DODGE_PER_DEX, MAX_DODGE)


func get_luck() -> int:
	return stat_points("luck")


func get_xp_mult() -> float:
	return minf(1.0 + get_luck() * XP_PER_LUCK, 4.0)


func get_drop_mult() -> float:
	return minf(1.0 + get_luck() * DROP_PER_LUCK, 3.0)


## Recalcula a vida máxima depois de mudar atributos, equipamentos ou cartas.
func refresh_stats() -> void:
	var new_max := get_max_health()
	if health > 0.0 and new_max > max_health:
		health += new_max - max_health
	max_health = new_max
	health = min(health, max_health)
	health_changed.emit(health, max_health)


func add_attribute(stat: String) -> bool:
	return add_point("hero", stat)


func _physics_process(delta: float) -> void:
	_clock += delta
	_tick_buffs(delta)
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var wasd := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
	if wasd != Vector2.ZERO:
		direction = wasd.normalized()
	if joystick and joystick.output != Vector2.ZERO:
		direction = joystick.output
	var moving := direction.length() > 0.05
	if moving:
		facing = direction.normalized()
		_sprite.flip_h = direction.x < -0.05
	tick_stamina(delta, moving)
	global_position += (direction.limit_length(1.0) * get_move_speed() + _pull) * delta
	if global_position.length() > MAP_RADIUS:
		global_position = global_position.limit_length(MAP_RADIUS)
	_pull = Vector2.ZERO
	var bob := sin(_clock * 12.0) * 2.0 if moving else sin(_clock * 3.0) * 0.8
	_sprite.position.y = SPRITE_BASE_Y + bob


## Puxão de um vórtice (px/s) neste quadro; quem puxa chama de novo a cada quadro.
func add_pull(velocity: Vector2) -> void:
	_pull += velocity


func _tick_buffs(delta: float) -> void:
	var was_shielded := shield_time > 0.0
	if double_time > 0.0:
		double_time = max(0.0, double_time - delta)
	if haste_time > 0.0:
		haste_time = max(0.0, haste_time - delta)
	if shield_time > 0.0:
		shield_time = max(0.0, shield_time - delta)
		if shield_time <= 0.0:
			shield_hp = 0.0
	if attack_buff_time > 0.0:
		attack_buff_time = max(0.0, attack_buff_time - delta)
	if slow_time > 0.0:
		slow_time = max(0.0, slow_time - delta)
	if _hurt_flash > 0.0:
		_hurt_flash = max(0.0, _hurt_flash - delta)
	energy = minf(get_max_energy(), energy + get_energy_regen() * delta)
	if health > 0.0 and health < max_health and not _dead:
		var regen := get_hp_regen()
		if regen > 0.0:
			heal(regen * delta)
	var tint := Color.WHITE
	if slow_time > 0.0:
		tint = Color(0.8, 0.85, 1.0)
	if haste_time > 0.0:
		tint = Color(0.75, 1.0, 0.8)
	if double_time > 0.0:
		tint = tint * Color(1.0, 0.95, 0.7)
	if _hurt_flash > 0.0:
		tint = Color(1.0, 0.45, 0.45)
	_sprite.modulate = tint
	if shield_time > 0.0 or was_shielded:
		queue_redraw()


func _draw() -> void:
	if shield_time > 0.0 and shield_hp > 0.0:
		var fade := clampf(shield_time, 0.0, 1.0)
		draw_circle(Vector2(0, -16), 40.0, Color(0.43, 0.7, 1.0, 0.16 * fade))
		draw_arc(Vector2(0, -16), 40.0, 0.0, TAU, 48, Color(0.6, 0.85, 1.0, 0.9 * fade), 3.0)


func activate_shield(duration: float, absorb: float) -> void:
	shield_time = duration
	shield_hp = absorb
	queue_redraw()


## `kind` "hit" (golpe de monstro) pode ser esquivado com Destreza; "dot" (veneno) não.
## `min_fraction`: o golpe tira pelo menos essa fração da vida máxima (depois da defesa); `melee`: ataque de perto, que o
## herói desvia com metade da chance.
func take_damage(amount: float, kind := "hit", min_fraction := 0.0, melee := false) -> void:
	if _dead:
		return
	if kind == "hit" and randf() < get_dodge_chance() * (MELEE_DODGE_FACTOR if melee else 1.0):
		dodged.emit()
		return
	var defense := get_defense()
	var damage := amount * (1.0 - defense / (defense + 25.0))
	if min_fraction > 0.0:
		damage = maxf(damage, max_health * min_fraction)
	if shield_hp > 0.0:
		var absorbed: float = min(shield_hp, damage)
		shield_hp -= absorbed
		damage -= absorbed
		if shield_hp <= 0.0:
			shield_time = 0.0
			queue_redraw()
	if damage <= 0.0:
		return
	_hurt_flash = 0.12
	health = max(0.0, health - damage)
	health_changed.emit(health, max_health)
	hit_taken.emit(damage)
	if health <= 0.0:
		_dead = true
		died.emit()


func heal(amount: float) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)


func raise_max_health(amount: float) -> void:
	card_health += amount
	refresh_stats()


# --- Acerto e vitalidade ------------------------------------------------------

## Chance de o golpe do herói acertar: a base do herói (o arqueiro é o que mais erra) mais 2% por
## ponto de Destreza. Os golpes que erram aparecem como "Errou".
func get_accuracy() -> float:
	return minf(float(hero.get("accuracy", 0.9)) + get_dexterity() * ACCURACY_PER_DEX + accuracy_bonus, MAX_ACCURACY if accuracy_bonus < 1.0 else 1.0)


func get_max_stamina() -> float:
	return STAMINA_BASE + stat_points("stamina") * STAMINA_PER_POINT


## 1 com a vitalidade pela metade ou mais; abaixo disso a velocidade de movimento cai aos poucos até
## FATIGUE_MIN_SPEED com a vitalidade vazia.
func fatigue_factor() -> float:
	var ratio := stamina / maxf(get_max_stamina(), 1.0)
	if ratio >= FATIGUE_START:
		return 1.0
	return lerpf(FATIGUE_MIN_SPEED, 1.0, ratio / FATIGUE_START)


## Correr gasta vitalidade (menos com Resistência); parado, ela volta rápido.
func tick_stamina(delta: float, moving: bool) -> void:
	var maximum := get_max_stamina()
	if moving:
		var relief := minf(stat_points("stamina") * STAMINA_RELIEF_PER_POINT, 0.5)
		stamina -= STAMINA_DRAIN * (1.0 - relief) * delta
	else:
		stamina += STAMINA_REGEN * delta
	stamina = clampf(stamina, 0.0, maximum)


## Roubo de vida: cada ponto devolve 0,4% do dano causado como vida (no máximo 6%), e cada golpe cura no
## máximo 2% da vida máxima (ver Game._on_damage_dealt).
func get_lifesteal() -> float:
	return clampf((inventory.bonus("lifesteal") + int(tree_bonus.get("lifesteal", 0))) * LIFESTEAL_PER_POINT, 0.0, LIFESTEAL_CAP)


## Refletir (despertar da armadura): fração do dano recebido que volta ao atacante (no máximo 60%).
func get_reflect() -> float:
	return clampf((inventory.bonus("reflect") + int(tree_bonus.get("reflect", 0))) / 100.0, 0.0, 0.6)


## Penetração: cada ponto ignora 2% da defesa do inimigo (no máximo 60%).
func get_penetration() -> float:
	return clampf(inventory.bonus("penetration") * 0.02, 0.0, 0.6)


## Regeneração de vida por segundo: 0,08% da vida máxima por ponto (só vem de despertar).
func get_hp_regen() -> float:
	return maxf(inventory.bonus("hp_regen"), 0) * 0.0008 * max_health


## Regeneração de energia por segundo: a base mais 0,5 por ponto.
func get_energy_regen() -> float:
	return ENERGY_REGEN + maxf(inventory.bonus("energy_regen"), 0) * 0.5


## Alcance dos ataques: +3% por ponto (no máximo +60%).
func get_range_mult() -> float:
	return 1.0 + clampf(inventory.bonus("range") * 0.03, 0.0, 0.6)
