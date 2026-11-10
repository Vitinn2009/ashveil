class_name SkillsExtra
extends RefCounted

## Segundo leque de habilidades: 6 novas para cada herói, que se equipam no lugar das iniciais (aba
## Habilidades do castelo). Cada uma exige um nível mínimo do herói (`req`) para ser equipada.
## `cast` recebe o Game, o poder e o alcance já calculados por Skills.cast (nível da habilidade e atributos).

const DEFS := {
	# --- Mago -----------------------------------------------------------------------------------
	"meteor": {
		"name": "Meteoro", "hero": "mage", "req": 5,
		"desc": "Marca o chão e, depois de um instante, um meteoro cai: dano enorme em área e queima 4 vezes.",
		"cooldown": 14.0, "cost": 40.0, "color": Color("ff6a2a"), "glyph": "Me",
	},
	"arcane_orb": {
		"name": "Orbes Arcanos", "hero": "mage", "req": 10,
		"desc": "Três orbes giram em volta do herói por 6s e ferem quem encostar.",
		"cooldown": 16.0, "cost": 35.0, "color": Color("b36bff"), "glyph": "Or",
	},
	"blink": {
		"name": "Salto Arcano", "hero": "mage", "req": 15,
		"desc": "Teletransporta para a frente e abala quem estiver na chegada.",
		"cooldown": 9.0, "cost": 20.0, "color": Color("8a9bff"), "glyph": "Sa",
	},
	"meditation": {
		"name": "Meditação", "hero": "mage", "req": 20,
		"desc": "Recupera 20% da vida e 30 de energia.",
		"cooldown": 22.0, "cost": 0.0, "color": Color("7bd3b0"), "glyph": "Md",
	},
	"chain_lightning": {
		"name": "Corrente Elétrica", "hero": "mage", "req": 25,
		"desc": "Um raio salta entre até 5 monstros, perdendo força a cada salto.",
		"cooldown": 12.0, "cost": 38.0, "color": Color("ffe45c"), "glyph": "Ce",
	},
	"frost_nova": {
		"name": "Nova Glacial", "hero": "mage", "req": 30,
		"desc": "Explosão de gelo em volta do herói: dano e atordoa por 1,5s.",
		"cooldown": 15.0, "cost": 45.0, "color": Color("8fe3ff"), "glyph": "Ng",
	},
	# --- Arqueiro -------------------------------------------------------------------------------
	"multishot": {
		"name": "Rajada", "hero": "archer", "req": 5,
		"desc": "Solta 7 flechas de uma vez em leque.",
		"cooldown": 9.0, "cost": 28.0, "color": Color("f4e9d8"), "glyph": "Ra",
	},
	"trap": {
		"name": "Armadilha", "hero": "archer", "req": 10,
		"desc": "Planta uma armadilha: o primeiro monstro que pisar leva dano e fica atordoado por 2s.",
		"cooldown": 11.0, "cost": 25.0, "color": Color("7bd389"), "glyph": "Ar",
	},
	"poison_arrow": {
		"name": "Flecha Venenosa", "hero": "archer", "req": 15,
		"desc": "Flecha que envenena: dano a cada segundo por 6s.",
		"cooldown": 8.0, "cost": 22.0, "color": Color("6fd06a"), "glyph": "Fv",
	},
	"arrow_rain": {
		"name": "Chuva de Flechas", "hero": "archer", "req": 20,
		"desc": "Uma chuva de flechas cai numa área por 3s.",
		"cooldown": 18.0, "cost": 45.0, "color": Color("f2b705"), "glyph": "Cf",
	},
	"eagle": {
		"name": "Falcão", "hero": "archer", "req": 25,
		"desc": "Um falcão mergulha sobre até 4 monstros, um depois do outro.",
		"cooldown": 13.0, "cost": 35.0, "color": Color("c9a06a"), "glyph": "Fa",
	},
	"pierce_shot": {
		"name": "Tiro Perfurante", "hero": "archer", "req": 30,
		"desc": "Uma flecha enorme que atravessa tudo no caminho.",
		"cooldown": 14.0, "cost": 40.0, "color": Color("ffd36b"), "glyph": "Tp",
	},
	# --- Guerreiro ------------------------------------------------------------------------------
	"charge": {
		"name": "Investida", "hero": "warrior", "req": 5,
		"desc": "Avança em linha reta, ferindo e empurrando quem estiver no caminho.",
		"cooldown": 9.0, "cost": 22.0, "color": Color("e8edf5"), "glyph": "In",
	},
	"whirlwind": {
		"name": "Redemoinho", "hero": "warrior", "req": 10,
		"desc": "Duas lâminas giram em volta do herói por 2,5s ferindo quem chegar perto.",
		"cooldown": 14.0, "cost": 40.0, "color": Color("c4ccd8"), "glyph": "Rd",
	},
	"warcry": {
		"name": "Grito de Guerra", "hero": "warrior", "req": 15,
		"desc": "Um grito que atordoa por 0,8s e empurra os monstros em volta.",
		"cooldown": 16.0, "cost": 30.0, "color": Color("ff9a5a"), "glyph": "Gg",
	},
	"second_wind": {
		"name": "Segundo Fôlego", "hero": "warrior", "req": 20,
		"desc": "Recupera 35% da vida.",
		"cooldown": 24.0, "cost": 20.0, "color": Color("7bd389"), "glyph": "Sf",
	},
	"leap": {
		"name": "Salto Esmagador", "hero": "warrior", "req": 25,
		"desc": "Salta até o ponto mirado e cai com uma pancada em área que atordoa.",
		"cooldown": 13.0, "cost": 35.0, "color": Color("c98a4a"), "glyph": "Se",
	},
	"blade_storm": {
		"name": "Tempestade de Lâminas", "hero": "warrior", "req": 30,
		"desc": "Solta 8 ondas de espada para todos os lados.",
		"cooldown": 18.0, "cost": 50.0, "color": Color("e8edf5"), "glyph": "Tl",
	},
	# --- Gnomo ----------------------------------------------------------------------------------
	"mine": {
		"name": "Mina", "hero": "gnome", "req": 5,
		"desc": "Deixa uma mina no chão: explode no primeiro monstro que chegar perto.",
		"cooldown": 10.0, "cost": 20.0, "color": Color("ff7a1a"), "glyph": "Mi",
	},
	"turret": {
		"name": "Torreta", "hero": "gnome", "req": 10,
		"desc": "Monta uma torreta que atira nos monstros por 8s.",
		"cooldown": 18.0, "cost": 40.0, "color": Color("c9962c"), "glyph": "To",
	},
	"oil": {
		"name": "Óleo Escorregadio", "hero": "gnome", "req": 15,
		"desc": "Joga óleo no chão: quem pisar anda 55% mais devagar por 6s.",
		"cooldown": 12.0, "cost": 25.0, "color": Color("5a4a2a"), "glyph": "Ol",
	},
	"repair": {
		"name": "Kit de Reparos", "hero": "gnome", "req": 20,
		"desc": "Recupera 30% da vida e cria um escudo curto.",
		"cooldown": 22.0, "cost": 25.0, "color": Color("7bd389"), "glyph": "Kr",
	},
	"fragments": {
		"name": "Rajada de Fragmentos", "hero": "gnome", "req": 25,
		"desc": "Solta 12 fragmentos em círculo.",
		"cooldown": 11.0, "cost": 30.0, "color": Color("f4d58a"), "glyph": "Rf",
	},
	"cannon": {
		"name": "Tiro de Canhão", "hero": "gnome", "req": 30,
		"desc": "Uma bala de canhão que atravessa 3 monstros e queima.",
		"cooldown": 14.0, "cost": 40.0, "color": Color("ff5a1a"), "glyph": "Tc",
	},
	# --- Viking (as três primeiras já vêm com o herói; as outras seis se equipam) -----------------
	"axe_throw": {
		"name": "Machado Arremessado", "hero": "viking", "req": 0, "base": true,
		"desc": "Arremessa um machado que atravessa até 3 monstros.",
		"cooldown": 7.0, "cost": 22.0, "color": Color("c4ccd8"), "glyph": "Ma",
	},
	"rage": {
		"name": "Fúria Berserker", "hero": "viking", "req": 0, "base": true,
		"desc": "+50% de movimento e +40% de ataque por 6s, e recupera um pouco de vida.",
		"cooldown": 14.0, "cost": 25.0, "color": Color("e0452d"), "glyph": "Fu",
	},
	"thunder_slam": {
		"name": "Trovão de Thor", "hero": "viking", "req": 20, "base": true,
		"desc": "Cinco raios caem em volta do herói e atordoam quem for atingido.",
		"cooldown": 15.0, "cost": 45.0, "color": Color("ffe45c"), "glyph": "Tt",
	},
	"shield_bash": {
		"name": "Golpe de Escudo", "hero": "viking", "req": 5,
		"desc": "Bate com o escudo à frente: dano, empurrão e atordoa por 1,5s.",
		"cooldown": 9.0, "cost": 22.0, "color": Color("e8d4a8"), "glyph": "Ge",
	},
	"battle_horn": {
		"name": "Corneta de Guerra", "hero": "viking", "req": 10,
		"desc": "Um toque de corneta que deixa os monstros próximos 60% mais lentos por 5s.",
		"cooldown": 16.0, "cost": 30.0, "color": Color("f2b705"), "glyph": "Co",
	},
	"spear_toss": {
		"name": "Lanças do Norte", "hero": "viking", "req": 15,
		"desc": "Arremessa 3 lanças em leque que atravessam 2 monstros cada.",
		"cooldown": 11.0, "cost": 30.0, "color": Color("d9c9a0"), "glyph": "La",
	},
	"ironhide": {
		"name": "Pele de Ferro", "hero": "viking", "req": 20,
		"desc": "Um escudo grande que absorve dano por 8s.",
		"cooldown": 20.0, "cost": 30.0, "color": Color("9aa5b5"), "glyph": "Pf",
	},
	"axe_whirl": {
		"name": "Machadadas Giratórias", "hero": "viking", "req": 25,
		"desc": "Três machados giram em volta do herói por 4s ferindo quem chegar perto.",
		"cooldown": 17.0, "cost": 40.0, "color": Color("c4ccd8"), "glyph": "Mg",
	},
	"valhalla": {
		"name": "Valhalla", "hero": "viking", "req": 30,
		"desc": "Recupera 30% da vida, acelera por 5s e abala os monstros em volta.",
		"cooldown": 26.0, "cost": 50.0, "color": Color("ffd36b"), "glyph": "Va",
	},
}

## Habilidades miradas arrastando o botão.
const AIMED := ["axe_throw", "spear_toss", "shield_bash", "meteor", "multishot", "trap", "poison_arrow", "arrow_rain", "pierce_shot", "charge", "leap", "oil", "cannon", "blink"]


## As 6 novas de um herói, na ordem de nível.
static func for_hero(hero_id: String) -> Array:
	var ids: Array = []
	for id in DEFS:
		if DEFS[id]["hero"] == hero_id and not DEFS[id].get("base", false):
			ids.append(id)
	return ids


static func cast(id: String, game, power: float, reach: float, _repeat := false) -> void:
	var player: Player = game.player
	var wd: float = game.weapon.damage
	var dm: float = player.get_damage_mult()
	var world: Node2D = game.world
	var tree: SceneTree = game.get_tree()
	var color: Color = DEFS[id]["color"]
	match id:
		"meteor":
			var blast := SkillEffects.Blast.new()
			blast.radius = 120.0 * reach
			blast.delay = 0.8
			blast.damage = (50.0 + wd * 2.0) * dm * power
			blast.burn_ticks = 4
			blast.burn_damage = 8.0 * dm * power
			blast.color = color
			blast.falling = "meteor"
			world.add_child(blast)
			blast.global_position = Skills._aim_point(game, reach)
		"arcane_orb":
			var orbit := SkillEffects.Orbit.new()
			orbit.count = 3
			orbit.orbit_radius = 110.0 * reach
			orbit.duration = 6.0 * power
			orbit.damage = (8.0 + wd * 0.6) * dm * power
			orbit.color = color
			player.add_child(orbit)
		"blink":
			var direction := _direction(game, 400.0)
			Skills._ring(game, 50.0, color, 0.3)
			player.global_position = (player.global_position + direction * 300.0 * reach).limit_length(Player.MAP_RADIUS)
			Skills._ring(game, 110.0 * reach, color, 0.4)
			for enemy in Skills.enemies_near(game, player.global_position, 110.0 * reach):
				enemy.take_damage((20.0 + wd) * dm * power, "skill")
				if not enemy.is_queued_for_deletion():
					enemy.knockback((enemy.global_position - player.global_position).normalized() * 320.0)
		"meditation":
			player.heal(player.max_health * minf(0.2 * power, 0.6))
			player.energy = minf(player.get_max_energy(), player.energy + 30.0 * power)
			Skills._ring(game, 70.0 * reach, color, 0.5)
		"chain_lightning":
			_chain(game, (30.0 + wd) * dm * power, reach)
		"frost_nova":
			var radius := 210.0 * reach
			Skills._ring(game, radius, color, 0.5)
			for enemy in Skills.enemies_near(game, player.global_position, radius):
				enemy.take_damage((25.0 + wd * 1.2) * dm * power, "skill")
				if not enemy.is_queued_for_deletion():
					enemy.stun(1.5 * (1.0 + (power - 1.0) * 0.5))
		"multishot":
			var direction := Skills._aim_direction(game, 520.0 * reach)
			for i in 7:
				_arrow(game, direction.rotated(lerpf(-0.45, 0.45, i / 6.0)), "arrow", Color("f4e9d8"), wd * 0.8 * dm * power, 640.0, 0.9 * reach)
		"trap":
			var trap := SkillEffects.Trap.new()
			trap.trigger_radius = 55.0
			trap.blast_radius = 100.0 * reach
			trap.damage = (35.0 + wd * 1.5) * dm * power
			trap.stun_time = 2.0 * (1.0 + (power - 1.0) * 0.5)
			trap.color = color
			world.add_child(trap)
			trap.global_position = Skills._aim_point(game, reach)
		"poison_arrow":
			var direction := Skills._aim_direction(game, 520.0 * reach)
			var arrow := _arrow(game, direction, "arrow", color, wd * 1.2 * dm * power, 700.0, 1.0 * reach)
			arrow.poison_ticks = 6
			arrow.poison_damage = 6.0 * dm * power
		"arrow_rain":
			var rain := SkillEffects.Rain.new()
			rain.radius = 150.0 * reach
			rain.duration = 3.0
			rain.damage = (10.0 + wd * 0.5) * dm * power
			rain.color = color
			world.add_child(rain)
			rain.global_position = Skills._aim_point(game, reach)
		"eagle":
			var targets: Array = game.weapon.find_targets(600.0 * reach).slice(0, 4)
			for i in targets.size():
				var enemy: Enemy = targets[i]
				tree.create_timer(0.2 * i).timeout.connect(func() -> void:
					if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and is_instance_valid(game):
						var spark := HitSpark.new()
						world.add_child(spark)
						spark.setup(enemy.global_position, "crit")
						enemy.take_damage((25.0 + wd * 1.2) * dm * power, "skill"))
			Skills._ring(game, 50.0, color, 0.3)
		"pierce_shot":
			var direction := Skills._aim_direction(game, 620.0 * reach)
			var arrow := _arrow(game, direction, "fire_arrow", color, wd * 3.5 * dm * power, 900.0, 1.1 * reach)
			arrow.radius = 12.0
			arrow.pierce = 999
		"charge":
			_charge(game, wd, dm, power, reach, color)
		"whirlwind":
			var orbit := SkillEffects.Orbit.new()
			orbit.count = 2
			orbit.orbit_radius = 95.0 * reach
			orbit.contact_radius = 40.0
			orbit.duration = 2.5 * power
			orbit.interval = 0.2
			orbit.spin = 9.0
			orbit.damage = (10.0 + wd * 0.8) * dm * power
			orbit.color = color
			player.add_child(orbit)
		"warcry":
			var radius := 260.0 * reach
			Skills._ring(game, radius, color, 0.5)
			for enemy in Skills.enemies_near(game, player.global_position, radius):
				enemy.take_damage((8.0 + wd * 0.5) * dm * power, "skill")
				if not enemy.is_queued_for_deletion():
					enemy.stun(0.8)
					enemy.knockback((enemy.global_position - player.global_position).normalized() * 300.0)
		"second_wind":
			player.heal(player.max_health * minf(0.35 * power, 0.8))
			Skills._ring(game, 70.0 * reach, color, 0.5)
		"leap":
			var target: Vector2 = Skills._aim_point(game, reach)
			var offset := (target - player.global_position).limit_length(340.0 * reach)
			player.global_position = (player.global_position + offset).limit_length(Player.MAP_RADIUS)
			var crack := CrackEffect.new()
			crack.radius = 150.0 * reach
			world.add_child(crack)
			crack.global_position = player.global_position
			for enemy in Skills.enemies_near(game, player.global_position, 150.0 * reach):
				enemy.take_damage((40.0 + wd * 2.2) * dm * power, "skill")
				if not enemy.is_queued_for_deletion():
					enemy.stun(0.8)
			EventBus.impact.emit(9.0, 0.0)
		"blade_storm":
			for i in 8:
				var wave := Projectile.new()
				wave.style = "slash"
				wave.color = color
				wave.radius = 30.0
				wave.damage = wd * 1.8 * dm * power
				wave.velocity = Vector2.from_angle(TAU * i / 8.0) * 520.0
				wave.lifetime = 240.0 * reach / 520.0
				wave.pierce = 999
				world.add_child(wave)
				wave.global_position = player.global_position + wave.velocity.normalized() * 24.0
		"mine":
			var mine := SkillEffects.Trap.new()
			mine.trigger_radius = 50.0
			mine.blast_radius = 110.0 * reach
			mine.duration = 15.0
			mine.damage = (45.0 + wd * 2.0) * dm * power
			mine.color = color
			world.add_child(mine)
			mine.global_position = player.global_position + player.facing * 40.0
		"turret":
			var turret := SkillEffects.Turret.new()
			turret.duration = 8.0 * power
			turret.damage = (6.0 + wd * 0.9) * dm * power
			turret.color = Color("f4d58a")
			world.add_child(turret)
			turret.global_position = player.global_position + player.facing * 30.0
		"oil":
			var zone := SkillZone.new()
			zone.radius = 130.0 * reach
			zone.duration = 6.0 * power
			zone.slow_factor = 0.45
			zone.color = color
			world.add_child(zone)
			zone.global_position = Skills._aim_point(game, reach)
		"repair":
			player.heal(player.max_health * minf(0.3 * power, 0.7))
			player.activate_shield(5.0, 30.0 * power + player.get_defense() * 2.0)
			Skills._ring(game, 60.0 * reach, color, 0.4)
		"fragments":
			for i in 12:
				var fragment := Projectile.new()
				fragment.style = "fragment"
				fragment.color = DEFS["fragments"]["color"]
				fragment.radius = 4.5
				fragment.damage = wd * 1.3 * dm * power
				fragment.velocity = Vector2.from_angle(TAU * i / 12.0) * 520.0
				fragment.lifetime = 0.6 * reach
				fragment.pierce = 1
				world.add_child(fragment)
				fragment.global_position = player.global_position + Vector2(0, -14)
		"cannon":
			var direction := Skills._aim_direction(game, 520.0 * reach)
			var ball := _arrow(game, direction, "fire", color, wd * 5.0 * dm * power, 600.0, 1.0 * reach)
			ball.radius = 14.0
			ball.pierce = 3
			ball.burn_ticks = 3
			ball.burn_damage = 6.0 * dm * power
		"axe_throw":
			var direction := Skills._aim_direction(game, 520.0 * reach)
			var axe := _arrow(game, direction, "axe", color, wd * 2.4 * dm * power, 560.0, 0.9 * reach)
			axe.radius = 16.0
			axe.pierce = 3
		"rage":
			player.haste_time = 6.0 * power
			player.heal(player.max_health * 0.1)
			Skills._ring(game, 70.0 * reach, color, 0.5)
		"thunder_slam":
			for i in 5:
				var blast := SkillEffects.Blast.new()
				blast.radius = 90.0 * reach
				blast.delay = 0.5 + 0.15 * i
				blast.damage = (35.0 + wd * 1.8) * dm * power
				blast.stun_time = 1.0
				blast.color = color
				blast.falling = "bolt"
				world.add_child(blast)
				blast.global_position = player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(60.0, 200.0)
		"shield_bash":
			var direction := _direction(game, 300.0)
			var center: Vector2 = player.global_position + direction * 70.0
			Skills._ring(game, 90.0 * reach, color, 0.3, center)
			for enemy in Skills.enemies_near(game, player.global_position, 160.0 * reach):
				var offset: Vector2 = enemy.global_position - player.global_position
				if absf(direction.angle_to(offset)) <= 0.9:
					enemy.take_damage((22.0 + wd * 1.4) * dm * power, "skill")
					if not enemy.is_queued_for_deletion():
						enemy.stun(1.5)
						enemy.knockback(direction * 360.0)
		"battle_horn":
			var radius := 300.0 * reach
			Skills._ring(game, radius, color, 0.6)
			for enemy in Skills.enemies_near(game, player.global_position, radius):
				enemy.take_damage((6.0 + wd * 0.5) * dm * power, "skill")
				if not enemy.is_queued_for_deletion():
					enemy.apply_slow(0.4, 5.0 * (1.0 + (power - 1.0) * 0.5))
		"spear_toss":
			var direction := Skills._aim_direction(game, 520.0 * reach)
			for i in 3:
				var spear := _arrow(game, direction.rotated((i - 1) * 0.16), "arrow", color, wd * 1.8 * dm * power, 640.0, 0.9 * reach)
				spear.radius = 10.0
				spear.pierce = 2
		"ironhide":
			player.activate_shield(8.0, (80.0 + player.get_defense() * 5.0) * power)
			Skills._ring(game, 70.0 * reach, color, 0.5)
		"axe_whirl":
			var orbit := SkillEffects.Orbit.new()
			orbit.count = 3
			orbit.orbit_radius = 120.0 * reach
			orbit.contact_radius = 34.0
			orbit.duration = 4.0 * power
			orbit.interval = 0.25
			orbit.spin = 7.0
			orbit.damage = (14.0 + wd) * dm * power
			orbit.color = color
			player.add_child(orbit)
		"valhalla":
			player.heal(player.max_health * minf(0.3 * power, 0.8))
			player.haste_time = 5.0 * power
			Skills._ring(game, 240.0 * reach, color, 0.6)
			for enemy in Skills.enemies_near(game, player.global_position, 240.0 * reach):
				enemy.take_damage((20.0 + wd * 1.2) * dm * power, "skill")
				if not enemy.is_queued_for_deletion():
					enemy.knockback((enemy.global_position - player.global_position).normalized() * 380.0)


## Direção da habilidade: a mira escolhida ou, sem ela, a do herói.
static func _direction(game, search_range: float) -> Vector2:
	if game.aim_dir != Vector2.ZERO:
		return game.aim_dir
	return Skills._aim_direction(game, search_range)


static func _arrow(game, direction: Vector2, style: String, color: Color, damage: float, speed: float, lifetime: float) -> Projectile:
	var shot := Projectile.new()
	shot.style = style
	shot.color = color
	shot.damage = damage
	shot.velocity = direction * speed
	shot.lifetime = lifetime
	game.world.add_child(shot)
	shot.global_position = game.player.global_position + Vector2(0, -14)
	return shot


## Corrente Elétrica: do monstro mais perto, salta de um em um (até 5), cada salto com 15% menos dano.
static func _chain(game, damage: float, reach: float) -> void:
	var player: Player = game.player
	var hit: Array = []
	var from: Vector2 = player.global_position
	var jump_range := 440.0 * reach
	for i in 5:
		var best: Enemy = null
		var best_distance := jump_range
		for node in game.get_tree().get_nodes_in_group("enemies"):
			var enemy := node as Enemy
			if enemy == null or enemy.is_queued_for_deletion() or enemy.is_intangible() or hit.has(enemy):
				continue
			var distance := from.distance_to(enemy.global_position)
			if distance < best_distance:
				best_distance = distance
				best = enemy
		if best == null:
			break
		hit.append(best)
		var bolt := LightningBolt.new()
		bolt.radius = 40.0
		game.world.add_child(bolt)
		bolt.global_position = best.global_position
		best.take_damage(damage * pow(0.85, i), "skill")
		from = best.global_position
		jump_range = 200.0 * reach


## Investida: anda em linha reta e fere quem estiver a até 55 px do caminho.
static func _charge(game, wd: float, dm: float, power: float, reach: float, color: Color) -> void:
	var player: Player = game.player
	var direction := _direction(game, 300.0)
	var start: Vector2 = player.global_position
	var finish := (start + direction * 260.0 * reach).limit_length(Player.MAP_RADIUS)
	var path := finish - start
	for node in game.get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		var along := clampf((enemy.global_position - start).dot(path) / maxf(path.length_squared(), 1.0), 0.0, 1.0)
		var closest := start + path * along
		if closest.distance_to(enemy.global_position) <= 55.0 + enemy.radius:
			enemy.take_damage((25.0 + wd * 1.5) * dm * power, "skill")
			if not enemy.is_queued_for_deletion():
				enemy.knockback(direction * 320.0)
	Skills._ring(game, 50.0, color, 0.3)
	player.global_position = finish
	Skills._ring(game, 80.0, color, 0.3)
