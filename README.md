# Ashveil: Survivors RPG

Jogo Android de sobrevivência em hordas com elementos de RPG. Feito em Godot 4.4 (GDScript).

## Instalar o APK no celular

O APK de debug já está gerado em `export/ashveil.apk` (arm64, Android 5.0+, assinado com a chave de debug).

1. No celular, ative **Opções do desenvolvedor > Depuração USB** e conecte ao computador.
2. Instale:

```bash
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" install -r export/ashveil.apk
```

Também dá para copiar o arquivo para o celular e abrir pelo gerenciador de arquivos (permita instalar de fontes desconhecidas).

## Como abrir no Godot

1. Instale o [Godot 4.4](https://godotengine.org/download) (standard, não a .NET).
2. Importe `project.godot` e pressione **F5**. No computador use WASD ou setas. No celular, o joystick virtual aparece onde você toca na metade esquerda da tela.

## Gerar o APK de novo

Pré-requisitos já usados nesta máquina: JDK 17, Android SDK com `platforms;android-34` e `build-tools;34.0.0`, e os export templates 4.4.1 do Godot.

```bash
godot --headless --path . --export-debug "Android" "export/ashveil.apk"
```

Observações que custaram tempo descobrir:
- O Godot 4.4.1 exige build-tools 34.0.0 e a opção `rendering/textures/vram_compression/import_etc2_astc` ligada. Sem isso o export falha com uma mensagem vazia.
- O preset não usa Gradle (`gradle_build/use_gradle_build=false`), então não há pasta `android/`.

## Testes

```bash
godot --headless --path . --script res://tests/smoke_test.gd
```

Roda uma partida simulada para os três heróis: telas, ataque, habilidades, inventário, atributos, level-up, popup de status e fim de jogo. No modo `--script`, o Godot imprime "Identifier not found: EventBus" no stderr ao carregar as classes antes dos autoloads. O teste continua e termina com "SMOKE TEST: PASSOU".

## Ferramentas

- `tools/make_icons.gd` gera os PNGs de `assets/brand/` a partir dos SVGs.
- `tools/render_characters.gd` renderiza os três heróis em `docs/personagens.png`.
- `tools/make_grass.gd` gera a textura de grama; `tools/render_world.gd` renderiza o cenário em `docs/cenario.png`.
- `scenes/Bestiary.tscn` mostra os cinco inimigos lado a lado. Para ver, abra a cena no Godot e pressione F6.
- `scenes/PreviewLevels.tscn` abre a partida no nível 9, subindo para o 10, para ver as cartas e os dois popups de atributos sem jogar até lá.

## Documentação

- [Game design](docs/game-design.md)
- [Marca](docs/brand.md)

## Status

Pronto: base, marca, núcleo de combate e a primeira camada de RPG (M0 a M2 em versão inicial): 3 heróis com habilidades, inventário, drops e atributos. Próximas fases: progressão permanente e save (M3), conteúdo com biomas e chefes (M4).
