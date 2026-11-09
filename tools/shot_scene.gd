extends Node

## Abre uma cena numa janela e salva uma captura. Uso:
##   godot --path . --resolution 1280x720 res://tools/shot_scene.tscn -- res://scenes/Castle.tscn <arquivo.png>


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	Session.save_enabled = false
	add_child((load(args[0]) as PackedScene).instantiate())
	for i in 25:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(args[1])
	print("SHOT ", args[1], " ", get_viewport().get_visible_rect().size)
	get_tree().quit()
