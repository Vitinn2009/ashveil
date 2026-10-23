class_name Enemy
extends Node2D

## Inimigo. `kind` (ver EnemyTypes) escolhe o comportamento:
## slime se divide, bat voa em zigue-zague, skeleton atira de longe,
## bomber explode em área e brute ignora empurrões e reduz o dano.

const PUSH_DECAY := 1300.0
const BOMB_RADIUS := 110.0
const BOMB_FUSE := 0.8
const BOMB_TRIGGER := 85.0

var kind := "slime"
var speed := 70.0
var max_health := 20.0
var contact_damage := 8.0
var xp_value := 1
var radius := 14.0
var color := Color("8b2e2e")
var target: Player
var health := 0.0
var generation := 0
var loot := true
var knockback_immune := false
var damage_taken_mult := 1.0
var shot_damage := 9.0
var explode_damage := 22.0
var _hp_scale := 1.0
var _dmg_scale := 1.0
var _contact_cooldown := 0.0
var _hit_flash := 0.0
var _slow_factor := 1.0
var _slow_time := 0.0
var _burn_ticks := 0
var _burn_damage := 0.0
var _burn_timer := 0.0
var _push := Vector2.ZERO
var _clock := randf() * 10.0
var _shot_timer := 1.2
var _fuse := -1.0
var _strafe := 1.0


## Aplica os atributos do tipo, escalados pelo tempo de partida.
func setup(enemy_kind: String, elapsed: float) -> void:
	kind = enemy_kind
	var data := EnemyTypes.get_type(kind)
	_hp_scale = 1.0 + elapsed / 50.0
	_dmg_scale = 1.0 + elapsed / 160.0
	max_health = data["health"] * _hp_scale
	radius = data["radius"]
	speed = data["speed"]
	color = data["color"]
	xp_value = data["xp"]
	contact_damage = data["damage"] * _dmg_scale
	shot_damage = 9.0 * _dmg_scale
	explode_damage = 22.0 * _dmg_scale
	knockback_immune = data.get("knockback_immune", false)
	damage_taken_mult = data.get("damage_taken_mult", 1.0)
	_strafe = 1.0 if randf() < 0.5 else -1.0


func _ready() -> void:
	health = max_health
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	_clock += delta
	_tick_status(delta)
	if is_queued_for_deletion() or target == null:
		return
	_contact_cooldown -= delta
	var offset := target.global_position - global_position
	var distance := offset.length()
	var direction := offset / maxf(distance, 0.001)
	match kind:
		"bat":
			_move_bat(direction, delta)
		"skeleton":
			_move_skeleton(direction, distance, delta)
		"bomber":
			_move_bomber(direction, distance, delta)
		_:
			_move_chase(direction, distance, delta)
	if is_queued_for_deletion():
		return
	if contact_damage > 0.0 and distance <= target.radius + radius and _contact_cooldown <= 0.0:
		target.take_damage(contact_damage)
		_contact_cooldown = 0.6


func _tick_status(delta: float) -> void:
	if _hit_flash > 0.0:
		_hit_flash -= delta
		queue_redraw()
	if _slow_time > 0.0:
		_slow_time -= delta
		if _slow_time <= 0.0:
			_slow_factor = 1.0
			queue_redraw()
	if _burn_ticks > 0:
		_burn_timer -= delta
		if _burn_timer <= 0.0:
			_burn_timer += 1.0
			_burn_ticks -= 1
			take_damage(_burn_damage)
			if is_queued_for_deletion():
				return
			queue_redraw()
	if _push.length() > 1.0:
		global_position += _push * delta
		_push = _push.move_toward(Vector2.ZERO, PUSH_DECAY * delta)


# --- Movimento por tipo -----------------------------------------------------

func _move_chase(direction: Vector2, distance: float, delta: float) -> void:
	if distance > target.radius + radius:
		global_position += direction * speed * _slow_factor * delta


## Morcego: avança de lado para lado, em zigue-zague.
func _move_bat(direction: Vector2, delta: float) -> void:
	var sideways := Vector2(-direction.y, direction.x) * sin(_clock * 7.0)
	global_position += (direction * 0.8 + sideways * 0.9) * speed * _slow_factor * delta
	queue_redraw()


## Esqueleto: aproxima se estiver longe, recua se estiver perto, e atira.
func _move_skeleton(direction: Vector2, distance: float, delta: float) -> void:
	var step := Vector2.ZERO
	if distance > 330.0:
		step = direction
	elif distance < 220.0:
		step = -direction
	else:
		step = Vector2(-direction.y, direction.x) * _strafe * 0.5
	global_position += step * speed * _slow_factor * delta
	_shot_timer -= delta
	if _shot_timer <= 0.0 and distance < 560.0:
		_shot_timer = 2.2 + randf() * 0.6
		_shoot(direction)


func _shoot(direction: Vector2) -> void:
	var shot := EnemyShot.new()
	shot.target = target
	shot.damage = shot_damage
	shot.velocity = direction * 270.0
	get_parent().add_child(shot)
	shot.global_position = global_position


## Bomba-viva: corre até o herói, para, pisca e explode em área.
func _move_bomber(direction: Vector2, distance: float, delta: float) -> void:
	if _fuse >= 0.0:
		_fuse -= delta
		queue_redraw()
		if _fuse <= 0.0:
			_explode()
		return
	if distance < BOMB_TRIGGER:
		_fuse = BOMB_FUSE
		return
	global_position += direction * speed * _slow_factor * delta


func _explode() -> void:
	if target.global_position.distance_to(global_position) <= BOMB_RADIUS + target.radius:
		target.take_damage(explode_damage)
	var ring := RingEffect.new()
	ring.radius = BOMB_RADIUS
	ring.color = Color("ff5a3c")
	ring.duration = 0.35
	get_parent().add_child(ring)
	ring.global_position = global_position
	# Explodir sozinha não conta como abate e não solta nada.
	remove_from_group("enemies")
	queue_free()


# --- Desenho ----------------------------------------------------------------

func _draw() -> void:
	_draw_shadow()
	var fill := _body_color()
	match kind:
		"bat":
			_draw_bat(fill)
		"skeleton":
			_draw_skeleton(fill)
		"bomber":
			_draw_bomber(fill)
		"brute":
			_draw_brute(fill)
		_:
			_draw_slime(fill)
	_draw_health_bar()


## Sombra no chão. O morcego voa, então a sombra fica mais longe do corpo.
func _draw_shadow() -> void:
	var drop := radius * (2.3 if kind == "bat" else 0.95)
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		points.append(Vector2(cos(angle) * radius * 1.15, sin(angle) * radius * 0.4 + drop))
	draw_colored_polygon(points, Color(0.0, 0.0, 0.0, 0.3))


func _body_color() -> Color:
	var fill := color
	if _burn_ticks > 0:
		fill = color.lerp(Color("ff7a1a"), 0.55)
	elif _slow_time > 0.0:
		fill = color.lerp(Color("6ec6ff"), 0.55)
	return fill.lerp(Color.WHITE, clampf(_hit_flash * 8.0, 0.0, 1.0))


func _eyes(offset_y: float, spacing: float, size: float, iris: Color) -> void:
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * spacing, offset_y), size, Color.WHITE)
		draw_circle(Vector2(side * spacing, offset_y), size * 0.5, iris)


func _blob(scale_factor: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 20:
		var angle := TAU * i / 20.0
		var wobble := 1.0 + 0.07 * sin(angle * 3.0)
		points.append(Vector2(cos(angle) * wobble, sin(angle) * 0.88 * wobble) * radius * scale_factor)
	return points


func _draw_slime(fill: Color) -> void:
	draw_colored_polygon(_blob(1.14), Brand.NIGHT)
	draw_colored_polygon(_blob(1.0), fill)
	draw_circle(Vector2(-radius * 0.35, -radius * 0.45), radius * 0.2, fill.lightened(0.45))
	_eyes(-radius * 0.05, radius * 0.32, radius * 0.2, Brand.NIGHT)


func _draw_bat(fill: Color) -> void:
	var flap := sin(_clock * 18.0)
	for side in [-1.0, 1.0]:
		var wing := PackedVector2Array([
			Vector2(side * radius * 0.5, -radius * 0.2),
			Vector2(side * radius * 2.3, -radius * (0.2 + 0.9 * flap)),
			Vector2(side * radius * 1.6, radius * 0.8)])
		draw_colored_polygon(wing, fill.darkened(0.3))
		var ear := PackedVector2Array([
			Vector2(side * radius * 0.7, -radius * 0.6),
			Vector2(side * radius * 0.9, -radius * 1.4),
			Vector2(side * radius * 0.1, -radius * 0.9)])
		draw_colored_polygon(ear, fill)
	draw_circle(Vector2.ZERO, radius + 1.5, Brand.NIGHT)
	draw_circle(Vector2.ZERO, radius, fill)
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * radius * 0.35, -radius * 0.1), radius * 0.2, Color("ff4d4d"))


func _draw_skeleton(fill: Color) -> void:
	draw_arc(Vector2(radius * 1.15, 0), radius * 0.95, -1.1, 1.1, 10, Color("a8692f"), 3.5)
	draw_line(Vector2(radius * 1.15 + radius * 0.95 * cos(1.1), radius * 0.95 * sin(-1.1)),
		Vector2(radius * 1.15 + radius * 0.95 * cos(1.1), radius * 0.95 * sin(1.1)), Brand.PARCHMENT, 1.5)
	draw_circle(Vector2.ZERO, radius + 2.0, Brand.NIGHT)
	draw_circle(Vector2.ZERO, radius, fill)
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * radius * 0.38, -radius * 0.1), radius * 0.28, Brand.NIGHT)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, radius * 0.1), Vector2(-radius * 0.12, radius * 0.38), Vector2(radius * 0.12, radius * 0.38)]), Brand.NIGHT)
	for i in 4:
		var x := -radius * 0.45 + i * radius * 0.3
		draw_line(Vector2(x, radius * 0.55), Vector2(x, radius * 0.85), Brand.NIGHT, 1.5)


func _draw_brute(fill: Color) -> void:
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(side * radius * 0.6, -radius * 0.6),
			Vector2(side * radius * 1.2, -radius * 1.4),
			Vector2(side * radius * 0.15, -radius * 0.95)]), Brand.PARCHMENT)
	draw_circle(Vector2.ZERO, radius + 2.5, Brand.NIGHT)
	draw_circle(Vector2.ZERO, radius, fill)
	draw_circle(Vector2(0, radius * 0.3), radius * 0.55, fill.darkened(0.2))
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * radius * 0.38, -radius * 0.2), radius * 0.16, Color("ffd34d"))
		draw_line(Vector2(side * radius * 0.65, -radius * 0.5), Vector2(side * radius * 0.12, -radius * 0.3), Brand.NIGHT, 3.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(side * radius * 0.35, radius * 0.45),
			Vector2(side * radius * 0.55, radius * 0.45),
			Vector2(side * radius * 0.45, radius * 0.8)]), Brand.PARCHMENT)


func _draw_bomber(fill: Color) -> void:
	var pulse := 0.0
	if _fuse >= 0.0:
		pulse = 0.5 + 0.5 * sin(_fuse * 40.0)
		fill = fill.lerp(Color("ff3b30"), pulse)
		draw_circle(Vector2.ZERO, BOMB_RADIUS, Color(1.0, 0.3, 0.2, 0.08 + 0.08 * pulse))
		draw_arc(Vector2.ZERO, BOMB_RADIUS, 0.0, TAU, 48, Color(1.0, 0.3, 0.2, 0.7), 2.0)
	draw_circle(Vector2.ZERO, radius + 2.0, Brand.NIGHT)
	draw_circle(Vector2.ZERO, radius, fill)
	draw_circle(Vector2(-radius * 0.35, -radius * 0.4), radius * 0.2, fill.lightened(0.4))
	draw_line(Vector2(0, -radius), Vector2(radius * 0.5, -radius * 1.5), Color("c9a06a"), 3.0)
	draw_circle(Vector2(radius * 0.5, -radius * 1.5), 3.5 + 1.5 * sin(_clock * 20.0), Color("ffb02e"))
	_eyes(radius * 0.05, radius * 0.32, radius * 0.18, Color("ff3b30"))


func _draw_health_bar() -> void:
	var width := maxf(radius * 2.4, 24.0)
	var top := -radius - 11.0
	if kind == "bat":
		top -= radius * 0.9
	var ratio := clampf(health / max_health, 0.0, 1.0)
	draw_rect(Rect2(-width * 0.5 - 1.0, top - 1.0, width + 2.0, 6.0), Brand.NIGHT)
	draw_rect(Rect2(-width * 0.5, top, width, 4.0), Color("4a1f1f"))
	draw_rect(Rect2(-width * 0.5, top, width * ratio, 4.0), Color("e0452d").lerp(Color("7bd389"), ratio))


# --- Efeitos recebidos e morte ----------------------------------------------

func apply_slow(factor: float, duration: float) -> void:
	if _slow_time <= 0.0:
		queue_redraw()
	_slow_factor = factor
	_slow_time = max(_slow_time, duration)


func apply_burn(ticks: int, damage: float) -> void:
	_burn_ticks = ticks
	_burn_damage = damage
	_burn_timer = 1.0
	queue_redraw()


func knockback(velocity: Vector2) -> void:
	if knockback_immune:
		return
	_push = velocity


func take_damage(amount: float) -> void:
	if is_queued_for_deletion():
		return
	health -= amount * damage_taken_mult
	_hit_flash = 0.1
	queue_redraw()
	if health <= 0.0:
		die()


func die() -> void:
	remove_from_group("enemies")
	EventBus.enemy_killed.emit(global_position, xp_value, loot)
	if kind == "slime" and generation == 0:
		_split()
	queue_free()


## Gosma: ao morrer, deixa duas gosmas menores, mais rápidas e frágeis.
func _split() -> void:
	for side in [-1.0, 1.0]:
		var mini := Enemy.new()
		mini.kind = "slime"
		mini.generation = 1
		mini.loot = false
		mini.target = target
		mini.color = color
		mini.radius = radius * 0.55
		mini.max_health = max_health * 0.3
		mini.speed = speed * 1.3
		mini.contact_damage = contact_damage * 0.6
		mini.xp_value = 1
		mini.position = position + Vector2(side * radius * 0.8, 0)
		get_parent().add_child.call_deferred(mini)
