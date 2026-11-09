# Atualização automática pelo GitHub

O jogo consulta a última *release* do seu repositório ao abrir o menu. Se a versão publicada for
mais nova que a instalada, aparece um aviso no canto de cima com **Atualizar** (abre o download do APK
e o Android pede para instalar) e **Depois**. O botão **Buscar atualização** (canto de baixo) faz a
consulta na hora.

## Como ligar

1. Crie o repositório no GitHub e envie o projeto.
2. Em `scripts/autoload/updater.gd`, preencha `REPO` com `"usuario/repositorio"`.
   Enquanto estiver vazio, o recurso fica desligado e nada aparece no menu.
3. O repositório precisa ser **público** (o jogo consulta a API sem login).

## Como publicar uma versão

1. Suba a versão nos dois lugares, sempre iguais:
   - `export_presets.cfg`: `version/code` (+1) e `version/name`
   - `scripts/autoload/updater.gd`: `VERSION` e `VERSION_CODE`
2. Rode `tools/publish_release.ps1 -Notes "O que mudou"` (exporta o APK e cria a release `vX.Y.Z` com o
   arquivo anexado). Ou crie a release à mão no GitHub: a tag deve ser a versão (`v0.34.0`) e o `.apk`
   deve estar anexado.

## Regras importantes

- **Assine sempre com a mesma chave.** O Android só instala por cima se a assinatura for a mesma. Hoje o
  projeto usa o `debug.keystore` do Godot: não apague esse arquivo.
- O jogo precisa da permissão de internet (já ligada no export).
- A primeira instalação que tiver o atualizador precisa ser feita à mão (a 0.33.0 ou mais nova).
  Dali em diante as próximas chegam pelo aviso.
- A versão web não usa isso: ela é atualizada quando o site é republicado.
