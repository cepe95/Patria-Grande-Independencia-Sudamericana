extends Resource

class_name EventData

# Tipos de eventos
enum EventType {
	HISTORICAL,  # Evento histórico con fecha específica
	RANDOM,      # Evento aleatorio
	TRIGGERED    # Evento disparado por condiciones específicas
}

# Tipos de efectos
enum EffectType {
	RESOURCE_CHANGE,    # Cambio de recursos
	DIPLOMATIC_CHANGE,  # Cambio en relaciones diplomáticas
	UNIT_CHANGE,        # Cambio en unidades
	CUSTOM              # Efecto personalizado
}

# === DATOS BÁSICOS DEL EVENTO ===
@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var event_type: EventType = EventType.RANDOM
@export var image_path: String = ""

# === CONDICIONES DE ACTIVACIÓN ===
@export var trigger_date: String = ""  # Fecha para eventos históricos (formato: "YYYY/MM/DD")
@export var trigger_turn: int = -1      # Turno específico (-1 = cualquier turno)
@export var random_chance: float = 0.0  # Probabilidad (0.0-1.0) para eventos aleatorios
@export var trigger_conditions: Array[String] = []  # Condiciones personalizadas

# === OPCIONES DE DECISIÓN ===
@export var has_choices: bool = false
@export var choices: Array[Dictionary] = []  # Array de {text: String, effects: Array}

# === EFECTOS DEL EVENTO ===
@export var effects: Array[Dictionary] = []  # Array de efectos del evento

# === CONFIGURACIÓN ===
@export var can_repeat: bool = false    # ¿Puede repetirse el evento?
@export var priority: int = 0           # Prioridad para mostrar (mayor = más importante)
@export var category: String = ""       # Categoría del evento (militar, económico, político, etc.)

func _init():
	pass

func create_historical_event(event_id: String, event_title: String, event_description: String, date: String) -> EventData:
	"""Crea un evento histórico básico"""
	var event = EventData.new()
	event.id = event_id
	event.title = event_title
	event.description = event_description
	event.event_type = EventType.HISTORICAL
	event.trigger_date = date
	return event

func create_random_event(event_id: String, event_title: String, event_description: String, chance: float) -> EventData:
	"""Crea un evento aleatorio básico"""
	var event = EventData.new()
	event.id = event_id
	event.title = event_title
	event.description = event_description
	event.event_type = EventType.RANDOM
	event.random_chance = chance
	return event

func add_resource_effect(resource_name: String, amount: int):
	"""Agrega un efecto de cambio de recursos"""
	var effect = {
		"type": EffectType.RESOURCE_CHANGE,
		"resource": resource_name,
		"amount": amount
	}
	effects.append(effect)

func add_choice(choice_text: String, choice_effects: Array = []):
	"""Agrega una opción de decisión al evento"""
	has_choices = true
	var choice = {
		"text": choice_text,
		"effects": choice_effects
	}
	choices.append(choice)

func get_trigger_date() -> Date:
	"""Convierte la fecha de activación a objeto Date"""
	if trigger_date.is_empty():
		return null
	
	var parts = trigger_date.split("/")
	if parts.size() != 3:
		push_error("Formato de fecha inválido: " + trigger_date)
		return null
	
	return Date.new(int(parts[0]), int(parts[1]), int(parts[2]))

func should_trigger(current_date: Date, current_turn: int, context: Dictionary = {}) -> bool:
	"""Verifica si el evento debe dispararse"""
	match event_type:
		EventType.HISTORICAL:
			if trigger_date.is_empty():
				return false
			var target_date = get_trigger_date()
			if target_date:
				return current_date.is_greater_or_equal(target_date)
			return false
		
		EventType.RANDOM:
			if trigger_turn > 0 and current_turn != trigger_turn:
				return false
			return randf() <= random_chance
		
		EventType.TRIGGERED:
			# Aquí se evaluarían las condiciones personalizadas
			return evaluate_trigger_conditions(context)
	
	return false

func evaluate_trigger_conditions(context: Dictionary) -> bool:
	"""Evalúa condiciones personalizadas de activación"""
	# TODO: Implementar sistema de evaluación de condiciones
	# Por ahora, siempre retorna false para eventos TRIGGERED
	return false

func apply_effects(game_context: Dictionary) -> Dictionary:
	"""Aplica los efectos del evento y retorna los cambios realizados"""
	var results = {
		"resource_changes": {},
		"diplomatic_changes": {},
		"unit_changes": [],
		"other_changes": []
	}
	
	for effect in effects:
		match effect.get("type", EffectType.CUSTOM):
			EffectType.RESOURCE_CHANGE:
				var resource = effect.get("resource", "")
				var amount = effect.get("amount", 0)
				if not resource.is_empty():
					results.resource_changes[resource] = amount
			
			EffectType.DIPLOMATIC_CHANGE:
				var change = {
					"faction": effect.get("faction", ""),
					"relation_change": effect.get("relation_change", 0)
				}
				results.diplomatic_changes[change.faction] = change.relation_change
			
			EffectType.UNIT_CHANGE:
				results.unit_changes.append(effect)
			
			EffectType.CUSTOM:
				results.other_changes.append(effect)
	
	return results

func to_dict() -> Dictionary:
	"""Convierte el evento a diccionario para serialización"""
	return {
		"id": id,
		"title": title,
		"description": description,
		"event_type": event_type,
		"image_path": image_path,
		"trigger_date": trigger_date,
		"trigger_turn": trigger_turn,
		"random_chance": random_chance,
		"trigger_conditions": trigger_conditions,
		"has_choices": has_choices,
		"choices": choices,
		"effects": effects,
		"can_repeat": can_repeat,
		"priority": priority,
		"category": category
	}

func from_dict(data: Dictionary):
	"""Carga el evento desde un diccionario"""
	id = data.get("id", "")
	title = data.get("title", "")
	description = data.get("description", "")
	event_type = data.get("event_type", EventType.RANDOM)
	image_path = data.get("image_path", "")
	trigger_date = data.get("trigger_date", "")
	trigger_turn = data.get("trigger_turn", -1)
	random_chance = data.get("random_chance", 0.0)
	trigger_conditions = data.get("trigger_conditions", [])
	has_choices = data.get("has_choices", false)
	choices = data.get("choices", [])
	effects = data.get("effects", [])
	can_repeat = data.get("can_repeat", false)
	priority = data.get("priority", 0)
	category = data.get("category", "")