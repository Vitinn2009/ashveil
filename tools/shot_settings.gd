extends Node

## Captura da janela de configurações. Uso: godot --path . res://tools/shot_settings.tscn -- <arquivo.png>


func _ready() -> void:
	Settings.save_enabled = false
	add_child(SettingsPanel.new())
	for i in 10:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	get_tree().quit()
