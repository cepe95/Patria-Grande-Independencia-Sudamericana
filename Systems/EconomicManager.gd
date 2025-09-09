extends Node

# EconomicManager - Sistema económico central del juego
# Maneja recursos, ingresos, gastos, asignaciones y alertas económicas

signal resource_changed(resource_id: String, old_amount: int, new_amount: int)
signal economic_alert(alert_type: String, resource_id: String, message: String)
signal turn_processed(turn_number: int)

# === CONFIGURACIÓN ===
const CONFIG_PATH = "res://Data/Config/economic_config.json"
const SHORTAGE_THRESHOLD = 0.2  # 20% del máximo para alerta de escasez
const SURPLUS_THRESHOLD = 0.8   # 80% del máximo para alerta de superávit
const DRASTIC_CHANGE_THRESHOLD = 0.3  # 30% de cambio para alerta

# === DATOS ECONÓMICOS ===
var resource_definitions: Dictionary = {}  # id -> ResourceData
var faction_resources: Dictionary = {}  # faction_name -> {resource_id -> amount}
var resource_income: Dictionary = {}  # faction_name -> {resource_id -> income_per_turn}
var resource_expenses: Dictionary = {}  # faction_name -> {resource_id -> expenses_per_turn}
var resource_allocations: Dictionary = {}  # faction_name -> {category -> {resource_id -> amount}}

var current_turn: int = 1
var economic_config: Dictionary = {}

# === INICIALIZACIÓN ===
func _ready():
	print("✓ EconomicManager inicializando...")
	load_economic_config()
	load_resource_definitions()
	initialize_faction_economies()
	print("✓ EconomicManager listo")

func load_economic_config():
	"""Carga la configuración económica desde archivo JSON"""
	var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			economic_config = json.data
			print("✓ Configuración económica cargada")
		else:
			print("⚠ Error parseando configuración económica, usando valores por defecto")
			create_default_economic_config()
	else:
		print("⚠ Archivo de configuración económica no encontrado, creando configuración por defecto")
		create_default_economic_config()

func create_default_economic_config():
	"""Crea configuración económica por defecto"""
	economic_config = {
		"global_modifiers": {
			"base_income_multiplier": 1.0,
			"base_expense_multiplier": 1.0,
			"trade_efficiency": 1.0
		},
		"resource_interactions": {
			"dinero": {
				"trade_conversion_rate": 1.0,
				"maintenance_cost": 0.1
			},
			"comida": {
				"population_consumption_rate": 1.0,
				"morale_bonus": 5.0
			},
			"municion": {
				"military_consumption_rate": 2.0,
				"combat_effectiveness": 1.2
			}
		},
		"economic_events": {
			"shortage_penalty": 0.8,
			"surplus_bonus": 1.1,
			"trade_disruption": 0.7
		}
	}
	save_economic_config()

func save_economic_config():
	"""Guarda la configuración económica actual"""
	var file = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(economic_config, "\t"))
		file.close()
		print("✓ Configuración económica guardada")

func load_resource_definitions():
	"""Carga las definiciones de recursos desde los archivos existentes"""
	# Integrar con ResourceManager existente para mantener compatibilidad
	var resource_manager = get_node_or_null("/root/ResourceManager")
	if not resource_manager:
		resource_manager = ResourceManager.new()
		add_child(resource_manager)
	
	# Crear definiciones basadas en recursos existentes
	create_resource_definitions_from_existing()

func create_resource_definitions_from_existing():
	"""Crea definiciones de ResourceData basadas en la estructura existente"""
	var categories = ["alimentacion", "economia", "militar", "cultural"]
	
	for category in categories:
		var path = "res://Data/Resources/" + category.capitalize() + "/"
		var dir = DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tres"):
					var resource_id = file_name.get_basename().to_lower()
					create_resource_definition(resource_id, category, file_name.get_basename())
				file_name = dir.get_next()
			dir.list_dir_end()

func create_resource_definition(id: String, category: String, display_name: String):
	"""Crea una definición de recurso"""
	var resource_data = ResourceData.new()
	resource_data.id = id
	resource_data.nombre = display_name
	resource_data.categoria = category
	
	# Configurar valores específicos por tipo de recurso
	match category:
		"economia":
			resource_data.base_value = 1.0
			resource_data.production_rate = get_config_value("resource_interactions." + id + ".base_production", 10.0)
			resource_data.consumption_rate = get_config_value("resource_interactions." + id + ".base_consumption", 5.0)
		"alimentacion":
			resource_data.base_value = 0.5
			resource_data.production_rate = get_config_value("resource_interactions." + id + ".base_production", 15.0)
			resource_data.consumption_rate = get_config_value("resource_interactions." + id + ".base_consumption", 10.0)
			resource_data.affects_morale = 5.0
		"militar":
			resource_data.base_value = 2.0
			resource_data.production_rate = get_config_value("resource_interactions." + id + ".base_production", 5.0)
			resource_data.consumption_rate = get_config_value("resource_interactions." + id + ".base_consumption", 8.0)
		"cultural":
			resource_data.base_value = 1.5
			resource_data.production_rate = get_config_value("resource_interactions." + id + ".base_production", 3.0)
			resource_data.consumption_rate = get_config_value("resource_interactions." + id + ".base_consumption", 1.0)
			resource_data.affects_research = 3.0
			resource_data.affects_diplomacy = 2.0
	
	resource_definitions[id] = resource_data

func initialize_faction_economies():
	"""Inicializa las economías de las facciones"""
	if not FactionManager:
		print("⚠ FactionManager no disponible")
		return
	
	for faction_name in FactionManager.facciones.keys():
		initialize_faction_economy(faction_name)

func initialize_faction_economy(faction_name: String):
	"""Inicializa la economía de una facción específica"""
	faction_resources[faction_name] = {}
	resource_income[faction_name] = {}
	resource_expenses[faction_name] = {}
	resource_allocations[faction_name] = {
		"construccion": {},
		"unidades": {},
		"tecnologia": {},
		"diplomacia": {}
	}
	
	# Establecer recursos iniciales basados en FactionManager
	var faction_data = FactionManager.obtener_faccion(faction_name)
	if faction_data:
		for resource_id in faction_data.recursos:
			var amount = faction_data.recursos[resource_id]
			set_resource_amount(faction_name, resource_id, amount)
			
			# Establecer ingresos/gastos base
			if resource_definitions.has(resource_id):
				var res_def = resource_definitions[resource_id]
				resource_income[faction_name][resource_id] = res_def.production_rate
				resource_expenses[faction_name][resource_id] = res_def.consumption_rate

# === GESTIÓN DE RECURSOS ===
func get_resource_amount(faction_name: String, resource_id: String) -> int:
	"""Obtiene la cantidad de un recurso para una facción"""
	if not faction_resources.has(faction_name):
		return 0
	return faction_resources[faction_name].get(resource_id, 0)

func set_resource_amount(faction_name: String, resource_id: String, amount: int):
	"""Establece la cantidad de un recurso para una facción"""
	if not faction_resources.has(faction_name):
		faction_resources[faction_name] = {}
	
	var old_amount = faction_resources[faction_name].get(resource_id, 0)
	faction_resources[faction_name][resource_id] = max(0, amount)
	
	# Verificar límites de almacenamiento
	if resource_definitions.has(resource_id):
		var res_def = resource_definitions[resource_id]
		if res_def.storage_limit > 0:
			faction_resources[faction_name][resource_id] = min(
				faction_resources[faction_name][resource_id], 
				res_def.storage_limit
			)
	
	# Emitir señal si cambió
	if old_amount != faction_resources[faction_name][resource_id]:
		resource_changed.emit(resource_id, old_amount, faction_resources[faction_name][resource_id])
		check_resource_alerts(faction_name, resource_id, old_amount, faction_resources[faction_name][resource_id])

func add_resource(faction_name: String, resource_id: String, amount: int):
	"""Agrega cantidad a un recurso"""
	var current = get_resource_amount(faction_name, resource_id)
	set_resource_amount(faction_name, resource_id, current + amount)

func subtract_resource(faction_name: String, resource_id: String, amount: int) -> bool:
	"""Resta cantidad de un recurso. Retorna true si se pudo realizar"""
	var current = get_resource_amount(faction_name, resource_id)
	if current >= amount:
		set_resource_amount(faction_name, resource_id, current - amount)
		return true
	return false

func get_resource_income(faction_name: String, resource_id: String) -> float:
	"""Obtiene el ingreso por turno de un recurso"""
	if not resource_income.has(faction_name):
		return 0.0
	return resource_income[faction_name].get(resource_id, 0.0)

func get_resource_expenses(faction_name: String, resource_id: String) -> float:
	"""Obtiene los gastos por turno de un recurso"""
	if not resource_expenses.has(faction_name):
		return 0.0
	return resource_expenses[faction_name].get(resource_id, 0.0)

func get_resource_net_income(faction_name: String, resource_id: String) -> float:
	"""Obtiene el ingreso neto por turno de un recurso"""
	return get_resource_income(faction_name, resource_id) - get_resource_expenses(faction_name, resource_id)

# === ASIGNACIÓN DE RECURSOS ===
func allocate_resources(faction_name: String, category: String, resource_allocations_dict: Dictionary) -> bool:
	"""Asigna recursos a una categoría específica (construccion, unidades, tecnologia, diplomacia)"""
	# Verificar que se tienen los recursos necesarios
	for resource_id in resource_allocations_dict:
		var amount = resource_allocations_dict[resource_id]
		if get_resource_amount(faction_name, resource_id) < amount:
			economic_alert.emit("error", resource_id, "Recursos insuficientes para asignación: " + resource_id)
			return false
	
	# Realizar asignación
	for resource_id in resource_allocations_dict:
		var amount = resource_allocations_dict[resource_id]
		subtract_resource(faction_name, resource_id, amount)
		
		if not resource_allocations[faction_name][category].has(resource_id):
			resource_allocations[faction_name][category][resource_id] = 0
		resource_allocations[faction_name][category][resource_id] += amount
	
	return true

func get_allocated_resources(faction_name: String, category: String) -> Dictionary:
	"""Obtiene los recursos asignados a una categoría"""
	if not resource_allocations.has(faction_name) or not resource_allocations[faction_name].has(category):
		return {}
	return resource_allocations[faction_name][category]

func deallocate_resources(faction_name: String, category: String, resource_id: String, amount: int):
	"""Desasigna recursos de una categoría"""
	if not resource_allocations.has(faction_name) or not resource_allocations[faction_name].has(category):
		return
	
	var allocated = resource_allocations[faction_name][category].get(resource_id, 0)
	var to_return = min(allocated, amount)
	
	resource_allocations[faction_name][category][resource_id] -= to_return
	add_resource(faction_name, resource_id, to_return)

# === PROCESAMIENTO DE TURNOS ===
func process_turn():
	"""Procesa un turno económico completo"""
	current_turn += 1
	
	for faction_name in faction_resources.keys():
		process_faction_turn(faction_name)
	
	turn_processed.emit(current_turn)
	print("✓ Turno económico procesado: ", current_turn)

func process_faction_turn(faction_name: String):
	"""Procesa el turno económico para una facción"""
	# Aplicar ingresos y gastos
	for resource_id in resource_definitions.keys():
		var income = get_resource_income(faction_name, resource_id)
		var expenses = get_resource_expenses(faction_name, resource_id)
		var net_change = income - expenses
		
		if net_change != 0:
			add_resource(faction_name, resource_id, int(net_change))
	
	# Aplicar efectos de asignaciones
	apply_allocation_effects(faction_name)

func apply_allocation_effects(faction_name: String):
	"""Aplica los efectos de las asignaciones de recursos"""
	# Placeholder para efectos específicos de asignaciones
	# Aquí se implementarían los beneficios de asignar recursos a diferentes categorías
	pass

# === SISTEMA DE ALERTAS ===
func check_resource_alerts(faction_name: String, resource_id: String, old_amount: int, new_amount: int):
	"""Verifica y emite alertas económicas"""
	if not resource_definitions.has(resource_id):
		return
	
	var res_def = resource_definitions[resource_id]
	
	# Alerta de escasez
	if res_def.storage_limit > 0:
		var percentage = float(new_amount) / float(res_def.storage_limit)
		if percentage <= SHORTAGE_THRESHOLD:
			economic_alert.emit("shortage", resource_id, 
				"Escasez de " + res_def.get_display_name() + " (" + str(new_amount) + "/" + str(res_def.storage_limit) + ")")
		elif percentage >= SURPLUS_THRESHOLD:
			economic_alert.emit("surplus", resource_id,
				"Superávit de " + res_def.get_display_name() + " (" + str(new_amount) + "/" + str(res_def.storage_limit) + ")")
	
	# Alerta de cambio brusco
	if old_amount > 0:
		var change_percentage = abs(float(new_amount - old_amount)) / float(old_amount)
		if change_percentage >= DRASTIC_CHANGE_THRESHOLD:
			var change_type = "aumento" if new_amount > old_amount else "disminución"
			economic_alert.emit("drastic_change", resource_id,
				"Cambio brusco en " + res_def.get_display_name() + ": " + change_type + " del " + str(int(change_percentage * 100)) + "%")

# === UTILIDADES ===
func get_config_value(path: String, default_value):
	"""Obtiene un valor de configuración usando path con puntos"""
	var keys = path.split(".")
	var current = economic_config
	
	for key in keys:
		if current.has(key):
			current = current[key]
		else:
			return default_value
	
	return current

func get_all_faction_resources(faction_name: String) -> Dictionary:
	"""Obtiene todos los recursos de una facción"""
	return faction_resources.get(faction_name, {})

func get_faction_economic_summary(faction_name: String) -> Dictionary:
	"""Obtiene un resumen económico completo de una facción"""
	var summary = {
		"recursos": get_all_faction_resources(faction_name),
		"ingresos": resource_income.get(faction_name, {}),
		"gastos": resource_expenses.get(faction_name, {}),
		"asignaciones": resource_allocations.get(faction_name, {}),
		"recursos_netos": {}
	}
	
	# Calcular ingresos netos
	for resource_id in resource_definitions.keys():
		summary.recursos_netos[resource_id] = get_resource_net_income(faction_name, resource_id)
	
	return summary

# === INTEGRACIÓN CON OTROS SISTEMAS ===
func modify_resource_income(faction_name: String, resource_id: String, modifier: float):
	"""Modifica el ingreso de un recurso (usado por investigación, diplomacia, etc.)"""
	if not resource_income.has(faction_name):
		resource_income[faction_name] = {}
	
	if not resource_income[faction_name].has(resource_id):
		resource_income[faction_name][resource_id] = 0.0
	
	resource_income[faction_name][resource_id] += modifier

func modify_resource_expenses(faction_name: String, resource_id: String, modifier: float):
	"""Modifica los gastos de un recurso"""
	if not resource_expenses.has(faction_name):
		resource_expenses[faction_name] = {}
	
	if not resource_expenses[faction_name].has(resource_id):
		resource_expenses[faction_name][resource_id] = 0.0
	
	resource_expenses[faction_name][resource_id] += modifier