class_name Player
extends Node2D

signal health_changed(current: float, maximum: float)
signal died

var move_speed := 220.0
var max_health := 100.0
var pickup_radius := 70.0
var radius := 16.0
var health := 0.0
var joystick: VirtualJoystick
var _dead := false


func _ready() -> void:
	health = max_health


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if joystick and joystick.output != Vector2.ZERO:
		direction = joystick.output
	global_position += direction.limit_length(1.0) * move_speed * delta


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius + 3.0, Brand.NIGHT)
	draw_circle(Vector2.ZERO, radius, Brand.GOLD)


func take_damage(amount: float) -> void:
	if _dead:
		return
	health = max(0.0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		_dead = true
		died.emit()


func heal(amount: float) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)


func raise_max_health(amount: float) -> void:
	max_health += amount
	heal(amount)
