extends Resource
class_name DiplomaticEventData

# Evento diplomático que puede afectar las relaciones

@export var event_id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var date: String = ""
@export var factions_involved: Array[String] = []

# Efectos del evento
@export var relation_changes: Dictionary = {}  # {"faction_a-faction_b": change_value}
@export var resource_effects: Dictionary = {}  # {"faction": {"resource": amount}}
@export var military_effects: Dictionary = {}  # Efectos militares
@export var economic_effects: Dictionary = {}  # Efectos económicos

# Tipo de evento
@export var event_type: String = "diplomatic"  # diplomatic, military, economic, cultural
@export var severity: String = "minor"  # minor, major, critical
@export var duration: int = 1  # Turnos que dura el efecto

# Estado
@export var is_active: bool = true
@export var remaining_turns: int = 1

func get_event_icon() -> String:
	"""Retorna la ruta del ícono del evento"""
	match event_type:
		"diplomatic":
			return "res://Assets/Icons/diplomacy.png"
		"military":
			return "res://Assets/Icons/military.png"
		"economic":
			return "res://Assets/Icons/economy.png"
		"cultural":
			return "res://Assets/Icons/culture.png"
		_:
			return "res://Assets/Icons/default_event.png"

func get_severity_color() -> Color:
	"""Retorna el color según la severidad"""
	match severity:
		"minor":
			return Color(0.8, 0.8, 1.0)  # Azul claro
		"major":
			return Color(1.0, 0.8, 0.2)  # Naranja
		"critical":
			return Color(1.0, 0.2, 0.2)  # Rojo
		_:
			return Color.WHITE

func process_turn():
	"""Procesa el evento cada turno"""
	if is_active and remaining_turns > 0:
		remaining_turns -= 1
		if remaining_turns <= 0:
			is_active = false