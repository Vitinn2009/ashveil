extends Node

## Eventos globais que desacoplam combate, XP e interface.

signal enemy_killed(at_position: Vector2, xp_value: int)
signal xp_collected(value: int)
