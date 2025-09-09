extends Node

# Script de prueba para el sistema de tecnologías
# Este script se puede usar para verificar que el sistema funciona correctamente

func test_technology_system():
	print("=== INICIANDO PRUEBAS DEL SISTEMA DE TECNOLOGÍAS ===")
	
	# Crear el gestor de tecnologías
	var tech_manager = TechnologyManager.new()
	
	# Verificar que las tecnologías se cargaron
	var technologies = tech_manager.get_all_technologies()
	print("Tecnologías cargadas: ", technologies.size())
	assert(technologies.size() > 0, "Deben existir tecnologías")
	
	# Verificar tecnologías básicas
	var disciplina = tech_manager.get_technology_by_id("disciplina_militar")
	assert(disciplina != null, "Disciplina Militar debe existir")
	assert(disciplina.nombre == "Disciplina Militar", "Nombre correcto")
	assert(disciplina.prerequisitos.size() == 0, "No debe tener prerequisitos")
	
	var economia = tech_manager.get_technology_by_id("economia_basica")
	assert(economia != null, "Economía Básica debe existir")
	
	var tacticas = tech_manager.get_technology_by_id("tacticas_avanzadas")
	assert(tacticas != null, "Tácticas Avanzadas debe existir")
	assert(tacticas.prerequisitos.size() > 0, "Debe tener prerequisitos")
	assert("disciplina_militar" in tacticas.prerequisitos, "Debe requerir Disciplina Militar")
	
	# Verificar disponibilidad inicial
	var available = tech_manager.get_available_technologies("test_faction")
	print("Tecnologías disponibles inicialmente: ", available.size())
	assert(available.size() >= 3, "Debe haber al menos 3 tecnologías básicas disponibles")
	
	# Verificar que tecnologías avanzadas no están disponibles
	var available_ids = []
	for tech in available:
		available_ids.append(tech.id)
	assert(not "tacticas_avanzadas" in available_ids, "Tácticas Avanzadas no debe estar disponible inicialmente")
	
	# Simular investigación
	print("Iniciando investigación de Disciplina Militar...")
	var success = tech_manager.start_research("test_faction", "disciplina_militar")
	assert(success, "La investigación debe iniciarse exitosamente")
	assert(disciplina.investigando, "La tecnología debe estar marcada como en investigación")
	
	# Simular progreso
	tech_manager.advance_research("test_faction", 50)
	assert(disciplina.progreso_actual == 50, "El progreso debe ser 50")
	assert(not disciplina.completada, "No debe estar completada aún")
	
	# Completar investigación
	tech_manager.advance_research("test_faction", 50)
	assert(disciplina.completada, "La tecnología debe estar completada")
	assert(not disciplina.investigando, "No debe estar en investigación")
	
	# Verificar que ahora Tácticas Avanzadas está disponible
	available = tech_manager.get_available_technologies("test_faction")
	available_ids = []
	for tech in available:
		available_ids.append(tech.id)
	assert("tacticas_avanzadas" in available_ids, "Tácticas Avanzadas debe estar disponible ahora")
	
	print("✓ TODAS LAS PRUEBAS PASARON EXITOSAMENTE")
	print("=== FIN DE PRUEBAS ===")

func _ready():
	# Ejecutar pruebas automáticamente si este script se ejecuta
	test_technology_system()