extends Node

# EconomicIntegrationManager - Integración del sistema económico con otros sistemas del juego
# Maneja los efectos económicos en investigación, diplomacia y combate sin modificar sus implementaciones core

signal research_economic_effect(faction: String, research_id: String, cost: Dictionary, bonus: float)
signal diplomacy_economic_effect(faction: String, action: String, cost: Dictionary)
signal combat_economic_effect(faction: String, unit: Node, supply_status: String)

# === CONFIGURACIÓN ===
var integration_config: Dictionary = {}

# === INICIALIZACIÓN ===
func _ready():
	print("✓ EconomicIntegrationManager inicializando...")
	load_integration_config()
	setup_system_connections()
	print("✓ EconomicIntegrationManager listo")

func load_integration_config():
	"""Carga configuración de integración económica"""
	integration_config = {
		"research": {
			"base_cost_multiplier": 1.0,
			"resource_bonuses": {
				"biblias": 1.2,
				"oro": 1.1,
				"dinero": 1.0
			},
			"shortage_penalty": 0.7
		},
		"diplomacy": {
			"trade_efficiency": 1.0,
			"gift_multiplier": 1.5,
			"luxury_bonus": {
				"vino": 1.3,
				"tabaco": 1.2,
				"oro": 1.4
			}
		},
		"combat": {
			"supply_efficiency": 1.0,
			"ammunition_consumption": 1.0,
			"equipment_maintenance": 1.0,
			"morale_from_supplies": 1.0
		}
	}

func setup_system_connections():
	"""Configura conexiones con otros sistemas"""
	if EconomicManager:
		EconomicManager.resource_changed.connect(_on_resource_changed)
		EconomicManager.turn_processed.connect(_on_turn_processed)

# === INTEGRACIÓN CON INVESTIGACIÓN ===
func request_research_funding(faction: String, research_id: String, base_cost: Dictionary) -> Dictionary:
	"""Solicita fondos para investigación. Retorna el costo real y los bonos aplicables"""
	if not EconomicManager:
		return {"cost": base_cost, "bonus": 1.0, "can_afford": false}
	
	var config = integration_config.get("research", {})
	var multiplier = config.get("base_cost_multiplier", 1.0)
	var bonuses = config.get("resource_bonuses", {})
	
	# Calcular costo real
	var real_cost = {}
	for resource_id in base_cost:
		real_cost[resource_id] = int(base_cost[resource_id] * multiplier)
	
	# Verificar disponibilidad
	var can_afford = true
	for resource_id in real_cost:
		if EconomicManager.get_resource_amount(faction, resource_id) < real_cost[resource_id]:
			can_afford = false
			break
	
	# Calcular bono total por recursos disponibles
	var total_bonus = 1.0
	for resource_id in bonuses:
		var available = EconomicManager.get_resource_amount(faction, resource_id)
		if available > 0:
			# Bono basado en cantidad disponible (más recursos = mayor bono)
			var bonus_factor = min(available / 100.0, 1.0)  # Máximo bono al tener 100+ recursos
			total_bonus += (bonuses[resource_id] - 1.0) * bonus_factor
	
	return {
		"cost": real_cost,
		"bonus": total_bonus,
		"can_afford": can_afford
	}

func apply_research_cost(faction: String, research_id: String, cost: Dictionary) -> bool:
	"""Aplica el costo de investigación"""
	if not EconomicManager:
		return false
	
	# Intentar asignar recursos a tecnología
	var success = EconomicManager.allocate_resources(faction, "tecnologia", cost)
	if success:
		research_economic_effect.emit(faction, research_id, cost, 1.0)
	
	return success

func get_research_efficiency_bonus(faction: String) -> float:
	"""Obtiene el bono de eficiencia de investigación basado en recursos"""
	if not EconomicManager:
		return 1.0
	
	var config = integration_config.get("research", {})
	var bonuses = config.get("resource_bonuses", {})
	var total_bonus = 1.0
	
	for resource_id in bonuses:
		var allocated = EconomicManager.get_allocated_resources(faction, "tecnologia").get(resource_id, 0)
		if allocated > 0:
			total_bonus += (bonuses[resource_id] - 1.0) * min(allocated / 50.0, 1.0)
	
	return total_bonus

# === INTEGRACIÓN CON DIPLOMACIA ===
func calculate_trade_value(resource_from: String, amount_from: int, resource_to: String) -> int:
	"""Calcula el valor de intercambio entre recursos"""
	if not EconomicManager:
		return amount_from
	
	var res_from = EconomicManager.resource_definitions.get(resource_from)
	var res_to = EconomicManager.resource_definitions.get(resource_to)
	
	if not res_from or not res_to:
		return amount_from
	
	var value_from = res_from.base_value * amount_from
	var amount_to = int(value_from / res_to.base_value)
	
	# Aplicar eficiencia de comercio
	var trade_efficiency = integration_config.get("diplomacy", {}).get("trade_efficiency", 1.0)
	amount_to = int(amount_to * trade_efficiency)
	
	return max(1, amount_to)

func request_diplomatic_action(faction: String, action: String, target_faction: String, resources: Dictionary) -> Dictionary:
	"""Solicita una acción diplomática que requiere recursos"""
	if not EconomicManager:
		return {"can_afford": false, "effectiveness": 1.0}
	
	# Verificar disponibilidad de recursos
	var can_afford = true
	for resource_id in resources:
		if EconomicManager.get_resource_amount(faction, resource_id) < resources[resource_id]:
			can_afford = false
			break
	
	# Calcular efectividad basada en tipo de recursos
	var effectiveness = 1.0
	var luxury_bonuses = integration_config.get("diplomacy", {}).get("luxury_bonus", {})
	
	for resource_id in resources:
		if luxury_bonuses.has(resource_id):
			var amount = resources[resource_id]
			effectiveness += (luxury_bonuses[resource_id] - 1.0) * min(amount / 20.0, 1.0)
	
	return {
		"can_afford": can_afford,
		"effectiveness": effectiveness
	}

func apply_diplomatic_cost(faction: String, action: String, resources: Dictionary) -> bool:
	"""Aplica el costo de una acción diplomática"""
	if not EconomicManager:
		return false
	
	var success = EconomicManager.allocate_resources(faction, "diplomacia", resources)
	if success:
		diplomacy_economic_effect.emit(faction, action, resources)
	
	return success

# === INTEGRACIÓN CON COMBATE ===
func calculate_unit_supply_status(faction: String, unit: Node) -> Dictionary:
	"""Calcula el estado de suministros de una unidad"""
	if not EconomicManager or not unit:
		return {"status": "unknown", "effectiveness": 1.0}
	
	var unit_data = unit.get("data")
	if not unit_data:
		return {"status": "unknown", "effectiveness": 1.0}
	
	# Determinar recursos militares necesarios
	var required_resources = {
		"municion": 10,
		"polvora": 5,
		"pan": 8  # Comida para la tropa
	}
	
	# Verificar disponibilidad
	var total_availability = 0.0
	var resource_count = 0
	
	for resource_id in required_resources:
		var needed = required_resources[resource_id]
		var available = EconomicManager.get_resource_amount(faction, resource_id)
		var ratio = float(available) / float(needed)
		total_availability += min(ratio, 1.0)
		resource_count += 1
	
	var supply_ratio = total_availability / resource_count if resource_count > 0 else 0.0
	
	# Determinar estado
	var status = "well_supplied"
	var effectiveness = 1.0
	
	if supply_ratio < 0.3:
		status = "critically_low"
		effectiveness = 0.6
	elif supply_ratio < 0.6:
		status = "low_supplies"
		effectiveness = 0.8
	elif supply_ratio < 0.9:
		status = "adequate"
		effectiveness = 0.95
	
	return {
		"status": status,
		"effectiveness": effectiveness,
		"supply_ratio": supply_ratio
	}

func consume_combat_resources(faction: String, unit: Node, combat_intensity: String) -> bool:
	"""Consume recursos durante el combate"""
	if not EconomicManager or not unit:
		return false
	
	var consumption = {}
	match combat_intensity:
		"light":
			consumption = {"municion": 2, "polvora": 1}
		"moderate":
			consumption = {"municion": 5, "polvora": 2, "pan": 1}
		"heavy":
			consumption = {"municion": 10, "polvora": 5, "pan": 3}
		"siege":
			consumption = {"municion": 15, "polvora": 8, "pan": 5, "cañones": 1}
	
	# Intentar consumir recursos
	var can_consume = true
	for resource_id in consumption:
		if EconomicManager.get_resource_amount(faction, resource_id) < consumption[resource_id]:
			can_consume = false
			break
	
	if can_consume:
		for resource_id in consumption:
			EconomicManager.subtract_resource(faction, resource_id, consumption[resource_id])
		
		combat_economic_effect.emit(faction, unit, "resources_consumed")
		return true
	else:
		combat_economic_effect.emit(faction, unit, "insufficient_supplies")
		return false

func apply_combat_economic_effects(faction: String, combat_result: String, units_involved: Array):
	"""Aplica efectos económicos post-combate"""
	if not EconomicManager:
		return
	
	match combat_result:
		"victory":
			# Bonus por victoria (posible botín)
			EconomicManager.add_resource(faction, "dinero", randi_range(10, 50))
			EconomicManager.add_resource(faction, "municion", randi_range(5, 20))
		"defeat":
			# Pérdida por derrota
			EconomicManager.modify_resource_income(faction, "dinero", -5.0)
		"tactical_victory":
			# Victoria táctica - menor bonificación
			EconomicManager.add_resource(faction, "dinero", randi_range(5, 25))

# === CALLBACKS DE EVENTOS ECONÓMICOS ===
func _on_resource_changed(resource_id: String, old_amount: int, new_amount: int):
	"""Callback cuando cambia un recurso"""
	# Verificar si afecta otros sistemas
	check_research_impact(resource_id, new_amount)
	check_diplomatic_impact(resource_id, new_amount)
	check_combat_impact(resource_id, new_amount)

func check_research_impact(resource_id: String, new_amount: int):
	"""Verifica impacto en investigación"""
	var research_resources = ["biblias", "oro", "dinero"]
	if resource_id in research_resources and new_amount < 10:
		# Alertar sobre posible impacto en investigación
		if EconomicManager:
			EconomicManager.economic_alert.emit("research_impact", resource_id, 
				"Bajos recursos de " + resource_id + " pueden afectar la investigación")

func check_diplomatic_impact(resource_id: String, new_amount: int):
	"""Verifica impacto en diplomacia"""
	var diplomatic_resources = ["oro", "vino", "tabaco", "dinero"]
	if resource_id in diplomatic_resources and new_amount < 5:
		if EconomicManager:
			EconomicManager.economic_alert.emit("diplomacy_impact", resource_id,
				"Escasez de " + resource_id + " limitará opciones diplomáticas")

func check_combat_impact(resource_id: String, new_amount: int):
	"""Verifica impacto en combate"""
	var military_resources = ["municion", "polvora", "pan"]
	if resource_id in military_resources and new_amount < 20:
		if EconomicManager:
			EconomicManager.economic_alert.emit("combat_impact", resource_id,
				"Suministros militares bajos: " + resource_id)

func _on_turn_processed(turn_number: int):
	"""Callback cuando se procesa un turno"""
	# Aplicar efectos económicos gradual de asignaciones
	apply_turn_based_effects()

func apply_turn_based_effects():
	"""Aplica efectos económicos basados en turnos"""
	if not EconomicManager or not FactionManager:
		return
	
	for faction_name in FactionManager.facciones.keys():
		apply_faction_turn_effects(faction_name)

func apply_faction_turn_effects(faction_name: String):
	"""Aplica efectos de turno para una facción específica"""
	# Bonos por asignaciones a investigación
	var tech_allocation = EconomicManager.get_allocated_resources(faction_name, "tecnologia")
	for resource_id in tech_allocation:
		var amount = tech_allocation[resource_id]
		if amount > 0:
			# Convertir recursos asignados en bono de investigación
			var bonus = amount * 0.1  # 10% del recurso asignado como bono
			EconomicManager.modify_resource_income(faction_name, "biblias", bonus)
	
	# Bonos por asignaciones a diplomacia
	var diplo_allocation = EconomicManager.get_allocated_resources(faction_name, "diplomacia")
	if not diplo_allocation.is_empty():
		# Mejorar relaciones comerciales (aumentar eficiencia de intercambio)
		integration_config["diplomacy"]["trade_efficiency"] += 0.01
	
	# Costos por asignaciones militares
	var military_allocation = EconomicManager.get_allocated_resources(faction_name, "unidades")
	for resource_id in military_allocation:
		var amount = military_allocation[resource_id]
		if amount > 0:
			# Aumentar gastos de mantenimiento militar
			EconomicManager.modify_resource_expenses(faction_name, resource_id, amount * 0.05)

# === MÉTODOS PÚBLICOS DE INTEGRACIÓN ===
func get_system_economic_status(system_name: String, faction: String) -> Dictionary:
	"""Obtiene el estado económico de un sistema específico"""
	match system_name:
		"research":
			return {
				"efficiency_bonus": get_research_efficiency_bonus(faction),
				"allocated_resources": EconomicManager.get_allocated_resources(faction, "tecnologia") if EconomicManager else {}
			}
		"diplomacy":
			return {
				"trade_efficiency": integration_config.get("diplomacy", {}).get("trade_efficiency", 1.0),
				"allocated_resources": EconomicManager.get_allocated_resources(faction, "diplomacia") if EconomicManager else {}
			}
		"combat":
			return {
				"supply_efficiency": integration_config.get("combat", {}).get("supply_efficiency", 1.0),
				"allocated_resources": EconomicManager.get_allocated_resources(faction, "unidades") if EconomicManager else {}
			}
		_:
			return {}

func modify_system_economic_parameter(system_name: String, parameter: String, value: float):
	"""Modifica un parámetro económico de un sistema"""
	if not integration_config.has(system_name):
		integration_config[system_name] = {}
	
	integration_config[system_name][parameter] = value
	print("✓ Parámetro económico modificado: ", system_name, ".", parameter, " = ", value)