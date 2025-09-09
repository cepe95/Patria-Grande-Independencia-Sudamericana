extends Node
class_name RecruitmentManager

# Gestiona el reclutamiento y mantenimiento de unidades militares
# Implementa los costos definidos en docs/CostosUnidades.md

signal unit_recruited(unit_data: UnitData, town_instance: Node)
signal recruitment_failed(reason: String, required_resources: Dictionary)
signal maintenance_applied(units_count: int, total_cost: Dictionary)
signal maintenance_failed(units_without_maintenance: Array)

var resource_manager: ResourceManager

func _ready():
	# Conectar al ResourceManager
	resource_manager = get_node("/root/ResourceManager")
	if not resource_manager:
		print("⚠ RecruitmentManager: No se encontró ResourceManager")

func can_recruit_unit(unit_data: UnitData, town_instance: Node) -> Dictionary:
	"""
	Verifica si se puede reclutar una unidad en una ciudad específica.
	Retorna un diccionario con 'success' (bool) y 'missing_resources' (Dictionary)
	"""
	var result = {
		"success": false,
		"missing_resources": {}
	}
	
	if not unit_data:
		result["error"] = "UnitData inválido"
		return result
	
	if not town_instance:
		result["error"] = "TownInstance inválido"
		return result
	
	# Verificar recursos de reclutamiento
	var town_resources = get_town_resources(town_instance)
	var recruitment_costs = unit_data.costos_reclutamiento
	
	for resource in recruitment_costs:
		var required = recruitment_costs[resource]
		var available = town_resources.get(resource, 0)
		
		if available < required:
			result["missing_resources"][resource] = required - available
	
	result["success"] = result["missing_resources"].is_empty()
	return result

func recruit_unit(unit_data: UnitData, town_instance: Node) -> bool:
	"""
	Recluta una unidad en la ciudad especificada, descontando los recursos necesarios.
	Retorna true si el reclutamiento fue exitoso.
	"""
	var recruitment_check = can_recruit_unit(unit_data, town_instance)
	
	if not recruitment_check["success"]:
		var reason = "Recursos insuficientes: " + str(recruitment_check.get("missing_resources", {}))
		recruitment_failed.emit(reason, recruitment_check.get("missing_resources", {}))
		return false
	
	# Descontar recursos de reclutamiento
	var recruitment_costs = unit_data.costos_reclutamiento
	if not deduct_town_resources(town_instance, recruitment_costs):
		recruitment_failed.emit("Error al descontar recursos", recruitment_costs)
		return false
	
	# Emitir señal de reclutamiento exitoso
	unit_recruited.emit(unit_data, town_instance)
	
	print("✓ Unidad reclutada: %s en %s" % [unit_data.nombre, town_instance.town_data.nombre])
	return true

func apply_maintenance_costs(units: Array, towns: Array) -> Dictionary:
	"""
	Aplica los costos de mantenimiento a todas las unidades.
	Retorna estadísticas del mantenimiento aplicado.
	"""
	var total_maintenance_cost = {}
	var units_processed = 0
	var units_without_maintenance = []
	
	for unit in units:
		if not unit or not unit.get("data"):
			continue
		
		var unit_data = unit.data
		var maintenance_costs = unit_data.costos_mantenimiento
		
		# Buscar la ciudad más cercana que pueda proporcionar mantenimiento
		var supporting_town = find_supporting_town(unit, towns)
		
		if supporting_town:
			# Intentar aplicar costos de mantenimiento
			if can_afford_maintenance(supporting_town, maintenance_costs):
				deduct_town_resources(supporting_town, maintenance_costs)
				
				# Sumar al costo total para estadísticas
				for resource in maintenance_costs:
					total_maintenance_cost[resource] = total_maintenance_cost.get(resource, 0) + maintenance_costs[resource]
				
				units_processed += 1
			else:
				# La unidad no puede recibir mantenimiento adecuado
				units_without_maintenance.append(unit)
				apply_maintenance_penalty(unit)
		else:
			# No hay ciudad que pueda dar soporte
			units_without_maintenance.append(unit)
			apply_maintenance_penalty(unit)
	
	# Emitir señales
	if units_processed > 0:
		maintenance_applied.emit(units_processed, total_maintenance_cost)
	
	if not units_without_maintenance.is_empty():
		maintenance_failed.emit(units_without_maintenance)
	
	return {
		"units_processed": units_processed,
		"total_cost": total_maintenance_cost,
		"units_without_maintenance": units_without_maintenance.size()
	}

func find_supporting_town(unit_instance: Node, towns: Array) -> Node:
	"""
	Encuentra la ciudad más cercana que puede proporcionar mantenimiento a la unidad.
	"""
	var closest_town = null
	var closest_distance = INF
	
	for town in towns:
		if not town or not town.get("town_data"):
			continue
		
		# Solo ciudades controladas pueden dar soporte
		if town.town_data.estado != "controlado":
			continue
		
		var distance = unit_instance.position.distance_to(town.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_town = town
	
	return closest_town

func can_afford_maintenance(town_instance: Node, maintenance_costs: Dictionary) -> bool:
	"""
	Verifica si una ciudad puede permitirse los costos de mantenimiento.
	"""
	var town_resources = get_town_resources(town_instance)
	
	for resource in maintenance_costs:
		var required = maintenance_costs[resource]
		var available = town_resources.get(resource, 0)
		
		if available < required:
			return false
	
	return true

func apply_maintenance_penalty(unit_instance: Node):
	"""
	Aplica penalizaciones a unidades que no reciben mantenimiento adecuado.
	"""
	if not unit_instance or not unit_instance.get("data"):
		return
	
	var unit_data = unit_instance.data
	
	# Reducir moral por falta de mantenimiento
	if unit_data.has("moral"):
		unit_data.moral = max(0, unit_data.moral - 5)
	
	# Reducir cantidad (deserción)
	if unit_data.has("cantidad"):
		var desertion_rate = 0.02  # 2% de deserción por turno sin mantenimiento
		var losses = int(unit_data.cantidad * desertion_rate)
		unit_data.cantidad = max(1, unit_data.cantidad - losses)
	
	print("⚠ Unidad sin mantenimiento: %s (Moral: %d, Cantidad: %d)" % [
		unit_data.nombre, 
		unit_data.get("moral", 0), 
		unit_data.get("cantidad", 0)
	])

func get_town_resources(town_instance: Node) -> Dictionary:
	"""
	Obtiene los recursos disponibles en una ciudad.
	Por ahora usa un sistema simplificado, en el futuro se conectaría al sistema real de recursos.
	"""
	var resources = {}
	
	if not town_instance or not town_instance.get("town_data"):
		return resources
	
	var town_data = town_instance.town_data
	
	# Sistema simplificado de recursos basado en el tipo de ciudad
	match town_data.tipo:
		"villa", "pueblo", "ciudad_pequeña":
			resources = {
				"Pan": 500, "Carne": 200, "Vino": 100, "Aguardiente": 50,
				"Tabaco": 100, "Biblias": 10, "Sables": 20, "Mosquetes": 20,
				"Municion": 100, "Caballos": 50, "Cañones": 5
			}
		"ciudad_mediana":
			resources = {
				"Pan": 1500, "Carne": 600, "Vino": 300, "Aguardiente": 150,
				"Tabaco": 300, "Biblias": 30, "Sables": 60, "Mosquetes": 60,
				"Municion": 300, "Caballos": 150, "Cañones": 15
			}
		"ciudad_grande":
			resources = {
				"Pan": 4500, "Carne": 1800, "Vino": 900, "Aguardiente": 450,
				"Tabaco": 900, "Biblias": 90, "Sables": 180, "Mosquetes": 180,
				"Municion": 900, "Caballos": 450, "Cañones": 45
			}
		"capital", "metropolis":
			resources = {
				"Pan": 10000, "Carne": 4000, "Vino": 2000, "Aguardiente": 1000,
				"Tabaco": 2000, "Biblias": 200, "Sables": 400, "Mosquetes": 400,
				"Municion": 2000, "Caballos": 1000, "Cañones": 100
			}
		_:
			# Ciudad desconocida, recursos mínimos
			resources = {
				"Pan": 100, "Carne": 50, "Vino": 25, "Aguardiente": 10,
				"Tabaco": 25, "Biblias": 2, "Sables": 5, "Mosquetes": 5,
				"Municion": 25, "Caballos": 10, "Cañones": 1
			}
	
	return resources

func deduct_town_resources(town_instance: Node, costs: Dictionary) -> bool:
	"""
	Descuenta recursos de una ciudad. 
	Por ahora es una implementación simplificada.
	En el futuro se conectaría al sistema real de gestión de recursos.
	"""
	if not town_instance:
		return false
	
	# Por ahora solo imprimimos el descuento
	print("🏛 Recursos descontados de %s:" % town_instance.town_data.nombre)
	for resource in costs:
		print("   - %s: %s" % [resource, costs[resource]])
	
	# TODO: Implementar descuento real cuando el sistema de recursos esté completo
	return true

func get_available_units_for_recruitment(town_instance: Node) -> Array:
	"""
	Retorna las unidades que se pueden reclutar en una ciudad específica.
	Se basa en el tipo de ciudad y sus capacidades.
	"""
	var available_units = []
	
	if not town_instance or not town_instance.get("town_data"):
		return available_units
	
	var town_data = town_instance.town_data
	
	# Cargar unidades según el tipo de ciudad
	match town_data.tipo:
		"villa", "pueblo", "ciudad_pequeña":
			# Solo unidades básicas
			available_units.append(load("res://Data/Units/Infantería/Pelotón.tres"))
			available_units.append(load("res://Data/Units/Caballería/Escuadrón.tres"))
			available_units.append(load("res://Data/Units/Artillería/Batería_Pequeña.tres"))
		
		"ciudad_mediana":
			# Unidades básicas y medianas
			available_units.append(load("res://Data/Units/Infantería/Pelotón.tres"))
			available_units.append(load("res://Data/Units/Infantería/Compañia.tres"))
			available_units.append(load("res://Data/Units/Caballería/Escuadrón.tres"))
			available_units.append(load("res://Data/Units/Caballería/Compañia.tres"))
			available_units.append(load("res://Data/Units/Artillería/Batería_Pequeña.tres"))
			available_units.append(load("res://Data/Units/Artillería/Batería_Mediana.tres"))
		
		"ciudad_grande":
			# Unidades básicas, medianas y grandes
			available_units.append(load("res://Data/Units/Infantería/Pelotón.tres"))
			available_units.append(load("res://Data/Units/Infantería/Compañia.tres"))
			available_units.append(load("res://Data/Units/Infantería/Batallón.tres"))
			available_units.append(load("res://Data/Units/Caballería/Escuadrón.tres"))
			available_units.append(load("res://Data/Units/Caballería/Compañia.tres"))
			available_units.append(load("res://Data/Units/Caballería/Regimiento.tres"))
			available_units.append(load("res://Data/Units/Artillería/Batería_Pequeña.tres"))
			available_units.append(load("res://Data/Units/Artillería/Batería_Mediana.tres"))
			available_units.append(load("res://Data/Units/Artillería/Batería_Grande.tres"))
		
		"capital", "metropolis":
			# Todas las unidades
			available_units.append(load("res://Data/Units/Infantería/Pelotón.tres"))
			available_units.append(load("res://Data/Units/Infantería/Compañia.tres"))
			available_units.append(load("res://Data/Units/Infantería/Batallón.tres"))
			available_units.append(load("res://Data/Units/Infantería/Regimiento.tres"))
			available_units.append(load("res://Data/Units/Caballería/Escuadrón.tres"))
			available_units.append(load("res://Data/Units/Caballería/Compañia.tres"))
			available_units.append(load("res://Data/Units/Caballería/Regimiento.tres"))
			available_units.append(load("res://Data/Units/Artillería/Batería_Pequeña.tres"))
			available_units.append(load("res://Data/Units/Artillería/Batería_Mediana.tres"))
			available_units.append(load("res://Data/Units/Artillería/Batería_Grande.tres"))
	
	return available_units