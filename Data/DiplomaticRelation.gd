extends Resource
class_name DiplomaticRelation

# Estados diplomáticos posibles
enum RelationStatus {
	UNKNOWN,      # Desconocido - no hay contacto
	HOSTILE,      # Hostil - enemigos declarados
	UNFRIENDLY,   # Poco amistoso - tensiones
	NEUTRAL,      # Neutral - sin acuerdos especiales
	FRIENDLY,     # Amistoso - relaciones cordiales
	ALLIED,       # Aliado - pacto de cooperación
	VASSAL,       # Vasallo - subordinación
	WAR          # Guerra - conflicto activo
}

@export var faction_a: String = ""
@export var faction_b: String = ""
@export var status: RelationStatus = RelationStatus.NEUTRAL
@export var opinion_a_to_b: int = 0  # -100 a +100
@export var opinion_b_to_a: int = 0  # -100 a +100
@export var active_treaties: Array[String] = []
@export var last_contact_turn: int = 0
@export var trade_agreement: bool = false
@export var military_access: bool = false
@export var shared_vision: bool = false

# Eventos diplomáticos recientes
@export var recent_events: Array[Dictionary] = []

func _init(faction_a_name: String = "", faction_b_name: String = "", initial_status: RelationStatus = RelationStatus.NEUTRAL):
	faction_a = faction_a_name
	faction_b = faction_b_name
	status = initial_status
	opinion_a_to_b = 0
	opinion_b_to_a = 0

func get_relation_name() -> String:
	"""Retorna el nombre legible del estado de relación"""
	match status:
		RelationStatus.UNKNOWN:
			return "Desconocido"
		RelationStatus.HOSTILE:
			return "Hostil"
		RelationStatus.UNFRIENDLY:
			return "Poco Amistoso"
		RelationStatus.NEUTRAL:
			return "Neutral"
		RelationStatus.FRIENDLY:
			return "Amistoso"
		RelationStatus.ALLIED:
			return "Aliado"
		RelationStatus.VASSAL:
			return "Vasallo"
		RelationStatus.WAR:
			return "Guerra"
		_:
			return "Indefinido"

func get_relation_color() -> Color:
	"""Retorna el color asociado al estado de relación"""
	match status:
		RelationStatus.UNKNOWN:
			return Color(0.5, 0.5, 0.5)      # Gris
		RelationStatus.HOSTILE:
			return Color(0.8, 0.2, 0.2)      # Rojo oscuro
		RelationStatus.UNFRIENDLY:
			return Color(1.0, 0.4, 0.0)      # Naranja
		RelationStatus.NEUTRAL:
			return Color(0.8, 0.8, 0.8)      # Gris claro
		RelationStatus.FRIENDLY:
			return Color(0.4, 0.8, 0.4)      # Verde claro
		RelationStatus.ALLIED:
			return Color(0.2, 0.8, 0.2)      # Verde
		RelationStatus.VASSAL:
			return Color(0.6, 0.4, 0.8)      # Púrpura
		RelationStatus.WAR:
			return Color(1.0, 0.0, 0.0)      # Rojo brillante
		_:
			return Color(1.0, 1.0, 1.0)      # Blanco

func add_recent_event(event_type: String, description: String, turn: int, impact: int = 0):
	"""Agrega un evento diplomático reciente"""
	var event = {
		"type": event_type,
		"description": description,
		"turn": turn,
		"impact": impact
	}
	recent_events.append(event)
	
	# Mantener solo los últimos 10 eventos
	if recent_events.size() > 10:
		recent_events.remove_at(0)

func get_opinion_towards(faction_name: String) -> int:
	"""Retorna la opinión de una facción hacia otra"""
	if faction_name == faction_b:
		return opinion_a_to_b
	elif faction_name == faction_a:
		return opinion_b_to_a
	return 0

func set_opinion(from_faction: String, to_faction: String, value: int):
	"""Establece la opinión de una facción hacia otra"""
	value = clamp(value, -100, 100)
	
	if from_faction == faction_a and to_faction == faction_b:
		opinion_a_to_b = value
	elif from_faction == faction_b and to_faction == faction_a:
		opinion_b_to_a = value

func modify_opinion(from_faction: String, to_faction: String, change: int):
	"""Modifica la opinión de una facción hacia otra"""
	var current_opinion = get_opinion_towards(to_faction if from_faction == faction_a else faction_a)
	set_opinion(from_faction, to_faction, current_opinion + change)

func can_propose_alliance() -> bool:
	"""Verifica si se puede proponer una alianza"""
	return status in [RelationStatus.NEUTRAL, RelationStatus.FRIENDLY] and not status == RelationStatus.WAR

func can_declare_war() -> bool:
	"""Verifica si se puede declarar la guerra"""
	return status != RelationStatus.WAR

func can_propose_trade() -> bool:
	"""Verifica si se puede proponer un acuerdo comercial"""
	return status in [RelationStatus.NEUTRAL, RelationStatus.FRIENDLY, RelationStatus.ALLIED] and not trade_agreement