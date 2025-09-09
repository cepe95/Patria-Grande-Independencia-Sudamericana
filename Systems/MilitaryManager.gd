extends Node

# MilitaryManager - Sistema de gestión militar global
# Maneja reclutamiento, batallas, y operaciones militares

signal unit_recruited(unit_data: UnitData, city: String)
signal battle_started(attacker: DivisionData, defender: DivisionData, location: String)
signal battle_finished(result: Dictionary)

var active_battles: Array[Dictionary] = []
var recruitment_queue: Array[Dictionary] = []
var unit_types_config: Dictionary = {}
var combat_rules_config: Dictionary = {}

func _ready():
	load_military_configs()

func load_military_configs():
	"""Carga configuraciones militares desde archivos JSON"""
	var unit_types_file = FileAccess.open("res://Data/Military/UnitTypes.json", FileAccess.READ)
	if unit_types_file:
		var json_string = unit_types_file.get_as_text()
		unit_types_file.close()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			unit_types_config = json.data
			print("✓ Configuración de tipos de unidad cargada")
		else:
			push_error("Error al parsear UnitTypes.json")
	
	var combat_rules_file = FileAccess.open("res://Data/Military/CombatRules.json", FileAccess.READ)
	if combat_rules_file:
		var json_string = combat_rules_file.get_as_text()
		combat_rules_file.close()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			combat_rules_config = json.data
			print("✓ Reglas de combate cargadas")
		else:
			push_error("Error al parsear CombatRules.json")

func can_recruit_unit(unit_type: String, city: String, faction: String) -> bool:
	"""Verifica si se puede reclutar una unidad en una ciudad"""
	if not FactionManager.faccion_existe(faction):
		return false
	
	var faction_data = FactionManager.obtener_faccion(faction)
	var unit_config = get_unit_config(unit_type)
	
	if not unit_config:
		return false
	
	# Verificar recursos suficientes
	for resource in unit_config.get("recruitment_cost", {}):
		var required = unit_config["recruitment_cost"][resource]
		var available = faction_data.recursos.get(resource, 0)
		if available < required:
			return false
	
	return true

func recruit_unit(unit_type: String, city: String, faction: String) -> bool:
	"""Inicia el reclutamiento de una unidad"""
	if not can_recruit_unit(unit_type, city, faction):
		return false
	
	var faction_data = FactionManager.obtener_faccion(faction)
	var unit_config = get_unit_config(unit_type)
	
	# Consumir recursos
	for resource in unit_config.get("recruitment_cost", {}):
		var cost = unit_config["recruitment_cost"][resource]
		faction_data.recursos[resource] -= cost
	
	# Agregar a cola de reclutamiento
	var recruitment_order = {
		"unit_type": unit_type,
		"city": city,
		"faction": faction,
		"turns_remaining": unit_config.get("recruitment_time", 1),
		"config": unit_config
	}
	recruitment_queue.append(recruitment_order)
	
	print("Reclutamiento iniciado: %s en %s" % [unit_type, city])
	return true

func process_recruitment():
	"""Procesa la cola de reclutamiento cada turno"""
	var completed_recruitments = []
	
	for i in range(recruitment_queue.size()):
		var order = recruitment_queue[i]
		order["turns_remaining"] -= 1
		
		if order["turns_remaining"] <= 0:
			completed_recruitments.append(i)
			complete_recruitment(order)
	
	# Remover reclutamientos completados (en orden inverso)
	for i in range(completed_recruitments.size() - 1, -1, -1):
		recruitment_queue.remove_at(completed_recruitments[i])

func complete_recruitment(order: Dictionary):
	"""Completa un reclutamiento y crea la unidad"""
	var unit_data = UnitData.new()
	var config = order["config"]
	
	unit_data.nombre = config["name"]
	unit_data.rama = config["branch"]
	unit_data.nivel = config["level"]
	unit_data.tamaño = config["size"]
	unit_data.cantidad = config["size"]
	unit_data.efectividad_combate = config["effectiveness"]
	unit_data.costo_reclutamiento = config["recruitment_cost"]
	unit_data.tiempo_reclutamiento = config["recruitment_time"]
	
	# Configurar consumo desde config
	if config.has("consumption"):
		unit_data.consumo = config["consumption"]
	
	unit_recruited.emit(unit_data, order["city"])
	print("¡Reclutamiento completado! %s en %s" % [unit_data.nombre, order["city"]])

func get_unit_config(unit_type: String) -> Dictionary:
	"""Obtiene configuración de un tipo de unidad"""
	for category in unit_types_config.values():
		if category.has(unit_type):
			return category[unit_type]
	return {}

func get_available_unit_types() -> Array[String]:
	"""Obtiene lista de tipos de unidad disponibles"""
	var types: Array[String] = []
	for category in unit_types_config.values():
		for unit_type in category.keys():
			types.append(unit_type)
	return types

func initiate_battle(attacker: DivisionData, defender: DivisionData, location: String) -> Dictionary:
	"""Inicia una batalla entre dos divisiones"""
	var battle_data = {
		"id": Time.get_unix_time_from_system(),
		"attacker": attacker,
		"defender": defender,
		"location": location,
		"turn": 0,
		"max_turns": 5,
		"status": "active"
	}
	
	active_battles.append(battle_data)
	battle_started.emit(attacker, defender, location)
	
	# Procesar batalla inmediatamente (puede extenderse para batallas por turnos)
	var result = resolve_battle(battle_data)
	return result

func resolve_battle(battle_data: Dictionary) -> Dictionary:
	"""Resuelve una batalla y determina el resultado"""
	var attacker = battle_data["attacker"] as DivisionData
	var defender = battle_data["defender"] as DivisionData
	
	# Calcular fuerzas
	var attacker_strength = calculate_battle_strength(attacker)
	var defender_strength = calculate_battle_strength(defender)
	
	# Determinar resultado
	var strength_ratio = attacker_strength / defender_strength
	var outcome = determine_battle_outcome(strength_ratio)
	
	# Aplicar pérdidas y efectos
	var result = apply_battle_effects(attacker, defender, outcome)
	result["location"] = battle_data["location"]
	result["outcome"] = outcome
	
	# Actualizar historial
	var battle_name = "Batalla de %s" % battle_data["location"]
	attacker.historial_batallas.append(battle_name)
	defender.historial_batallas.append(battle_name)
	
	# Remover batalla de activas
	active_battles.erase(battle_data)
	
	battle_finished.emit(result)
	return result

func calculate_battle_strength(division: DivisionData) -> float:
	"""Calcula la fuerza de combate de una división"""
	var base_strength = division.cantidad_total
	var moral_modifier = division.moral / 100.0
	var experience_modifier = (division.experiencia / 100.0) * 0.5 + 0.75
	
	return base_strength * moral_modifier * experience_modifier

func determine_battle_outcome(strength_ratio: float) -> String:
	"""Determina el resultado de la batalla basado en la relación de fuerzas"""
	if strength_ratio >= 2.0:
		return "decisive_victory"
	elif strength_ratio >= 1.5:
		return "victory"
	elif strength_ratio >= 1.2:
		return "pyrrhic_victory"
	elif strength_ratio >= 0.8:
		return "draw"
	else:
		return "defeat"

func apply_battle_effects(attacker: DivisionData, defender: DivisionData, outcome: String) -> Dictionary:
	"""Aplica los efectos de la batalla a las divisiones"""
	var outcome_config = combat_rules_config.get("battle_outcomes", {}).get(outcome, {})
	var result = {
		"attacker_name": attacker.nombre,
		"defender_name": defender.nombre,
		"attacker_losses": 0,
		"defender_losses": 0
	}
	
	if outcome_config.has("attacker_losses"):
		var loss_range = outcome_config["attacker_losses"]
		var loss_percent = randf_range(loss_range[0], loss_range[1])
		var losses = int(attacker.cantidad_total * loss_percent)
		attacker.cantidad_total = max(0, attacker.cantidad_total - losses)
		result["attacker_losses"] = losses
	
	if outcome_config.has("defender_losses"):
		var loss_range = outcome_config["defender_losses"]
		var loss_percent = randf_range(loss_range[0], loss_range[1])
		var losses = int(defender.cantidad_total * loss_percent)
		defender.cantidad_total = max(0, defender.cantidad_total - losses)
		result["defender_losses"] = losses
	
	# Aplicar cambios de moral
	if outcome_config.has("moral_change"):
		var moral_changes = outcome_config["moral_change"]
		if outcome in ["decisive_victory", "victory", "pyrrhic_victory"]:
			attacker.moral = min(100, attacker.moral + moral_changes["winner"])
			defender.moral = max(0, defender.moral + moral_changes["loser"])
		else:
			defender.moral = min(100, defender.moral + moral_changes["winner"])
			attacker.moral = max(0, attacker.moral + moral_changes["loser"])
	
	return result

func get_military_summary() -> Dictionary:
	"""Obtiene resumen del estado militar"""
	return {
		"active_battles": active_battles.size(),
		"recruitment_queue": recruitment_queue.size(),
		"available_unit_types": get_available_unit_types().size()
	}