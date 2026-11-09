extends Node

## Cena de desenvolvimento: abre a partida no nível 19, subindo para o 20, e já
## com o tempo adiantado, para conferir sem jogar até lá as cartas de melhoria,
## os popups de atributos, a habilidade liberada no nível 20 e todos os tipos de
## inimigo. Para usar: abra no Godot e pressione F6. Mude HERO para outro herói.

const HERO := "mage"
const START_LEVEL := 19
const START_ELAPSED := 160.0


func _ready() -> void:
	Session.hero_id = HERO
	var game: Node = load("res://scenes/Game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game.level = START_LEVEL
	game.elapsed = START_ELAPSED
	game.xp = 0.0
	game.xp_to_next = 1.0
	EventBus.pickup_collected.emit("xp", 5)
