extends Node

## Cena de desenvolvimento: abre a partida no nível 9, subindo para o 10, para
## conferir sem jogar até lá as cartas de melhoria, o popup de atributos do herói
## (a cada 5 níveis) e o popup de atributos das habilidades (a cada 10).
## Para usar: abra no Godot e pressione F6. Mude HERO para testar outro herói.

const HERO := "warrior"
const START_LEVEL := 9


func _ready() -> void:
	Session.hero_id = HERO
	var game: Node = load("res://scenes/Game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game.level = START_LEVEL
	game.xp = 0.0
	game.xp_to_next = 1.0
	EventBus.pickup_collected.emit("xp", 5)
