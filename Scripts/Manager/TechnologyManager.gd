extends Node
class_name TechnologyManager

# Gestor del sistema de investigación tecnológica

signal technology_completed(technology: TechnologyData)
signal technology_started(technology: TechnologyData)
signal research_progress_changed(technology: TechnologyData, progress: float)

# Todas las tecnologías del juego
var all_technologies: Dictionary = {}
var technology_tree_levels: Array = []

# Estado actual de investigación
var current_research: TechnologyData = null
var faction_research_points: Dictionary = {} # Por facción
var faction_completed_technologies: Dictionary = {} # Por facción

func _ready():
	print("✓ TechnologyManager inicializado")
	load_technologies()
	setup_technology_tree()
	print("✓ Tecnologías cargadas: ", all_technologies.size())

func load_technologies():
	"""Carga todas las tecnologías desde archivos de configuración"""
	# Esta función cargará tecnologías desde archivos JSON o recursos
	# Por ahora, crearemos algunas tecnologías de ejemplo
	create_example_technologies()

func create_example_technologies():
	"""Crea tecnologías de ejemplo para demostrar el sistema"""
	
	# Tecnologías básicas de nivel 1
	var disciplina_militar = create_technology(
		"disciplina_militar",
		"Disciplina Militar",
		"Mejora el entrenamiento básico de las tropas, aumentando su moral y efectividad en combate.",
		"militar",
		[],
		80,
		3,
		{"dinero": 50},
		{"moral_tropas": 10, "efectividad_combate": 5},
		["pelotón_disciplinado"],
		[],
		["entrenamiento_avanzado"],
		0, 0, 1
	)
	
	var economia_basica = create_technology(
		"economia_basica",
		"Economía Básica",
		"Establece principios básicos de administración económica y comercio.",
		"economia",
		[],
		60,
		2,
		{"dinero": 30},
		{"generacion_dinero": 15, "eficiencia_comercial": 10},
		[],
		["mercado_basico"],
		["impuestos_organizados"],
		1, 0, 1
	)
	
	var diplomatcia_inicial = create_technology(
		"diplomacia_inicial",
		"Diplomacia Inicial",
		"Desarrolla las bases de las relaciones diplomáticas y negociación.",
		"cultura",
		[],
		70,
		3,
		{"dinero": 40},
		{"prestigio": 20, "relaciones_diplomaticas": 15},
		[],
		["embajada"],
		["tratados_comerciales"],
		2, 0, 1
	)
	
	# Tecnologías de nivel 2
	var tacticas_avanzadas = create_technology(
		"tacticas_avanzadas",
		"Tácticas Avanzadas",
		"Desarrolla nuevas formaciones y estrategias militares más sofisticadas.",
		"militar",
		["disciplina_militar"],
		120,
		4,
		{"dinero": 80, "municion": 20},
		{"efectividad_combate": 15, "velocidad_movimiento": 10},
		["compañía_veterana"],
		["cuartel_avanzado"],
		["formaciones_especiales"],
		0, 1, 2
	)
	
	var industria_artesanal = create_technology(
		"industria_artesanal",
		"Industria Artesanal",
		"Mejora la producción artesanal y manufactura básica de equipos.",
		"economia",
		["economia_basica"],
		100,
		4,
		{"dinero": 60, "oro": 10},
		{"produccion_equipos": 20, "calidad_armas": 10},
		[],
		["taller_artesanal", "herreria_avanzada"],
		["especializacion_artesanos"],
		1, 1, 2
	)
	
	# Registrar en el diccionario
	all_technologies["disciplina_militar"] = disciplina_militar
	all_technologies["economia_basica"] = economia_basica
	all_technologies["diplomacia_inicial"] = diplomatcia_inicial
	all_technologies["tacticas_avanzadas"] = tacticas_avanzadas
	all_technologies["industria_artesanal"] = industria_artesanal

func create_technology(
	id: String, nombre: String, descripcion: String, categoria: String,
	prerequisitos: Array, costo: int, turnos: int, recursos: Dictionary,
	bonificaciones: Dictionary, unidades: Array, edificios: Array, mecanicas: Array,
	pos_x: int, pos_y: int, nivel: int
) -> TechnologyData:
	"""Función helper para crear tecnologías"""
	var tech = TechnologyData.new()
	tech.id = id
	tech.nombre = nombre
	tech.descripcion = descripcion
	tech.categoria = categoria
	tech.prerequisitos = prerequisitos
	tech.costo_investigacion = costo
	tech.tiempo_turnos = turnos
	tech.recursos_requeridos = recursos
	tech.bonificaciones = bonificaciones
	tech.unidades_desbloqueadas = unidades
	tech.edificios_desbloqueados = edificios
	tech.mecanicas_desbloqueadas = mecanicas
	tech.posicion_x = pos_x
	tech.posicion_y = pos_y
	tech.nivel_arbol = nivel
	
	return tech

func setup_technology_tree():
	"""Organiza las tecnologías en niveles del árbol"""
	technology_tree_levels.clear()
	
	# Organizar por niveles
	var max_level = 0
	for tech in all_technologies.values():
		max_level = max(max_level, tech.nivel_arbol)
	
	# Inicializar arrays de niveles
	for i in range(max_level + 1):
		technology_tree_levels.append([])
	
	# Agrupar tecnologías por nivel
	for tech in all_technologies.values():
		technology_tree_levels[tech.nivel_arbol].append(tech)

func get_available_technologies(faction_name: String) -> Array:
	"""Obtiene las tecnologías disponibles para investigar por una facción"""
	var completed = get_completed_technologies(faction_name)
	var available = []
	
	for tech in all_technologies.values():
		if tech.puede_ser_investigada(completed):
			available.append(tech)
	
	return available

func get_completed_technologies(faction_name: String) -> Array:
	"""Obtiene los IDs de tecnologías completadas por una facción"""
	if not faction_name in faction_completed_technologies:
		faction_completed_technologies[faction_name] = []
	
	return faction_completed_technologies[faction_name]

func start_research(faction_name: String, technology_id: String) -> bool:
	"""Inicia la investigación de una tecnología"""
	if not technology_id in all_technologies:
		push_error("Tecnología no encontrada: " + technology_id)
		return false
	
	var tech = all_technologies[technology_id]
	var completed = get_completed_technologies(faction_name)
	
	if not tech.puede_ser_investigada(completed):
		push_warning("Tecnología no disponible para investigación: " + technology_id)
		return false
	
	# Verificar recursos
	if not has_required_resources(faction_name, tech.recursos_requeridos):
		push_warning("Recursos insuficientes para: " + technology_id)
		return false
	
	# Consumir recursos
	consume_resources(faction_name, tech.recursos_requeridos)
	
	# Iniciar investigación
	tech.iniciar_investigacion()
	current_research = tech
	
	technology_started.emit(tech)
	print("✓ Investigación iniciada: ", tech.nombre)
	
	return true

func advance_research(faction_name: String, points: int) -> void:
	"""Avanza la investigación actual"""
	if not current_research:
		return
	
	var completed = current_research.avanzar_investigacion(points)
	research_progress_changed.emit(current_research, current_research.get_progreso_porcentaje())
	
	if completed:
		complete_current_research(faction_name)

func complete_current_research(faction_name: String) -> void:
	"""Completa la investigación actual"""
	if not current_research:
		return
	
	var tech = current_research
	
	# Agregar a tecnologías completadas
	if not faction_name in faction_completed_technologies:
		faction_completed_technologies[faction_name] = []
	
	faction_completed_technologies[faction_name].append(tech.id)
	
	# Aplicar efectos
	apply_technology_effects(faction_name, tech)
	
	technology_completed.emit(tech)
	print("✓ Investigación completada: ", tech.nombre)
	
	current_research = null

func apply_technology_effects(faction_name: String, tech: TechnologyData) -> void:
	"""Aplica los efectos de una tecnología completada"""
	# Este método se conectará con otros sistemas del juego
	# Por ahora solo registramos que se aplicaron los efectos
	print("Aplicando efectos de ", tech.nombre, ": ", tech.bonificaciones)

func has_required_resources(faction_name: String, required: Dictionary) -> bool:
	"""Verifica si una facción tiene los recursos requeridos"""
	# Obtener recursos de la facción desde FactionManager global
	if not FactionManager:
		return true # Si no hay manager, asumir que tiene recursos
	
	var faction_data = FactionManager.get_faction_data(faction_name)
	if not faction_data:
		return false
	
	for resource in required:
		var needed = required[resource]
		var available = faction_data.recursos.get(resource, 0)
		if available < needed:
			return false
	
	return true

func consume_resources(faction_name: String, costs: Dictionary) -> void:
	"""Consume recursos de una facción"""
	if not FactionManager:
		return
	
	var faction_data = FactionManager.get_faction_data(faction_name)
	if not faction_data:
		return
	
	for resource in costs:
		var cost = costs[resource]
		var current = faction_data.recursos.get(resource, 0)
		faction_data.recursos[resource] = max(0, current - cost)

func get_research_points_per_turn(faction_name: String) -> int:
	"""Calcula puntos de investigación generados por turno"""
	# Base + modificadores de tecnologías + edificios
	var base_points = 10
	var tech_bonus = 0
	
	# Sumar bonificaciones de tecnologías completadas
	var completed = get_completed_technologies(faction_name)
	for tech_id in completed:
		if tech_id in all_technologies:
			var tech = all_technologies[tech_id]
			tech_bonus += tech.bonificaciones.get("puntos_investigacion", 0)
	
	return base_points + tech_bonus

func process_turn(faction_name: String) -> void:
	"""Procesa el avance de investigación en cada turno"""
	if current_research:
		var points = get_research_points_per_turn(faction_name)
		advance_research(faction_name, points)

func get_technology_by_id(id: String) -> TechnologyData:
	"""Obtiene una tecnología por su ID"""
	return all_technologies.get(id, null)

func get_all_technologies() -> Array:
	"""Obtiene todas las tecnologías"""
	return all_technologies.values()

func get_technologies_by_level(level: int) -> Array:
	"""Obtiene tecnologías de un nivel específico del árbol"""
	if level < 0 or level >= technology_tree_levels.size():
		return []
	
	return technology_tree_levels[level]