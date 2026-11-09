class_name Weapon
extends Node

## Ataque automático do herói. Depende de `kind`:
## "magic" e "arrow" disparam projéteis, "melee" golpeia em leque só à frente
## (na direção em que o herói anda), causando mais dano quanto mais perto o
## inimigo está.

const MELEE_MIN_MULT := 0.6
const MELEE_MAX_MULT := 2.2
## Metade da abertura do leque do golpe, em radianos (55 graus).
const MELEE_HALF_ARC := 0.96
## Fragmentos por disparo do bacamarte e metade da abertura do leque (cerca de 17 graus).
const FRAGMENTS := 4
const FRAGMENT_SPREAD := 0.3

var kind := "magic"
var damage := 12.0
var fire_interval := 0.6
var attack_range := 280.0
## Alcance do herói sem bônus; o alcance real soma o bônus de Alcance do equipamento.
var base_range := 280.0
var projectile_speed := 480.0
var projectile_count := 1
## Dano de cada flecha enquanto a Flecha Dupla está ativa (em relação à flecha normal).
const DOUBLE_ARROW_DAMAGE := 0.6
var projectile_color := Color.WHITE
var _player: Player
var _world: Node2D
var _cooldown := 0.0
## Até o nível `AUTO_ATTACK_LEVEL` o herói só ataca pelo botão (segurando); depois ataca sozinho,
## e o botão continua valendo para atacar na hora.
var auto_enabled := false
var manual_held := false


func configure(player: Player, world: Node2D) -> void:
	_player = player
	_world = world
	var hero := player.hero
	kind = hero["attack"]
	damage = hero["damage"]
	fire_interval = hero["interval"]
	base_range = hero["range"]
	attack_range = base_range
	projectile_speed = hero["projectile_speed"]
	projectile_color = hero["projectile_color"]


func _process(delta: float) -> void:
	if _player != null:
		attack_range = base_range * _player.get_range_mult()
	_cooldown -= delta
	if _cooldown > 0.0 or not (auto_enabled or manual_held):
		return
	# Pelo botão, o ataque sai mesmo sem inimigo à vista: golpe ou disparo para onde o herói olha.
	if manual_held and find_targets(attack_range).is_empty():
		_air_attack()
		return
	match kind:
		"melee":
			_swing()
		"blunderbuss":
			_blast()
		_:
			_shoot()


## Quanto falta para o próximo ataque, de 0 (pronto) a 1 (acabou de atacar).
func cooldown_ratio() -> float:
	var total := fire_interval / maxf(_player.get_attack_speed_mult(), 0.1) if _player != null else fire_interval
	return clampf(_cooldown / maxf(total, 0.01), 0.0, 1.0)


func _air_attack() -> void:
	_cooldown = fire_interval / _player.get_attack_speed_mult()
	if kind == "melee":
		var slash := SlashEffect.new()
		slash.radius = attack_range
		slash.half_arc = MELEE_HALF_ARC
		slash.color = projectile_color
		slash.facing_angle = _player.facing.angle()
		_world.add_child(slash)
		slash.global_position = _player.global_position
	else:
		_fire(_player.facing)


## Inimigos vivos dentro do alcance, do mais perto para o mais longe.
func find_targets(max_range: float) -> Array:
	var origin := _player.global_position
	var max_distance_squared := max_range * max_range
	# Guarda a distância junto de cada inimigo: ordenar sem recalcular a distância a cada comparação.
	var found: Array = []
	for node in Enemy.alive(get_tree()):
		var enemy := node as Enemy
		if enemy and is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and not enemy.is_intangible():
			var distance_squared := origin.distance_squared_to(enemy.global_position)
			if distance_squared <= max_distance_squared:
				found.append([distance_squared, enemy])
	found.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var in_range: Array = []
	in_range.resize(found.size())
	for i in found.size():
		in_range[i] = found[i][1]
	return in_range


func melee_multiplier(distance: float) -> float:
	var proximity := 1.0 - clampf(distance / attack_range, 0.0, 1.0)
	return lerp(MELEE_MIN_MULT, MELEE_MAX_MULT, proximity)


## Inimigos dentro do alcance e do leque à frente do herói.
func find_targets_in_front() -> Array:
	var front: Array = []
	for enemy in find_targets(attack_range):
		var to_enemy: Vector2 = enemy.global_position - _player.global_position
		if absf(_player.facing.angle_to(to_enemy)) <= MELEE_HALF_ARC:
			front.append(enemy)
	return front


func _swing() -> void:
	var targets := find_targets_in_front()
	if targets.is_empty():
		return
	_cooldown = fire_interval / _player.get_attack_speed_mult()
	var base := damage * _player.get_damage_mult()
	for enemy in targets:
		var distance: float = _player.global_position.distance_to(enemy.global_position)
		enemy.take_damage(base * melee_multiplier(distance))
	var slash := SlashEffect.new()
	slash.radius = attack_range
	slash.half_arc = MELEE_HALF_ARC
	slash.color = projectile_color
	slash.facing_angle = _player.facing.angle()
	_world.add_child(slash)
	slash.global_position = _player.global_position


func _shoot() -> void:
	var targets := find_targets(attack_range)
	if targets.is_empty():
		return
	_cooldown = fire_interval / _player.get_attack_speed_mult()
	var count := projectile_count * (2 if _player.double_time > 0.0 else 1)
	var spreads := [0.0, 0.12, -0.12, 0.24, -0.24, 0.36, -0.36, 0.48]
	for i in count:
		var target: Node2D = targets[i % targets.size()]
		var round_index := i / targets.size()
		var direction := (target.global_position - _player.global_position).normalized()
		direction = direction.rotated(spreads[min(round_index, spreads.size() - 1)])
		_fire(direction, DOUBLE_ARROW_DAMAGE if _player.double_time > 0.0 else 1.0)


## Bacamarte do Gnomo: um disparo solta 4 fragmentos em leque (mais, com Tiro múltiplo).
func _blast() -> void:
	var targets := find_targets(attack_range)
	if targets.is_empty():
		return
	_cooldown = fire_interval / _player.get_attack_speed_mult()
	var aim: Vector2 = (targets[0].global_position - _player.global_position).normalized()
	var fragments := FRAGMENTS + projectile_count - 1
	for i in fragments:
		var angle := lerpf(-FRAGMENT_SPREAD, FRAGMENT_SPREAD, float(i) / maxi(fragments - 1, 1))
		var fragment := Projectile.new()
		fragment.style = "fragment"
		fragment.color = projectile_color
		fragment.radius = 4.5
		fragment.damage = damage * _player.get_damage_mult()
		fragment.velocity = aim.rotated(angle) * projectile_speed
		fragment.lifetime = attack_range * 1.15 / projectile_speed
		_world.add_child(fragment)
		fragment.global_position = _player.global_position + Vector2(0, -14) + aim * 22.0
	var flash := RingEffect.new()
	flash.radius = 34.0
	flash.color = Color("ffd36b")
	flash.duration = 0.14
	_world.add_child(flash)
	flash.global_position = _player.global_position + aim * 26.0


## `damage_scale`: com a Flecha Dupla ativa cada flecha causa só 60% do dano da flecha normal.
func _fire(direction: Vector2, damage_scale := 1.0) -> void:
	var projectile := Projectile.new()
	projectile.style = kind
	projectile.color = projectile_color
	projectile.damage = damage * _player.get_damage_mult() * damage_scale
	projectile.velocity = direction * projectile_speed
	projectile.lifetime = attack_range * 1.5 / projectile_speed
	projectile.pierce = 1 if kind == "arrow" else 0
	_world.add_child(projectile)
	projectile.global_position = _player.global_position + Vector2(0, -14)
