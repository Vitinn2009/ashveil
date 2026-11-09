extends Node

## Tira prints das telas do novo layout: tools/shot_layout.tscn -- <pasta de saída>
func _ready() -> void:
	Session.save_enabled = false
	var out := OS.get_cmdline_user_args()[0]
	Session.set_progress("mage", 22, 120.0, 3, 22)
	Session.inventory.gold = 12480
	for scene in ["Main", "CharacterSelect", "Castle"]:
		var node: Node = (load("res://scenes/%s.tscn" % scene) as PackedScene).instantiate()
		add_child(node)
		for i in 8:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, scene])
		node.queue_free()
		await get_tree().process_frame
	get_tree().quit()
