extends Node

# Test script para validar el sistema de diplomacia
# Este script puede ejecutarse para verificar que todas las funciones funcionan correctamente

func _ready():
	print("=== INICIANDO PRUEBAS DEL SISTEMA DE DIPLOMACIA ===")
	
	# Esperar a que los sistemas estén inicializados
	await get_tree().process_frame
	
	test_diplomacy_manager()
	test_faction_data_integration()
	test_validation_rules()
	test_proposal_system()
	test_diplomatic_effects()
	test_report_generation()
	
	print("=== PRUEBAS COMPLETADAS ===")

func test_diplomacy_manager():
	print("\n--- Probando DiplomacyManager ---")
	
	# Verificar que el manager existe
	assert(DiplomacyManager != null, "DiplomacyManager debe existir")
	print("✓ DiplomacyManager inicializado")
	
	# Verificar estados iniciales
	var status = DiplomacyManager.get_diplomatic_status("Patriota", "Realista")
	assert(status == DiplomacyManager.DiplomaticStatus.NEUTRAL, "Estado inicial debe ser NEUTRAL")
	print("✓ Estado inicial correcto: ", DiplomacyManager.get_status_name(status))
	
	# Probar cambio de estado
	var success = DiplomacyManager.set_diplomatic_status("Patriota", "Realista", DiplomacyManager.DiplomaticStatus.WAR)
	assert(success, "Debe poder declarar guerra")
	print("✓ Declaración de guerra exitosa")
	
	# Verificar estado bidireccional
	var status_reverse = DiplomacyManager.get_diplomatic_status("Realista", "Patriota")
	assert(status_reverse == DiplomacyManager.DiplomaticStatus.WAR, "Estado debe ser bidireccional")
	print("✓ Estado bidireccional correcto")

func test_faction_data_integration():
	print("\n--- Probando integración con FactionData ---")
	
	var patriota_faction = FactionManager.obtener_faccion("Patriota")
	assert(patriota_faction != null, "Facción Patriota debe existir")
	
	# Probar métodos de conveniencia
	var is_at_war = patriota_faction.is_at_war_with("Realista")
	assert(is_at_war, "Patriota debe estar en guerra con Realista")
	print("✓ Método is_at_war_with funciona correctamente")
	
	var can_trade = patriota_faction.can_trade_with("Realista")
	assert(not can_trade, "No debe poder comerciar durante guerra")
	print("✓ Método can_trade_with funciona correctamente")
	
	var enemies = patriota_faction.get_all_enemies()
	assert("Realista" in enemies, "Realista debe estar en la lista de enemigos")
	print("✓ Método get_all_enemies funciona correctamente")

func test_validation_rules():
	print("\n--- Probando reglas de validación ---")
	
	# No debe poder hacer paz sin guerra previa (pero ya están en guerra)
	var can_declare_peace = DiplomacyManager._can_send_proposal("Patriota", "Realista", DiplomacyManager.ProposalType.PROPOSE_PEACE)
	assert(can_declare_peace, "Debe poder proponer paz durante guerra")
	print("✓ Validación de propuesta de paz correcta")
	
	# No debe poder declarar guerra si ya están en guerra
	var can_declare_war = DiplomacyManager._can_send_proposal("Patriota", "Realista", DiplomacyManager.ProposalType.DECLARE_WAR)
	assert(not can_declare_war, "No debe poder declarar guerra si ya están en guerra")
	print("✓ Validación de declaración de guerra correcta")
	
	# No debe poder hacer alianza durante guerra
	var can_ally = DiplomacyManager._can_send_proposal("Patriota", "Realista", DiplomacyManager.ProposalType.PROPOSE_ALLIANCE)
	assert(not can_ally, "No debe poder hacer alianza durante guerra")
	print("✓ Validación de propuesta de alianza correcta")

func test_proposal_system():
	print("\n--- Probando sistema de propuestas ---")
	
	# Probar envío de propuesta
	var initial_count = DiplomacyManager.pending_proposals.size()
	var success = DiplomacyManager.send_proposal("Realista", "Patriota", DiplomacyManager.ProposalType.PROPOSE_PEACE)
	assert(success, "Debe poder enviar propuesta de paz")
	
	var new_count = DiplomacyManager.pending_proposals.size()
	assert(new_count == initial_count + 1, "Debe haber una propuesta más")
	print("✓ Envío de propuesta exitoso")
	
	# Encontrar la propuesta
	var peace_proposal = null
	for proposal in DiplomacyManager.pending_proposals:
		if proposal.sender == "Realista" and proposal.receiver == "Patriota" and proposal.type == DiplomacyManager.ProposalType.PROPOSE_PEACE:
			peace_proposal = proposal
			break
	
	assert(peace_proposal != null, "Debe encontrar la propuesta de paz")
	print("✓ Propuesta encontrada en la lista")
	
	# Probar aceptación de propuesta
	var accept_success = DiplomacyManager.accept_proposal(peace_proposal)
	assert(accept_success, "Debe poder aceptar propuesta de paz")
	
	# Verificar que el estado cambió
	var new_status = DiplomacyManager.get_diplomatic_status("Patriota", "Realista")
	assert(new_status == DiplomacyManager.DiplomaticStatus.PEACE, "Estado debe ser PAZ después de aceptar")
	print("✓ Aceptación de propuesta exitosa, estado cambiado a PAZ")
	
	# Verificar que la propuesta fue removida
	var final_count = DiplomacyManager.pending_proposals.size()
	assert(final_count == initial_count, "Propuesta debe ser removida después de aceptar")
	print("✓ Propuesta removida de la lista")

func test_diplomatic_effects():
	print("\n--- Probando efectos diplomáticos ---")
	
	var patriota_faction = FactionManager.obtener_faccion("Patriota")
	var initial_recursos = patriota_faction.recursos.duplicate()
	
	# Aplicar efectos diplomáticos
	patriota_faction.apply_trade_bonus()
	patriota_faction.apply_war_penalties()
	patriota_faction.apply_alliance_benefits()
	
	print("✓ Efectos diplomáticos aplicados sin errores")
	
	# Nota: Los valores específicos dependen del estado actual,
	# pero al menos verificamos que no hay errores de ejecución

func test_report_generation():
	print("\n--- Probando generación de reportes ---")
	
	var report = DiplomacyManager.generate_diplomatic_report("Patriota")
	assert(not report.is_empty(), "Reporte no debe estar vacío")
	assert("PATRIOTA" in report, "Reporte debe contener el nombre de la facción")
	print("✓ Reporte diplomático generado correctamente")
	
	var summary = DiplomacyManager.get_diplomatic_summary("Patriota")
	assert(summary.has("allies"), "Resumen debe tener categoría 'allies'")
	assert(summary.has("enemies"), "Resumen debe tener categoría 'enemies'")
	print("✓ Resumen diplomático generado correctamente")