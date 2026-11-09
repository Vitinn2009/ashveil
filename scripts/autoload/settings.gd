extends Node

## Configurações do jogador (volumes, tremor de tela e números de dano), salvas em arquivo próprio,
## separado do progresso. Os volumes valem de 0 a 1.

const PATH := "user://ashveil_settings.cfg"

var master := 1.0
var music := 1.0
var sfx := 1.0
var screen_shake := true
var damage_numbers := true
var save_enabled := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply()


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	master = clampf(float(config.get_value("audio", "master", 1.0)), 0.0, 1.0)
	music = clampf(float(config.get_value("audio", "music", 1.0)), 0.0, 1.0)
	sfx = clampf(float(config.get_value("audio", "sfx", 1.0)), 0.0, 1.0)
	screen_shake = bool(config.get_value("game", "screen_shake", true))
	damage_numbers = bool(config.get_value("game", "damage_numbers", true))


func save_settings() -> void:
	if not save_enabled:
		return
	var config := ConfigFile.new()
	config.set_value("audio", "master", master)
	config.set_value("audio", "music", music)
	config.set_value("audio", "sfx", sfx)
	config.set_value("game", "screen_shake", screen_shake)
	config.set_value("game", "damage_numbers", damage_numbers)
	config.save(PATH)


## Aplica os volumes: o geral no barramento principal; música e efeitos no Sound.
func apply() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master, 0.0001)))
	AudioServer.set_bus_mute(0, master <= 0.001)
	var sound := get_node_or_null("/root/Sound")
	if sound != null:
		sound.refresh_volumes()
