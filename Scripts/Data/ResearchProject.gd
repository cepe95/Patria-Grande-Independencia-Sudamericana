extends Resource
class_name ResearchProject

# Representa un proyecto de investigación en progreso

@export var technology_id: String
@export var faction_name: String
@export var progress: int = 0  # Puntos de investigación acumulados
@export var target_progress: int = 100  # Puntos necesarios para completar
@export var turns_invested: int = 0
@export var estimated_turns_remaining: int = 0
@export var assigned_researchers: int = 1  # Número de investigadores asignados
@export var resource_investment: Dictionary = {}  # Recursos ya invertidos
@export var started_turn: int = 1
@export var priority: String = "normal"  # "low", "normal", "high", "urgent"

# Estado del proyecto
@export var status: String = "active"  # "active", "paused", "completed", "cancelled"
@export var completion_turn: int = -1

func _init():
	resource_name = "ResearchProject"

func add_progress(points: int, current_turn: int = -1) -> void:
	"""Añade progreso al proyecto de investigación"""
	progress += points
	turns_invested += 1
	
	if current_turn > 0:
		update_estimated_completion()
	
	if progress >= target_progress:
		complete_research(current_turn if current_turn > 0 else started_turn + turns_invested)

func complete_research(turn: int) -> void:
	"""Marca la investigación como completada"""
	status = "completed"
	completion_turn = turn
	progress = target_progress

func pause_research() -> void:
	"""Pausa la investigación"""
	status = "paused"

func resume_research() -> void:
	"""Reanuda la investigación"""
	status = "active"

func cancel_research() -> void:
	"""Cancela la investigación"""
	status = "cancelled"

func update_estimated_completion() -> void:
	"""Actualiza la estimación de turnos restantes"""
	if turns_invested > 0 and progress > 0:
		var progress_per_turn = float(progress) / float(turns_invested)
		var remaining_progress = target_progress - progress
		estimated_turns_remaining = int(ceil(remaining_progress / progress_per_turn))
	else:
		estimated_turns_remaining = target_progress - progress  # Estimación básica

func get_progress_percentage() -> float:
	"""Retorna el porcentaje de progreso (0.0 - 1.0)"""
	return float(progress) / float(target_progress) if target_progress > 0 else 0.0

func get_efficiency_bonus() -> float:
	"""Calcula bonus de eficiencia basado en investigadores y prioridad"""
	var efficiency = 1.0
	
	# Bonus por investigadores adicionales (diminishing returns)
	if assigned_researchers > 1:
		efficiency += (assigned_researchers - 1) * 0.3
	
	# Bonus/malus por prioridad
	match priority:
		"urgent":
			efficiency += 0.5
		"high":
			efficiency += 0.2
		"low":
			efficiency -= 0.2
	
	return efficiency

func get_daily_cost() -> Dictionary:
	"""Retorna el costo diario de mantener la investigación"""
	var base_cost = {
		"dinero": assigned_researchers * 10,
		"comida": assigned_researchers * 5
	}
	
	# Multiplicador por prioridad
	var multiplier = 1.0
	match priority:
		"urgent":
			multiplier = 2.0
		"high":
			multiplier = 1.5
		"low":
			multiplier = 0.7
	
	for resource in base_cost:
		base_cost[resource] = int(base_cost[resource] * multiplier)
	
	return base_cost

func get_status_display() -> String:
	"""Retorna un texto descriptivo del estado actual"""
	match status:
		"active":
			return "En progreso (%.1f%%)" % (get_progress_percentage() * 100)
		"paused":
			return "Pausado (%.1f%%)" % (get_progress_percentage() * 100)
		"completed":
			return "Completado (Turno %d)" % completion_turn
		"cancelled":
			return "Cancelado"
		_:
			return "Estado desconocido"

func to_save_data() -> Dictionary:
	"""Convierte el proyecto a un diccionario para guardado"""
	return {
		"technology_id": technology_id,
		"faction_name": faction_name,
		"progress": progress,
		"target_progress": target_progress,
		"turns_invested": turns_invested,
		"estimated_turns_remaining": estimated_turns_remaining,
		"assigned_researchers": assigned_researchers,
		"resource_investment": resource_investment,
		"started_turn": started_turn,
		"priority": priority,
		"status": status,
		"completion_turn": completion_turn
	}

func from_save_data(data: Dictionary) -> void:
	"""Carga el proyecto desde un diccionario de guardado"""
	technology_id = data.get("technology_id", "")
	faction_name = data.get("faction_name", "")
	progress = data.get("progress", 0)
	target_progress = data.get("target_progress", 100)
	turns_invested = data.get("turns_invested", 0)
	estimated_turns_remaining = data.get("estimated_turns_remaining", 0)
	assigned_researchers = data.get("assigned_researchers", 1)
	resource_investment = data.get("resource_investment", {})
	started_turn = data.get("started_turn", 1)
	priority = data.get("priority", "normal")
	status = data.get("status", "active")
	completion_turn = data.get("completion_turn", -1)