extends Node

## Atualização pelo GitHub. O jogo consulta a última "release" do repositório, compara a versão
## com a instalada e, havendo uma mais nova, oferece baixar o APK. Para ligar, preencha REPO com
## "usuario/repositorio" e publique uma release cujo nome de tag seja a versão (ex.: v0.34.0)
## com o arquivo .apk anexado. Enquanto REPO estiver vazio, o recurso fica desligado.

signal state_changed

## Versão instalada (mantenha igual a version/name e version/code do export_presets.cfg).
const VERSION := "0.38.0"
const VERSION_CODE := 41
## "usuario/repositorio" no GitHub. Vazio = atualização desligada.
const REPO := "Vitinn2009/ashveil"
const TIMEOUT := 12.0

## "idle" (não consultou), "checking", "current" (já é a mais nova), "available", "error", "disabled".
var state := "idle"
var latest_version := ""
var notes := ""
var download_url := ""
var message := ""
var _http: HTTPRequest
var _checked_once := false


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT
	_http.request_completed.connect(_on_request_completed)
	add_child(_http)
	if not is_supported():
		_set_state("disabled", "Atualização automática desligada." if REPO == "" else "Indisponível nesta plataforma.")


## Só Android e computador atualizam por aqui; a versão web é atualizada pelo próprio site.
func is_supported() -> bool:
	return REPO != "" and not OS.has_feature("web")


func is_configured() -> bool:
	return REPO != ""


## Consulta o GitHub uma vez por abertura do jogo (use `force` para o botão manual).
func check(force := false) -> void:
	if state == "checking" or not is_supported():
		return
	if _checked_once and not force:
		return
	_checked_once = true
	_set_state("checking", "Procurando atualização...")
	var url := "https://api.github.com/repos/%s/releases/latest" % REPO
	var headers := PackedStringArray(["User-Agent: Ashveil-Updater", "Accept: application/vnd.github+json"])
	var error := _http.request(url, headers)
	if error != OK:
		_set_state("error", "Sem conexão com a internet.")


func _on_request_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		_set_state("error", "Sem conexão com a internet.")
		return
	if code == 404:
		_set_state("current", "Nenhuma versão publicada ainda.")
		return
	if code != 200:
		_set_state("error", "O GitHub respondeu com erro %d." % code)
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if not (data is Dictionary):
		_set_state("error", "Resposta inesperada do GitHub.")
		return
	apply_release(data)


## Lê os dados de uma release do GitHub (separado para poder ser testado sem internet).
func apply_release(data: Dictionary) -> void:
	latest_version = str(data.get("tag_name", "")).trim_prefix("v").trim_prefix("V")
	notes = str(data.get("body", "")).strip_edges()
	download_url = str(data.get("html_url", ""))
	var assets = data.get("assets", [])
	if assets is Array:
		for asset in assets:
			if asset is Dictionary and str(asset.get("name", "")).to_lower().ends_with(".apk"):
				download_url = str(asset.get("browser_download_url", download_url))
				break
	if latest_version == "":
		_set_state("error", "A versão publicada não tem nome.")
	elif compare_versions(latest_version, VERSION) > 0:
		_set_state("available", "Nova versão %s disponível." % latest_version)
	else:
		_set_state("current", "Você já está na versão mais nova (%s)." % VERSION)


## Abre o download do APK no navegador do aparelho; ao terminar, o Android pede para instalar.
func apply() -> void:
	if state == "available" and download_url != "":
		OS.shell_open(download_url)


## Compara versões "1.2.3": positivo se a > b, negativo se a < b, 0 se iguais.
static func compare_versions(a: String, b: String) -> int:
	var pa := a.split(".")
	var pb := b.split(".")
	for i in maxi(pa.size(), pb.size()):
		var na := int(pa[i]) if i < pa.size() else 0
		var nb := int(pb[i]) if i < pb.size() else 0
		if na != nb:
			return 1 if na > nb else -1
	return 0


func _set_state(new_state: String, text: String) -> void:
	state = new_state
	message = text
	state_changed.emit()
