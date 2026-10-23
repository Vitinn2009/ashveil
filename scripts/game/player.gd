class_name Player
extends Node2D

signal health_changed(current: float, maximum: float)
signal died

const HP_PER_POINT := 12.0
const ATTACK_PER_POINT := 0.08
const SPEED_PER_POINT := 0.03
const ATTACK_SPEED_PER_POINT := 0.03
const XP_PER_LUCK := 0.08
const DROP_PER_LUCK := 0.10
const SPRITE_SCALE := 0.52
const SPRITE_BASE_Y := -24.0
## Limite de pontos gastos em cada atributo do herói.
const MAX_ATTRIBUTE_POINTS := 10
## Limite do total de um atributo, somando equipamentos.
const MAX_TOTAL_POINTS := 20
## Limite de pontos em cada atributo de habilidade.
const MAX_SKILL_POINTS := 5
const SKILL_RANGE_PER_POINT := 0.10
const SKILL_ECHO_PER_POINT := 0.10
const SKILL_COOLDOWN_PER_POINT := 0.05
const SKILL_POWER_PER_POINT := 0.12

var hero_id := "warrior"
var hero: Dictionary
var inventory := Inventory.new()
## Pontos distribuídos no popup de status (a cada 5 níveis).
var attributes := {"hp": 0, "defense": 0, "attack": 0, "speed": 0, "luck": 0}
## Pontos distribuídos a cada 10 níveis: alcance, x2 (eco), recarga e poder das habilidades.
var skill_attributes := {"range": 0, "echo": 0, "cooldown": 0, "power": 0}
var card_health := 0.0
var card_speed_mult := 1.0
var pickup_radius := 80.0
var radius := 16.0
var health := 0.0
var max_health := 1.0
var facing := Vector2.RIGHT
var double_time := 0.0
var haste_time := 0.0
var shield_time := 0.0
var shield_hp := 0.0
var joystick: VirtualJoystick
var _dead := false
var _sprite: Sprite2D
var _clock := 0.0
var _hurt_flash := 0.0


func _ready() -> void:
	hero = Heroes.get_hero(hero_id)
	_sprite = Sprite2D.new()
	_sprite.texture = load(hero["art"])
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	_sprite.position = Vector2(0, SPRITE_BASE_Y)
	add_child(_sprite)
	inventory.changed.connect(refresh_stats)
	refresh_stats()
	health = max_health
	health_changed.emit(health, max_health)


func stat_points(stat: String) -> int:
	return mini(int(attributes[stat]) + inventory.bonus(stat), MAX_TOTAL_POINTS)


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
	return 1.0 + int(skill_attributes["range"]) * SKILL_RANGE_PER_POINT


func skill_echo_chance() -> float:
	return int(skill_attributes["echo"]) * SKILL_ECHO_PER_POINT


func skill_cooldown_mult() -> float:
	return 1.0 - int(skill_attributes["cooldown"]) * SKILL_COOLDOWN_PER_POINT


func skill_power_mult() -> float:
	return 1.0 + int(skill_attributes["power"]) * SKILL_POWER_PER_POINT


func get_max_health() -> float:
	return hero["health"] + card_health + stat_points("hp") * HP_PER_POINT


func get_defense() -> float:
	return hero["defense"] + stat_points("defense")


func get_damage_mult() -> float:
	return 1.0 + stat_points("attack") * ATTACK_PER_POINT


func get_move_speed() -> float:
	var haste := 1.5 if haste_time > 0.0 else 1.0
	return hero["speed"] * card_speed_mult * (1.0 + stat_points("speed") * SPEED_PER_POINT) * haste


func get_attack_speed_mult() -> float:
	var haste := 1.4 if haste_time > 0.0 else 1.0
	return (1.0 + stat_points("speed") * ATTACK_SPEED_PER_POINT) * haste


func get_luck() -> int:
	return stat_points("luck")


func get_xp_mult() -> float:
	return 1.0 + get_luck() * XP_PER_LUCK


func get_drop_mult() -> float:
	return 1.0 + get_luck() * DROP_PER_LUCK


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
	if joystick and joystick.output != Vector2.ZERO:
		direction = joystick.output
	var moving := direction.length() > 0.05
	if moving:
		facing = direction.normalized()
		_sprite.flip_h = direction.x < -0.05
	global_position += direction.limit_length(1.0) * get_move_speed() * delta
	var bob := sin(_clock * 12.0) * 2.0 if moving else sin(_clock * 3.0) * 0.8
	_sprite.position.y = SPRITE_BASE_Y + bob


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
	if _hurt_flash > 0.0:
		_hurt_flash = max(0.0, _hurt_flash - delta)
	var tint := Color.WHITE
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


func take_damage(amount: float) -> void:
	if _dead:
		return
	var defense := get_defense()
	var damage := amount * (1.0 - defense / (defense + 25.0))
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
	if health <= 0.0:
		_dead = true
		died.emit()


func heal(amount: float) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)


func raise_max_health(amount: float) -> void:
	card_health += amount
	refresh_stats()
