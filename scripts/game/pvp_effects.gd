class_name PvpProjectile
extends Projectile

## Projétil do rival da arena: igual ao do herói (mesmo desenho), mas fere o herói em vez dos monstros.

var player: Player
## Golpe de perto: o herói desvia com metade da chance.
var melee := false
var hit_player := false
## Chance de acertar o golpe (o do herói também pode errar, pela precisão do rival).
var accuracy := 1.0


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if player == null or not is_instance_valid(player) or hit_player:
		return
	if global_position.distance_to(player.global_position) <= radius + player.radius:
		hit_player = true
		if randf() > accuracy:
			EventBus.damage_dealt.emit(0.0, player.global_position, "miss")
		else:
			player.take_damage(damage, "hit", 0.0, melee)
			if burn_ticks > 0:
				PvpBurn.start(get_parent(), player, burn_ticks, burn_damage)
		if pierce <= 0:
			queue_free()


## Queimadura no herói: dano de tempo a cada segundo (não pode ser esquivado).
class PvpBurn extends Node:
	var target: Player
	var ticks := 3
	var amount := 5.0
	var _timer := 1.0

	static func start(parent: Node, target_player: Player, burn_ticks: int, burn_damage: float) -> void:
		if parent == null:
			return
		var burn := PvpBurn.new()
		burn.target = target_player
		burn.ticks = burn_ticks
		burn.amount = burn_damage
		parent.add_child(burn)

	func _physics_process(delta: float) -> void:
		if target == null or not is_instance_valid(target):
			queue_free()
			return
		_timer -= delta
		if _timer <= 0.0:
			_timer += 1.0
			ticks -= 1
			target.take_damage(amount, "dot")
			if ticks <= 0:
				queue_free()


## Golpe em área do rival: marca o chão (círculo que cresce) e, ao fim da espera, fere quem estiver dentro.
class PvpBlast extends Node2D:
	var player: Player
	var radius := 100.0
	var delay := 0.6
	var damage := 20.0
	var color := Color("ff7a1a")
	## Se for menor que 1 e houver tempo de lentidão, o golpe também atrasa o herói.
	var slow_factor := 1.0
	var slow_time := 0.0
	var burn_ticks := 0
	var burn_damage := 0.0
	## "bomb", "flask" ou "bolt": o que cai do alto enquanto a área está marcada.
	var falling := ""
	var melee := false
	var _time := 0.0
	var _done := false

	func _ready() -> void:
		z_index = 4

	func _physics_process(delta: float) -> void:
		_time += delta
		if _time >= delay and not _done:
			_done = true
			_explode()
			queue_free()
			return
		queue_redraw()

	func _explode() -> void:
		var ring := RingEffect.new()
		ring.radius = radius
		ring.color = color
		ring.duration = 0.4
		get_parent().add_child(ring)
		ring.global_position = global_position
		if falling == "bolt":
			var bolt := LightningBolt.new()
			bolt.radius = radius
			get_parent().add_child(bolt)
			bolt.global_position = global_position
		if player == null or not is_instance_valid(player):
			return
		if global_position.distance_to(player.global_position) > radius + player.radius:
			return
		if damage > 0.0:
			player.take_damage(damage, "hit", 0.0, melee)
		if slow_time > 0.0:
			player.apply_slow(slow_factor, slow_time)
		if burn_ticks > 0:
			PvpBurn.start(get_parent(), player, burn_ticks, burn_damage)

	func _draw() -> void:
		var progress := clampf(_time / maxf(delay, 0.01), 0.0, 1.0)
		draw_circle(Vector2.ZERO, radius, Color(color, 0.08 + 0.14 * progress))
		draw_arc(Vector2.ZERO, radius * progress, 0.0, TAU, 40, Color(color, 0.95), 3.0)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(color, 0.6), 2.0)
		if falling == "bomb":
			draw_circle(Vector2(0, -260.0 * (1.0 - progress) - 8.0), 9.0, Color("3a3a4a"))
			draw_circle(Vector2(5, -266.0 * (1.0 - progress) - 14.0), 3.5, Color("ffb02e"))
		elif falling == "flask":
			draw_circle(Vector2(0, -260.0 * (1.0 - progress) - 8.0), 8.0, Color("7bd389"))


## Chão do rival que atrasa o herói enquanto ele estiver dentro (Gelo).
class PvpZone extends Node2D:
	var player: Player
	var radius := 170.0
	var duration := 5.0
	var slow_factor := 0.4
	var color := Color("6ec6ff")
	var _time := 0.0

	func _ready() -> void:
		z_index = -20

	func _physics_process(delta: float) -> void:
		_time += delta
		if _time >= duration:
			queue_free()
			return
		if player != null and is_instance_valid(player) and global_position.distance_to(player.global_position) <= radius + player.radius:
			player.apply_slow(slow_factor, 0.3)
		queue_redraw()

	func _draw() -> void:
		var fade := clampf(duration - _time, 0.0, 1.0)
		draw_circle(Vector2.ZERO, radius, Color(color, 0.2 * fade))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(color, 0.8 * fade), 3.0)
