extends Resource
class_name DiplomaticRelationData

# Relación diplomática entre dos facciones

@export var faction_a: String = ""
@export var faction_b: String = ""
@export var relation_level: int = 0  # -100 (Guerra) a 100 (Alianza perfecta)
@export var relation_status: String = "neutral"  # neutral, alliance, war, peace_treaty, trade_agreement

# Modificadores específicos
@export var trade_modifier: float = 1.0  # Multiplicador de comercio
@export var military_access: bool = false  # Acceso militar mutuo
@export var technology_sharing: bool = false  # Intercambio de tecnología
@export var defensive_pact: bool = false  # Pacto defensivo

# Histórico
@export var last_interaction: String = ""
@export var interaction_history: Array[String] = []
@export var established_date: String = ""

# Tratados activos
@export var active_treaties: Array[String] = []

func get_relation_name() -> String:
	"""Retorna el nombre descriptivo de la relación"""
	match relation_status:
		"war":
			return "En Guerra"
		"alliance":
			return "Aliados"
		"peace_treaty":
			return "Tratado de Paz"
		"trade_agreement":
			return "Acuerdo Comercial"
		"neutral":
			if relation_level > 50:
				return "Amistosos"
			elif relation_level < -50:
				return "Hostiles"
			else:
				return "Neutrales"
		_:
			return "Desconocido"

func get_relation_color() -> Color:
	"""Retorna el color asociado con la relación"""
	match relation_status:
		"war":
			return Color.RED
		"alliance":
			return Color.GREEN
		"peace_treaty":
			return Color.YELLOW
		"trade_agreement":
			return Color.CYAN
		"neutral":
			if relation_level > 50:
				return Color(0.5, 1.0, 0.5)  # Verde claro
			elif relation_level < -50:
				return Color(1.0, 0.5, 0.5)  # Rojo claro
			else:
				return Color.WHITE
		_:
			return Color.GRAY

func add_interaction(description: String):
	"""Añade una interacción al historial"""
	interaction_history.append(description)
	last_interaction = description
	# Mantener solo las últimas 10 interacciones
	if interaction_history.size() > 10:
		interaction_history = interaction_history.slice(1)