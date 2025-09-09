extends Node

# ResearchManager - Sistema de investigación científica y tecnológica
# Maneja tecnologías, proyectos de investigación e integración con otros sistemas

signal research_completed(technology_id: String, faction_name: String)
signal research_started(technology_id: String, faction_name: String)
signal research_progress_updated(technology_id: String, faction_name: String, progress: float)
signal new_technology_available(technology_id: String, faction_name: String)

# Datos de tecnologías cargadas desde archivos de configuración
var available_technologies: Dictionary = {}
var technology_trees: Dictionary = {}

# Proyectos de investigación activos por facción
var active_projects: Dictionary = {}  # {"Patriota": [ResearchProject, ...], "Realista": [...]}

# Tecnologías completadas por facción
var completed_technologies: Dictionary = {}  # {"Patriota": ["tech1", "tech2"], "Realista": [...]}

# Configuración del sistema
var base_research_points_per_turn: int = 10
var max_concurrent_projects: int = 3

func _ready():
	print("✓ ResearchManager inicializado")
	load_all_technologies()
	initialize_faction_research()

# === CARGA DE DATOS ===

func load_all_technologies():
	"""Carga todas las tecnologías desde los archivos de configuración"""
	load_technologies_from_file("res://Data/Research/military_technologies.json")
	load_technologies_from_file("res://Data/Research/economic_technologies.json") 
	load_technologies_from_file("res://Data/Research/diplomatic_technologies.json")
	
	build_technology_trees()
	print("✓ Cargadas %d tecnologías" % available_technologies.size())

func load_technologies_from_file(file_path: String):
	"""Carga tecnologías desde un archivo JSON específico"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("⚠ No se pudo cargar archivo de tecnologías: %s" % file_path)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		print("⚠ Error al parsear JSON en %s" % file_path)
		return
	
	var data = json.data
	if not data.has("technologies"):
		print("⚠ Archivo JSON no tiene sección 'technologies': %s" % file_path)
		return
	
	for tech_data in data["technologies"]:
		var tech = create_technology_from_data(tech_data)
		if tech:
			available_technologies[tech.id] = tech

func create_technology_from_data(data: Dictionary) -> TechnologyData:
	"""Crea un objeto TechnologyData desde datos del JSON"""
	var tech = TechnologyData.new()
	
	tech.id = data.get("id", "")
	tech.name = data.get("name", "")
	tech.description = data.get("description", "")
	tech.category = data.get("category", "")
	tech.research_cost = data.get("research_cost", 100)
	tech.research_time = data.get("research_time", 5)
	tech.required_technologies = data.get("required_technologies", [])
	tech.required_resources = data.get("required_resources", {})
	tech.effects = data.get("effects", {})
	tech.military_benefits = data.get("military_benefits", {})
	tech.economic_benefits = data.get("economic_benefits", {})
	tech.diplomatic_benefits = data.get("diplomatic_benefits", {})
	tech.icon_path = data.get("icon_path", "")
	tech.era = data.get("era", "colonial")
	tech.is_secret = data.get("is_secret", false)
	
	return tech

func build_technology_trees():
	"""Construye los árboles de tecnología organizados por categoría"""
	technology_trees = {
		"militar": [],
		"economia": [], 
		"diplomacia": [],
		"cultural": []
	}
	
	for tech_id in available_technologies:
		var tech = available_technologies[tech_id]
		if technology_trees.has(tech.category):
			technology_trees[tech.category].append(tech)

func initialize_faction_research():
	"""Inicializa el sistema de investigación para todas las facciones"""
	active_projects["Patriota"] = []
	active_projects["Realista"] = []
	completed_technologies["Patriota"] = []
	completed_technologies["Realista"] = []

# === GESTIÓN DE INVESTIGACIÓN ===

func start_research(technology_id: String, faction_name: String, assigned_researchers: int = 1) -> bool:
	"""Inicia un nuevo proyecto de investigación"""
	
	if not available_technologies.has(technology_id):
		print("⚠ Tecnología no encontrada: %s" % technology_id)
		return false
	
	if not can_research_technology(technology_id, faction_name):
		print("⚠ No se pueden cumplir los requisitos para investigar: %s" % technology_id)
		return false
	
	if get_active_projects_count(faction_name) >= max_concurrent_projects:
		print("⚠ Límite de proyectos concurrentes alcanzado para facción: %s" % faction_name)
		return false
	
	var tech = available_technologies[technology_id]
	var project = ResearchProject.new()
	
	project.technology_id = technology_id
	project.faction_name = faction_name
	project.target_progress = tech.research_cost
	project.assigned_researchers = assigned_researchers
	project.started_turn = get_current_turn()
	
	# Consumir recursos requeridos
	if not consume_research_resources(tech.required_resources, faction_name):
		print("⚠ No hay recursos suficientes para iniciar investigación: %s" % technology_id)
		return false
	
	active_projects[faction_name].append(project)
	
	research_started.emit(technology_id, faction_name)
	print("✓ Investigación iniciada: %s para facción %s" % [tech.name, faction_name])
	return true

func process_turn_research():
	"""Procesa el progreso de investigación de todas las facciones durante un turno"""
	for faction_name in active_projects:
		for project in active_projects[faction_name]:
			if project.status == "active":
				process_project_turn(project)

func process_project_turn(project: ResearchProject):
	"""Procesa el progreso de un proyecto específico en un turno"""
	
	# Calcular puntos de investigación base
	var research_points = base_research_points_per_turn
	
	# Aplicar bonus de eficiencia
	research_points = int(research_points * project.get_efficiency_bonus())
	
	# Consumir recursos de mantenimiento
	var daily_cost = project.get_daily_cost()
	if not consume_research_resources(daily_cost, project.faction_name):
		print("⚠ No hay recursos para mantener investigación: %s" % project.technology_id)
		project.pause_research()
		return
	
	# Añadir progreso
	project.add_progress(research_points, get_current_turn())
	
	# Emitir señal de progreso
	research_progress_updated.emit(project.technology_id, project.faction_name, project.get_progress_percentage())
	
	# Verificar si se completó
	if project.status == "completed":
		complete_research(project)

func complete_research(project: ResearchProject):
	"""Completa una investigación y aplica sus beneficios"""
	var tech = available_technologies[project.technology_id]
	
	# Añadir a tecnologías completadas
	completed_technologies[project.faction_name].append(project.technology_id)
	
	# Remover de proyectos activos
	active_projects[project.faction_name].erase(project)
	
	# Aplicar beneficios de la tecnología
	apply_technology_benefits(tech, project.faction_name)
	
	# Verificar si se desbloquean nuevas tecnologías
	check_newly_available_technologies(project.faction_name)
	
	research_completed.emit(project.technology_id, project.faction_name)
	print("✓ Investigación completada: %s para facción %s" % [tech.name, project.faction_name])

func apply_technology_benefits(tech: TechnologyData, faction_name: String):
	"""Aplica los beneficios de una tecnología completada"""
	
	# Integración con sistema económico
	if tech.economic_benefits.size() > 0:
		apply_economic_benefits(tech.economic_benefits, faction_name)
	
	# Integración con sistema militar
	if tech.military_benefits.size() > 0:
		apply_military_benefits(tech.military_benefits, faction_name)
	
	# Integración con sistema diplomático
	if tech.diplomatic_benefits.size() > 0:
		apply_diplomatic_benefits(tech.diplomatic_benefits, faction_name)

func apply_economic_benefits(benefits: Dictionary, faction_name: String):
	"""Aplica beneficios económicos (integración con sistema económico)"""
	if not FactionManager.faccion_existe(faction_name):
		return
	
	var faction = FactionManager.obtener_faccion(faction_name)
	
	for benefit in benefits:
		var value = benefits[benefit]
		match benefit:
			"resource_generation":
				# Aplicar bonus a generación de recursos
				var bonus_percentage = value / 100.0
				for resource in ["dinero", "comida", "municion"]:
					var current_amount = faction.recursos.get(resource, 0)
					var bonus_amount = int(current_amount * bonus_percentage)
					faction.recursos[resource] = current_amount + bonus_amount
				print("  + Beneficio económico aplicado: +%d%% generación de recursos" % value)
			
			"trade_income":
				# Aumentar dinero por mejoras comerciales
				var bonus_money = int(faction.recursos.get("dinero", 0) * (value / 100.0))
				faction.recursos["dinero"] = faction.recursos.get("dinero", 0) + bonus_money
				print("  + Beneficio económico aplicado: +%d dinero por comercio mejorado" % bonus_money)
			
			"gold_production", "silver_production":
				# Aumentar recursos de oro/plata
				var resource_type = "oro" if benefit == "gold_production" else "plata"
				var bonus_amount = value
				faction.recursos[resource_type] = faction.recursos.get(resource_type, 0) + bonus_amount
				print("  + Beneficio económico aplicado: +%d %s" % [bonus_amount, resource_type])
			
			"population_growth":
				# Aumentar moral como proxy de crecimiento poblacional
				faction.recursos["moral"] = faction.recursos.get("moral", 100) + value
				print("  + Beneficio económico aplicado: +%d moral por crecimiento poblacional" % value)
			
			_:
				print("  + Beneficio económico: %s = %s" % [benefit, value])

func apply_military_benefits(benefits: Dictionary, faction_name: String):
	"""Aplica beneficios militares (integración con sistema militar)"""
	if not FactionManager.faccion_existe(faction_name):
		return
	
	var faction = FactionManager.obtener_faccion(faction_name)
	
	for benefit in benefits:
		var value = benefits[benefit]
		match benefit:
			"morale_bonus", "unit_morale":
				# Aumentar moral de la facción
				faction.recursos["moral"] = faction.recursos.get("moral", 100) + value
				print("  + Beneficio militar aplicado: +%d moral" % value)
			
			"recruitment_rate":
				# Reducir costo de reclutamiento (simulado con bonus de dinero)
				var recruitment_bonus = int(faction.recursos.get("dinero", 0) * 0.1)
				faction.recursos["dinero"] = faction.recursos.get("dinero", 0) + recruitment_bonus
				print("  + Beneficio militar aplicado: +%d dinero por reclutamiento eficiente" % recruitment_bonus)
			
			"infantry_attack", "mobility", "defensive_bonus":
				# Estos beneficios se aplicarían a las unidades directamente
				# Por ahora los registramos como modificadores de facción
				var modifier_key = "military_" + benefit
				if not faction.recursos.has(modifier_key):
					faction.recursos[modifier_key] = 0
				faction.recursos[modifier_key] = faction.recursos.get(modifier_key, 0) + value
				print("  + Beneficio militar aplicado: +%d %s" % [value, benefit])
			
			"unit_supply":
				# Mejorar suministros aumentando comida disponible
				var supply_bonus = value * 5  # Multiplicador para hacer el efecto visible
				faction.recursos["comida"] = faction.recursos.get("comida", 0) + supply_bonus
				print("  + Beneficio militar aplicado: +%d comida por mejores suministros" % supply_bonus)
			
			_:
				print("  + Beneficio militar: %s = %s" % [benefit, value])

func apply_diplomatic_benefits(benefits: Dictionary, faction_name: String):
	"""Aplica beneficios diplomáticos (integración con sistema diplomático)"""
	if not FactionManager.faccion_existe(faction_name):
		return
	
	var faction = FactionManager.obtener_faccion(faction_name)
	
	for benefit in benefits:
		var value = benefits[benefit]
		match benefit:
			"patriot_relations", "trade_relations":
				# Mejorar prestigio como proxy de relaciones mejoradas
				faction.recursos["prestigio"] = faction.recursos.get("prestigio", 0) + value
				print("  + Beneficio diplomático aplicado: +%d prestigio por relaciones mejoradas" % value)
			
			"alliance_stability":
				# Aumentar moral por alianzas estables
				var stability_bonus = int(value / 2)
				faction.recursos["moral"] = faction.recursos.get("moral", 100) + stability_bonus
				print("  + Beneficio diplomático aplicado: +%d moral por alianzas estables" % stability_bonus)
			
			"intelligence_gathering", "counter_intelligence":
				# Crear recursos de inteligencia si no existen
				var intel_key = "inteligencia"
				faction.recursos[intel_key] = faction.recursos.get(intel_key, 0) + value
				print("  + Beneficio diplomático aplicado: +%d inteligencia" % value)
			
			"propaganda_effectiveness":
				# Aumentar moral por propaganda efectiva
				faction.recursos["moral"] = faction.recursos.get("moral", 100) + int(value / 2)
				print("  + Beneficio diplomático aplicado: +%d moral por propaganda" % int(value / 2))
			
			"trade_agreements":
				# Aumentar dinero por acuerdos comerciales
				var trade_bonus = value * 10  # Multiplicador para hacer visible el efecto
				faction.recursos["dinero"] = faction.recursos.get("dinero", 0) + trade_bonus
				print("  + Beneficio diplomático aplicado: +%d dinero por acuerdos comerciales" % trade_bonus)
			
			_:
				print("  + Beneficio diplomático: %s = %s" % [benefit, value])

func check_newly_available_technologies(faction_name: String):
	"""Verifica si se desbloquearon nuevas tecnologías"""
	var completed = completed_technologies[faction_name]
	
	for tech_id in available_technologies:
		var tech = available_technologies[tech_id]
		
		if tech_id in completed:
			continue  # Ya completada
		
		if tech.is_secret and not can_research_technology(tech_id, faction_name):
			continue  # Aún secreta
		
		# Verificar si ahora cumple requisitos
		if can_research_technology(tech_id, faction_name):
			new_technology_available.emit(tech_id, faction_name)

# === CONSULTAS Y UTILIDADES ===

func can_research_technology(technology_id: String, faction_name: String) -> bool:
	"""Verifica si una facción puede investigar una tecnología específica"""
	
	if not available_technologies.has(technology_id):
		return false
	
	var tech = available_technologies[technology_id]
	var completed = completed_technologies[faction_name]
	var faction_resources = get_faction_resources(faction_name)
	
	return tech.can_research(completed, faction_resources)

func get_available_technologies_for_faction(faction_name: String) -> Array[TechnologyData]:
	"""Retorna las tecnologías que una facción puede investigar actualmente"""
	var result: Array[TechnologyData] = []
	
	for tech_id in available_technologies:
		if can_research_technology(tech_id, faction_name):
			result.append(available_technologies[tech_id])
	
	return result

func get_active_projects_count(faction_name: String) -> int:
	"""Retorna el número de proyectos activos de una facción"""
	return active_projects.get(faction_name, []).size()

func get_faction_projects(faction_name: String) -> Array:
	"""Retorna todos los proyectos de investigación de una facción"""
	return active_projects.get(faction_name, [])

func get_completed_technologies_for_faction(faction_name: String) -> Array[TechnologyData]:
	"""Retorna las tecnologías completadas por una facción"""
	var result: Array[TechnologyData] = []
	var completed = completed_technologies.get(faction_name, [])
	
	for tech_id in completed:
		if available_technologies.has(tech_id):
			result.append(available_technologies[tech_id])
	
	return result

func get_technology_by_id(technology_id: String) -> TechnologyData:
	"""Retorna una tecnología específica por su ID"""
	return available_technologies.get(technology_id, null)

# === INTEGRACIÓN CON OTROS SISTEMAS ===

func consume_research_resources(resources: Dictionary, faction_name: String) -> bool:
	"""Consume recursos para investigación (integra con ResourceManager)"""
	if not FactionManager.faccion_existe(faction_name):
		return false
	
	var faction = FactionManager.obtener_faccion(faction_name)
	var faction_resources = faction.recursos
	
	# Verificar si hay suficientes recursos
	for resource in resources:
		var required_amount = resources[resource]
		var available_amount = faction_resources.get(resource, 0)
		if available_amount < required_amount:
			print("⚠ Recursos insuficientes para investigación: %s necesita %d de %s, disponible %d" % [faction_name, required_amount, resource, available_amount])
			return false
	
	# Consumir recursos
	for resource in resources:
		var amount = resources[resource]
		faction_resources[resource] = faction_resources.get(resource, 0) - amount
		print("  - Consumido %d de %s para investigación" % [amount, resource])
	
	return true

func get_faction_resources(faction_name: String) -> Dictionary:
	"""Obtiene los recursos actuales de una facción"""
	# TODO: Integrar con FactionManager real
	if FactionManager.faccion_existe(faction_name):
		var faction = FactionManager.obtener_faccion(faction_name)
		return faction.recursos
	return {}

func get_current_turn() -> int:
	"""Obtiene el turno actual del juego"""
	# Integrar con MainHUD si está disponible
	var main_hud = get_tree().get_first_node_in_group("main_hud")
	if main_hud and main_hud.has_method("get_current_turn"):
		return main_hud.get_current_turn()
	
	# Fallback a un contador interno si no hay integración
	return 1

# === MÉTODOS PARA UI ===

func pause_research_project(technology_id: String, faction_name: String) -> bool:
	"""Pausa un proyecto de investigación específico"""
	var project = find_project(technology_id, faction_name)
	if project:
		project.pause_research()
		return true
	return false

func resume_research_project(technology_id: String, faction_name: String) -> bool:
	"""Reanuda un proyecto de investigación pausado"""
	var project = find_project(technology_id, faction_name)
	if project:
		project.resume_research()
		return true
	return false

func cancel_research_project(technology_id: String, faction_name: String) -> bool:
	"""Cancela un proyecto de investigación"""
	var project = find_project(technology_id, faction_name)
	if project:
		project.cancel_research()
		active_projects[faction_name].erase(project)
		return true
	return false

func change_project_priority(technology_id: String, faction_name: String, new_priority: String) -> bool:
	"""Cambia la prioridad de un proyecto de investigación"""
	var project = find_project(technology_id, faction_name)
	if project:
		project.priority = new_priority
		return true
	return false

func assign_researchers(technology_id: String, faction_name: String, researchers: int) -> bool:
	"""Asigna investigadores a un proyecto específico"""
	var project = find_project(technology_id, faction_name)
	if project:
		project.assigned_researchers = max(1, researchers)
		return true
	return false

func find_project(technology_id: String, faction_name: String) -> ResearchProject:
	"""Encuentra un proyecto específico"""
	var projects = active_projects.get(faction_name, [])
	for project in projects:
		if project.technology_id == technology_id:
			return project
	return null

# === GUARDADO Y CARGA ===

func get_save_data() -> Dictionary:
	"""Obtiene datos para guardar el estado del sistema de investigación"""
	var save_data = {
		"completed_technologies": completed_technologies,
		"active_projects": {}
	}
	
	# Convertir proyectos activos a datos serializables
	for faction_name in active_projects:
		save_data["active_projects"][faction_name] = []
		for project in active_projects[faction_name]:
			save_data["active_projects"][faction_name].append(project.to_save_data())
	
	return save_data

func load_save_data(data: Dictionary):
	"""Carga el estado del sistema desde datos guardados"""
	completed_technologies = data.get("completed_technologies", {})
	
	# Reconstruir proyectos activos
	var projects_data = data.get("active_projects", {})
	for faction_name in projects_data:
		active_projects[faction_name] = []
		for project_data in projects_data[faction_name]:
			var project = ResearchProject.new()
			project.from_save_data(project_data)
			active_projects[faction_name].append(project)