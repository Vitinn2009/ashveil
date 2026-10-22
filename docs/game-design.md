# Game design: Ashveil: Survivors RPG

## Loop de partida (5 a 12 minutos)

- O herói ataca sozinho. O jogador controla só o movimento.
- Inimigos chegam em hordas que aumentam com o tempo.
- Gemas de XP são atraídas para o herói ao chegar perto.
- Ao subir de nível, o jogador escolhe 1 de 3 melhorias.
- Chefe ao fim de cada bioma (a fazer no M4).

## Camada RPG (planejada)

- **Classes:** Guerreiro, Mago, Arqueiro, Clérigo, Ladino (M2).
- **Atributos:** Força, Destreza, Inteligência, Vitalidade, Sorte (M2).
- **Equipamento:** raridades, afixos e slots (M2).
- **Meta-progressão:** hub da cidade com ferreiro, biblioteca de talentos, taverna e altar (M3).
- **Biomas:** Floresta Sombria, Pântano, Ruínas, Vulcão (M4).

## Estado atual (M1, em código)

Implementado nesta etapa:
- Movimento por joystick virtual (toque) ou WASD/setas (teclado)
- Arma automática que mira no inimigo mais próximo
- Hordas que aparecem ao redor do herói, com dificuldade crescente
- Gemas de XP com atração magnética
- Level-up com 3 cartas de melhoria (o jogo pausa)
- Tela de fim de jogo com estatísticas

Ainda não implementado: classes, equipamentos, meta-progressão, biomas, chefes, missões, save, áudio.

## Decisões técnicas

- Orientação: paisagem (1280x720, expansível).
- Android: o APK atual sai com minSdk 21 e targetSdk 34 (padrão do template do Godot 4.4.1), só arm64.
- Renderização: `gl_compatibility`, para aparelhos de entrada.
- Sprites temporários desenhados por código. Trocar por arte no M5.
- Pool de objetos ainda não implementado. Entrará se o teste de desempenho pedir.
