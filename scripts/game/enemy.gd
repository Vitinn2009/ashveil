class_name Enemy
extends Node2D

const PUSH_DECAY := 1300.0

var speed := 70.0
var max_health := 20.0
var contact_damage := 8.0
var xp_value := 1
var radius := 14.0
var color := Color("8b2e2e")
var target: Player
var health := 0.0
var _contact_cooldown := 0.0
var _hit_flash := 0.0
var _slow_factor := 1.0
var _slow_time := 0.0
var _burn_ticks := 0
var _burn_damage := 0.0
var _burn_timer := 0.0
var _push := Vector2.ZERO


func _ready() -> void:
	health = max_health
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
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
	if target == null:
		return
	_contact_cooldown -= delta
	var offset := target.global_position - global_position
	var distance := offset.length()
	if distance > target.radius + radius:
		global_position += offset / distance * speed * _slow_factor * delta
	elif _contact_cooldown <= 0.0:
		target.take_damage(contact_damage)
		_contact_cooldown = 0.6


func _draw() -> void:
	var fill := color
	if _burn_ticks > 0:
		fill = color.lerp(Color("ff7a1a"), 0.55)
	elif _slow_time > 0.0:
		fill = color.lerp(Color("6ec6ff"), 0.55)
	fill = fill.lerp(Color.WHITE, clampf(_hit_flash * 8.0, 0.0, 1.0))
	draw_circle(Vector2.ZERO, radius + 2.0, Brand.NIGHT)
	draw_circle(Vector2.ZERO, radius, fill)
	var eye := radius * 0.3
	draw_circle(Vector2(-eye, -eye * 0.4), radius * 0.2, Color.WHITE)
	draw_circle(Vector2(eye, -eye * 0.4), radius * 0.2, Color.WHITE)
	draw_circle(Vector2(-eye, -eye * 0.4), radius * 0.09, Brand.NIGHT)
	draw_circle(Vector2(eye, -eye * 0.4), radius * 0.09, Brand.NIGHT)
	var width := radius * 2.4
	var top := -radius - 11.0
	var ratio := clampf(health / max_health, 0.0, 1.0)
	draw_rect(Rect2(-width * 0.5 - 1.0, top - 1.0, width + 2.0, 6.0), Brand.NIGHT)
	draw_rect(Rect2(-width * 0.5, top, width, 4.0), Color("4a1f1f"))
	draw_rect(Rect2(-width * 0.5, top, width * ratio, 4.0), Color("e0452d").lerp(Color("7bd389"), ratio))


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
	_push = velocity


func take_damage(amount: float) -> void:
	if is_queued_for_deletion():
		return
	health -= amount
	_hit_flash = 0.1
	queue_redraw()
	if health <= 0.0:
		die()


func die() -> void:
	remove_from_group("enemies")
	EventBus.enemy_killed.emit(global_position, xp_value)
	queue_free()
