class_name Billing
extends RefCounted

## Cobrança real dos pacotes de diamantes (Google Play Faturamento). O projeto ainda NÃO tem o plugin de
## cobrança instalado nem os produtos cadastrados no Play Console, então nenhuma compra com dinheiro é
## processada: `purchase` só avisa o motivo. Para ligar, é preciso instalar o plugin "GodotGooglePlayBilling",
## cadastrar os produtos (ids iguais aos de Premium.PACKS) e entregar os diamantes aqui, depois que o Google
## confirmar o pagamento.

const PLUGIN := "GodotGooglePlayBilling"


static func available() -> bool:
	return Engine.has_singleton(PLUGIN)


## Inicia a compra de um pacote. Devolve "" quando a compra foi entregue ou o motivo de não ter sido.
static func purchase(_pack_id: String) -> String:
	if not available():
		return "Pagamento ainda não configurado neste aparelho"
	return "Pagamento em implantação"
