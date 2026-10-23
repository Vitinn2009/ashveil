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

var kind := "magic"
var damage := 12.0
var fire_interval := 0.6
var attack_range := 280.0
var projectile_speed := 480.0
var projectile_count := 1
var projectile_color := Color.WHITE
var _player: Player
var _world: Node2D
var _cooldown := 0.0


func configure(player: Player, world: Node2D) -> void:
	_player = player
	_world = world
	var hero := player.hero
	kind = hero["attack"]
	damage = hero["damage"]
	fire_interval = hero["interval"]
	attack_range = hero["range"]
	projectile_speed = hero["projectile_speed"]
	projectile_color = hero["projectile_color"]


func _process(delta: float) -> void:
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	if kind == "melee":
		_swing()
	else:
		_shoot()


## Inimigos vivos dentro do alcance, do mais perto para o mais longe.
func find_targets(max_range: float) -> Array:
	var origin := _player.global_position
	var max_distance_squared := max_range * max_range
	var in_range: Array = []
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and not enemy.is_queued_for_deletion():
			if origin.distance_squared_to(enemy.global_position) <= max_distance_squared:
				in_range.append(enemy)
	in_range.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position))
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
		_fire(direction)


func _fire(direction: Vector2) -> void:
	var projectile := Projectile.new()
	projectile.style = kind
	projectile.color = projectile_color
	projectile.damage = damage * _player.get_damage_mult()
	projectile.velocity = direction * projectile_speed
	projectile.lifetime = attack_range * 1.5 / projectile_speed
	projectile.pierce = 1 if kind == "arrow" else 0
	_world.add_child(projectile)
	projectile.global_position = _player.global_position + Vector2(0, -14)
