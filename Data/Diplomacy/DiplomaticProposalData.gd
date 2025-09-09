extends Resource
class_name DiplomaticProposalData

# Propuesta diplomática entre facciones

@export var proposal_id: String = ""
@export var proposer: String = ""
@export var target: String = ""
@export var proposal_type: String = ""  # alliance, peace_treaty, trade_agreement, war_declaration, etc.
@export var title: String = ""
@export var description: String = ""

# Términos de la propuesta
@export var terms: Dictionary = {}
@export var resource_exchange: Dictionary = {}  # {"give": {}, "receive": {}}
@export var military_terms: Dictionary = {}
@export var economic_terms: Dictionary = {}

# Estado
@export var status: String = "pending"  # pending, accepted, rejected, expired
@export var created_date: String = ""
@export var expiry_date: String = ""
@export var response_date: String = ""

# Modificadores de aceptación
@export var acceptance_chance: float = 50.0
@export var relation_requirement: int = 0  # Nivel mínimo de relación requerido

func get_proposal_icon() -> String:
	"""Retorna la ruta del ícono de la propuesta"""
	match proposal_type:
		"alliance":
			return "res://Assets/Icons/alliance.png"
		"peace_treaty":
			return "res://Assets/Icons/peace.png"
		"trade_agreement":
			return "res://Assets/Icons/trade.png"
		"war_declaration":
			return "res://Assets/Icons/war.png"
		"military_access":
			return "res://Assets/Icons/military_access.png"
		"technology_sharing":
			return "res://Assets/Icons/technology.png"
		_:
			return "res://Assets/Icons/diplomacy.png"

func get_status_color() -> Color:
	"""Retorna el color según el estado"""
	match status:
		"pending":
			return Color.YELLOW
		"accepted":
			return Color.GREEN
		"rejected":
			return Color.RED
		"expired":
			return Color.GRAY
		_:
			return Color.WHITE

func get_type_name() -> String:
	"""Retorna el nombre descriptivo del tipo de propuesta"""
	match proposal_type:
		"alliance":
			return "Alianza"
		"peace_treaty":
			return "Tratado de Paz"
		"trade_agreement":
			return "Acuerdo Comercial"
		"war_declaration":
			return "Declaración de Guerra"
		"military_access":
			return "Acceso Militar"
		"technology_sharing":
			return "Intercambio Tecnológico"
		"defensive_pact":
			return "Pacto Defensivo"
		_:
			return "Propuesta Diplomática"

func is_expired(current_date: String) -> bool:
	"""Verifica si la propuesta ha expirado"""
	# TODO: Implementar comparación de fechas cuando el sistema de fechas esté disponible
	return status == "expired"

func calculate_acceptance_chance(relation_level: int) -> float:
	"""Calcula la posibilidad de aceptación basada en las relaciones"""
	var base_chance = acceptance_chance
	var relation_bonus = relation_level * 0.5  # Cada punto de relación suma 0.5%
	
	return max(0.0, min(100.0, base_chance + relation_bonus))