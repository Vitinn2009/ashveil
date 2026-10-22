class_name Enemy
extends Node2D

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


func _ready() -> void:
	health = max_health
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	if _hit_flash > 0.0:
		_hit_flash -= delta
		queue_redraw()
	if target == null:
		return
	_contact_cooldown -= delta
	var offset := target.global_position - global_position
	var distance := offset.length()
	if distance > target.radius + radius:
		global_position += offset / distance * speed * delta
	elif _contact_cooldown <= 0.0:
		target.take_damage(contact_damage)
		_contact_cooldown = 0.6


func _draw() -> void:
	var fill := color.lerp(Color.WHITE, clamp(_hit_flash * 8.0, 0.0, 1.0))
	draw_circle(Vector2.ZERO, radius, fill)


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
