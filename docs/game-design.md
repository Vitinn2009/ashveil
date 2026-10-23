# Game design: Ashveil: Survivors RPG

## Loop de partida (5 a 12 minutos)

- O herói ataca sozinho. O jogador controla o movimento e dispara as habilidades.
- Cada partida é uma **missão** (hoje, "Floresta Sombria"). Os inimigos surgem por 4 minutos e uma barra de progresso no topo mostra quanto falta. Quando o tempo acaba, o spawn para, a barra muda para "restam N inimigos" e a missão termina quando o último morrer, com bônus de 50 de ouro.
- Os inimigos chegam em hordas que aumentam com o tempo, com 5 tipos diferentes.
- Ao morrer, o inimigo solta XP e, com sorte, ouro, poção ou equipamento.
- Ao subir de nível, o jogador escolhe 1 de 3 melhorias. Cada carta pode ser escolhida no máximo 5 vezes.
- A cada 5 níveis abre um popup para distribuir 3 pontos de atributo do herói.
- A cada 10 níveis abre, depois dele, um popup com 4 pontos de atributo das habilidades.
- Chefe ao fim de cada bioma (a fazer no M4).

## Heróis

| | Mago | Arqueiro | Guerreiro |
|---|---|---|---|
| Ataque | Magia à distância | Flechas que atravessam 1 inimigo | Golpe em leque à frente |
| Vida base | 70 | 95 | 150 |
| Defesa base | 0 | 2 | 6 |
| Velocidade | 200 | 235 | 215 |
| Habilidades | Gelo, Fogo, Vento | Flecha Dupla, Velocidade | Corte Duplo, Escudo |

- **Guerreiro:** golpeia só à frente, num leque de 110 graus na direção em que está andando (a última direção do joystick). Não ataca o que está atrás ou do lado. Quanto menor a distância do inimigo, maior o dano: o golpe vai de 0,6x na borda do alcance até 2,2x colado no inimigo.
- **Corte Duplo (Guerreiro):** dois cortes de espada no ar, um logo depois do outro (0,18s), à frente. Cada corte causa o dobro do dano de ataque e atravessa todos os inimigos no caminho. Recarga de 8s.
- **Gelo (Mago):** congela o chão por 5s e deixa os inimigos 60% mais lentos.
- **Fogo (Mago):** bola de fogo que queima o inimigo 3 vezes, uma por segundo, com dano de 8 x o multiplicador de ataque por queimadura.
- **Vento (Mago):** empurra os inimigos próximos e causa um pouco de dano.
- **Flecha Dupla (Arqueiro):** dobra a quantidade de flechas por 6s.
- **Velocidade (Arqueiro):** +50% de movimento e +40% de velocidade de ataque por 6s.
- **Escudo (Guerreiro):** absorve dano por 6s (50 + 3x defesa).

Teclas no computador: WASD ou setas para andar, 1, 2 e 3 para as habilidades, Q para a poção.

### Atributos das habilidades (popup a cada 10 níveis, 4 pontos, máx. 5 por atributo)

| Atributo | Efeito por ponto |
|---|---|
| Alcance | +10% de alcance e área das habilidades |
| x2 | +10% de chance de usar a habilidade duas vezes (a repetição vem 0,35s depois; nas que duram, soma a duração) |
| Recarga | -5% no tempo de recarga (soma com a carta Foco) |
| Poder | +12% de dano e efeito: dano, queimadura, empurrão, duração e absorção do escudo, e Gelo mais forte |

## Inimigos

Cinco tipos, cada um com uma característica própria. Entram na partida em momentos diferentes e a vida e o dano deles crescem com o tempo.

| Tipo | Aparece | Característica | Vida | Vel. | Dano | XP |
|---|---|---|---|---|---|---|
| Gosma | 0s | Ao morrer, se divide em duas gosmas menores, mais rápidas e frágeis. As menores não soltam itens e não se dividem de novo. | 24 | 48 | 6 | 1 |
| Morcego | 25s | Voa em zigue-zague e é muito rápido, mas frágil. | 11 | 125 | 4 | 1 |
| Esqueleto Arqueiro | 50s | Mantém distância (recua se o herói chega perto, se aproxima se está longe) e atira ossos. | 20 | 62 | 5 | 2 |
| Bomba-viva | 75s | Corre até o herói, para, pisca por 0,8s e explode numa área de 110 px. Explodir sozinha não conta como abate e não solta nada. | 14 | 88 | 0 | 2 |
| Bruto | 100s | Enorme: reduz 25% do dano recebido e ignora o empurrão do Vento. | 120 | 36 | 14 | 5 |

Os valores de vida e dano são da base, no segundo 0. O sorteio usa pesos (Gosma 10, Morcego 5, Esqueleto 4, Bomba-viva 3, Bruto 2,5), então as gosmas continuam as mais comuns. O catálogo está em `scripts/game/enemy_types.gd`.

A cena `scenes/Bestiary.tscn` mostra os cinco lado a lado, para conferir o visual.

## Atributos (popup a cada 5 níveis, 3 pontos)

| Atributo | Efeito por ponto |
|---|---|
| HP | +12 de vida máxima |
| Defesa | Reduz o dano recebido: dano x (1 - defesa / (defesa + 25)) |
| Ataque | +8% de dano |
| Rapidez | +3% de movimento e +3% de velocidade de ataque |
| Sorte | +8% de XP ganho, +10% de chance de drop, mais ouro e chance de drop duplo |

**Limites, para equilibrar o jogo:**
- No máximo **10 pontos** gastos em cada atributo (o popup mostra "3/10").
- No máximo **20 pontos** no total de um atributo, somando equipamentos.
- Se todos os atributos estiverem no limite, os pontos que sobrarem são perdidos e o popup deixa fechar.

O popup só fecha quando todos os pontos forem gastos (ou quando nenhum atributo aceitar mais). Equipamentos somam pontos nesses mesmos atributos.

## Inventário (painel à direita)

- Ouro, poções de vida (curam 40% da vida máxima), equipamentos e mochila de 12 espaços.
- 4 slots de equipamento: arma, armadura, botas e anel.
- Raridades: comum, raro, épico e lendário. A Sorte aumenta a chance das raras.
- Tocar em um item da mochila mostra os detalhes, com botões Equipar e Vender.
- Mochila cheia: o item novo é vendido automaticamente.

## Estado atual

Implementado:
- Tela inicial, seleção de herói (3 personagens) e partida.
- Arte dos 3 heróis (SVG em `assets/characters/`, renderizados em [personagens.png](personagens.png)).
- Ataque automático por classe, habilidades com recarga e barra de habilidades.
- 5 tipos de inimigo com comportamentos diferentes, todos com barra de vida, lentidão, queimadura e empurrão.
- Drops (XP, ouro, poção, equipamento), inventário e popup de atributos.

Ainda não implementado: persistência (save), meta-progressão, biomas, chefes, missões, áudio, mais heróis.
O ouro e o inventário valem só para a partida atual.

## Cenário

O jogo acontece num campo de grama infinito, sem fundo roxo:
- **Chão:** textura de grama seamless (`assets/world/grass.png`, gerada por `tools/make_grass.gd`) repetida em volta do herói.
- **Elementos:** carvalhos, pinheiros, arbustos com frutinhas, pedras, troncos caídos, tocos, cogumelos, flores (brancas, vermelhas e azuis), tufos de grama e manchas de terra. A arte está em `assets/world/` (SVG com gradientes e sombras); [docs/cenario.png](cenario.png) mostra todos.
- **Geração:** o mundo é dividido em pedaços de 640 px. Os 5x5 pedaços em volta do herói recebem cenário sorteado a partir do seed da partida e das coordenadas do pedaço, e os que ficam longe são descartados. Um ruído suave cria florestas densas e clareiras. Nada nasce num raio de 150 px do ponto inicial.
- **Profundidade:** o herói, os inimigos, as árvores e as pedras são ordenados por Y, então o herói passa na frente ou atrás das árvores. Flores, tufos e terra ficam abaixo de todos, e os efeitos e drops, acima. As árvores e pedras não bloqueiam o movimento.
- **Acabamento:** sombras sob os inimigos (mais distantes no morcego, que voa) e uma vinheta que escurece as bordas.

## Decisões técnicas

- Orientação: paisagem (1280x720, expansível). O inventário ocupa 270 px à direita e a câmera é deslocada para o herói ficar no centro da área livre.
- Android: o APK sai com minSdk 21 e targetSdk 34 (padrão do template do Godot 4.4.1), só arm64.
- Renderização: `gl_compatibility`, para aparelhos de entrada.
- Inimigos e efeitos ainda são desenhados por código. Os heróis usam arte SVG.
- Pool de objetos ainda não implementado. Entrará se o teste de desempenho pedir.
