extends Node

## Eventos globais que desacoplam combate, drops e interface.

signal enemy_killed(at_position: Vector2, xp_value: int)
## kind: "xp", "gold", "potion" ou "item". payload: quantidade ou Item.
signal pickup_collected(kind: String, payload: Variant)
