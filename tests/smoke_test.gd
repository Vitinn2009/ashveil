extends SceneTree

## Teste de fumaça da partida. Rodar com:
##   godot --headless --path . --script res://tests/smoke_test.gd
## Sai com código 0 se tudo passar, 1 se alguma verificação falhar.

var _frame := 0
var _game: Node
var _failures := 0


func _initialize() -> void:
	_game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(_game)


func _process(_delta: float) -> bool:
	_frame += 1
	match _frame:
		# Em modo headless, eventos injetados não chegam ao _input do joystick,
		# então o handler é chamado direto. A lógica é a mesma de um toque real.
		30:
			var press := InputEventScreenTouch.new()
			press.index = 0
			press.pressed = true
			press.position = Vector2(200, 500)
			_game.joystick._input(press)
		32:
			var drag := InputEventScreenDrag.new()
			drag.index = 0
			drag.position = Vector2(260, 500)
			_game.joystick._input(drag)
		34:
			_check(_game.joystick.output.x > 0.5, "joystick reage ao arrastar para a direita")
		36:
			var release := InputEventScreenTouch.new()
			release.index = 0
			release.pressed = false
			release.position = Vector2(260, 500)
			root.push_input(release)
		38:
			_check(_game.joystick.output == Vector2.ZERO, "joystick zera ao soltar o dedo")
		60:
			_check(_game.world.get_child_count() > 1, "inimigos spawnados nos primeiros segundos")
			_check(get_nodes_in_group("enemies").size() > 0, "grupo 'enemies' preenchido")
		120:
			root.get_node("EventBus").xp_collected.emit(5)
			_check(paused, "partida pausa no level-up")
			_check(_game.level_panel.visible, "painel de level-up visível")
			_check(_game.cards_box.get_child_count() == 3, "três cartas de melhoria")
		121:
			var weapon_damage_before: float = _game.weapon.damage
			_game._choose_upgrade(_game.upgrades[0])
			_check(not paused, "partida retoma após escolher melhoria")
			_check(_game.level == 2, "nível subiu para 2")
			_check(_game.weapon.damage > weapon_damage_before, "dano da arma aumentou")
		180:
			_check(_game.kills >= 0, "contador de abates existe")
			_game.player.take_damage(99999.0)
			_check(_game.game_over, "fim de jogo ao zerar a vida")
			_check(paused, "partida pausa no fim de jogo")
		190:
			print("SMOKE TEST: %s" % ("PASSOU" if _failures == 0 else "FALHOU (%d)" % _failures))
			quit(1 if _failures > 0 else 0)
	return false


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  ok   - %s" % description)
	else:
		print("  FALHA - %s" % description)
		_failures += 1
