class_name Skills
extends RefCounted

## Habilidades ativas. `activate` recebe o Game, que expõe player, weapon e world.
## Os atributos de habilidade do herói escalam o efeito:
## alcance (área e distância), x2 (chance de repetir), recarga e poder.

const ECHO_DELAY := 0.35
const SLASH_GAP := 0.18

const DEFS := {
	"freeze": {
		"name": "Gelo",
		"desc": "Congela o chão: inimigos na área ficam 60% mais lentos por 5s.",
		"cooldown": 10.0,
		"color": Color("6ec6ff"),
		"glyph": "G",
	},
	"fire": {
		"name": "Fogo",
		"desc": "Bola de fogo que queima o inimigo 3 vezes.",
		"cooldown": 6.0,
		"color": Color("ff7a1a"),
		"glyph": "F",
	},
	"wind": {
		"name": "Vento",
		"desc": "Rajada que empurra os inimigos próximos.",
		"cooldown": 8.0,
		"color": Color("9be8c8"),
		"glyph": "V",
	},
	"double": {
		"name": "Flecha Dupla",
		"desc": "Dobra a quantidade de flechas por 6s.",
		"cooldown": 12.0,
		"color": Color("f2b705"),
		"glyph": "2x",
	},
	"haste": {
		"name": "Velocidade",
		"desc": "+50% de movimento e +40% de ataque por 6s.",
		"cooldown": 14.0,
		"color": Color("7bd389"),
		"glyph": "»",
	},
	"slash": {
		"name": "Corte Duplo",
		"desc": "Dois cortes de espada no ar, à frente, com dano x2 cada um.",
		"cooldown": 8.0,
		"color": Color("e8edf5"),
		"glyph": "X",
	},
	"shield": {
		"name": "Escudo",
		"desc": "Absorve dano por 6s.",
		"cooldown": 12.0,
		"color": Color("4aa3ff"),
		"glyph": "E",
	},
}


static func def(id: String) -> Dictionary:
	return DEFS[id]


## Recarga total de uma habilidade, com cartas e atributos de recarga.
static func cooldown_for(id: String, game) -> float:
	return DEFS[id]["cooldown"] * game.cooldown_scale * game.player.skill_cooldown_mult()


## Dispara a habilidade. Com a chance de x2, repete o efeito logo depois.
static func activate(id: String, game) -> void:
	cast(id, game, false)
	if randf() < game.player.skill_echo_chance():
		game.get_tree().create_timer(ECHO_DELAY).timeout.connect(func() -> void:
			if is_instance_valid(game) and not game.game_over:
				cast(id, game, true))


## `repeat` é true na segunda vez (x2): efeitos de duração se somam.
static func cast(id: String, game, repeat := false) -> void:
	var player: Player = game.player
	var power := player.skill_power_mult()
	var reach := player.skill_range_mult()
	match id:
		"freeze":
			_freeze(game, power, reach)
		"fire":
			_fire(game, power, reach)
		"wind":
			_wind(game, power, reach)
		"slash":
			_slash(game, power, reach)
		"double":
			player.double_time = (player.double_time if repeat else 0.0) + 6.0 * power
			_ring(game, 60.0 * reach, DEFS["double"]["color"], 0.4)
		"haste":
			player.haste_time = (player.haste_time if repeat else 0.0) + 6.0 * power
			_ring(game, 70.0 * reach, DEFS["haste"]["color"], 0.4)
		"shield":
			var absorb := (50.0 + player.get_defense() * 3.0) * power
			if repeat and player.shield_hp > 0.0:
				absorb += player.shield_hp
			player.activate_shield(6.0, absorb)
			_ring(game, 60.0 * reach, DEFS["shield"]["color"], 0.4)


static func _ring(game, radius: float, color: Color, duration: float) -> void:
	var ring := RingEffect.new()
	ring.radius = radius
	ring.color = color
	ring.duration = duration
	game.world.add_child(ring)
	ring.global_position = game.player.global_position


static func _freeze(game, power: float, reach: float) -> void:
	var zone := SkillZone.new()
	zone.radius = 170.0 * reach
	zone.duration = 5.0 * power
	zone.slow_factor = clampf(0.4 / power, 0.2, 0.4)
	game.world.add_child(zone)
	zone.global_position = game.player.global_position
	_ring(game, zone.radius, DEFS["freeze"]["color"], 0.45)


static func _fire(game, power: float, reach: float) -> void:
	var player: Player = game.player
	var targets: Array = game.weapon.find_targets(520.0 * reach)
	var direction: Vector2 = player.facing
	if not targets.is_empty():
		direction = (targets[0].global_position - player.global_position).normalized()
	var bolt := Projectile.new()
	bolt.style = "fire"
	bolt.color = DEFS["fire"]["color"]
	bolt.radius = 11.0 * (1.0 + (reach - 1.0) * 0.5)
	bolt.damage = (16.0 + game.weapon.damage * 0.5) * player.get_damage_mult() * power
	bolt.velocity = direction * 380.0
	bolt.lifetime = 1.6 * reach
	bolt.burn_ticks = 3
	bolt.burn_damage = 8.0 * player.get_damage_mult() * power
	game.world.add_child(bolt)
	bolt.global_position = player.global_position


static func _wind(game, power: float, reach: float) -> void:
	var player: Player = game.player
	var radius := 240.0 * reach
	_ring(game, radius, DEFS["wind"]["color"], 0.4)
	for node in game.get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		var offset := enemy.global_position - player.global_position
		if offset.length() <= radius:
			var direction := offset.normalized() if offset.length() > 0.01 else Vector2.RIGHT
			enemy.knockback(direction * 560.0 * power)
			enemy.take_damage(4.0 * player.get_damage_mult() * power)


## Corte Duplo: duas ondas de espada à frente, uma logo depois da outra.
static func _slash(game, power: float, reach: float) -> void:
	_wave(game, power, reach)
	game.get_tree().create_timer(SLASH_GAP).timeout.connect(func() -> void:
		if is_instance_valid(game) and not game.game_over:
			_wave(game, power, reach))


static func _wave(game, power: float, reach: float) -> void:
	var player: Player = game.player
	var direction: Vector2 = player.facing
	var wave := Projectile.new()
	wave.style = "slash"
	wave.color = DEFS["slash"]["color"]
	wave.radius = 34.0 * (1.0 + (reach - 1.0) * 0.5)
	wave.damage = game.weapon.damage * 2.0 * player.get_damage_mult() * power
	wave.velocity = direction * 520.0
	wave.lifetime = 270.0 * reach / 520.0
	wave.pierce = 999
	game.world.add_child(wave)
	wave.global_position = player.global_position + direction * 24.0
