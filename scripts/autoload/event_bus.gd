extends Node

## Eventos globais que desacoplam combate, drops e interface.

## `loot` é false para inimigos que não soltam nada (gosmas pequenas).
signal enemy_killed(at_position: Vector2, xp_value: int, loot: bool)
## kind: "xp", "gold", "potion" ou "item". payload: quantidade ou Item.
signal pickup_collected(kind: String, payload: Variant)
## Dano causado a um inimigo (para os números flutuantes).
## kind: "hit", "crit", "block", "dodge" ou "dot" (queimadura).
signal damage_dealt(amount: float, at_position: Vector2, kind: String)
## O ladrão levou ouro (`amount` pode ser 0), fugiu com ele ou foi morto e devolveu com juros.
signal gold_stolen(amount: int)
signal thief_escaped(amount: int)
signal gold_recovered(at_position: Vector2, amount: int)
## Elites, chefes e mímicos soltam equipamento: `count` itens de raridade mínima `min_rarity`.
signal treasure_dropped(at_position: Vector2, count: int, min_rarity: int)
signal boss_died(boss_name: String)
## Impacto para a câmera: tremor (em pixels) e uma pausa curta no tempo (hit-stop, em segundos reais).
signal impact(shake: float, hitstop: float)
## Um monstro foi derrotado de verdade (não conta o que explode sozinho): para o catálogo e as conquistas.
signal monster_defeated(kind: String)
