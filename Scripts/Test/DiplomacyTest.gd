extends Node
# Test básico del sistema de diplomacia

func _ready():
	print("=== INICIANDO PRUEBAS DEL SISTEMA DE DIPLOMACIA ===")
	
	# Esperar a que se inicialicen los sistemas
	await get_tree().process_frame
	await get_tree().process_frame
	
	test_diplomatic_relations()
	test_diplomatic_proposals()
	test_diplomatic_events()
	
	print("=== PRUEBAS COMPLETADAS ===")

func test_diplomatic_relations():
	print("\n--- Prueba de Relaciones Diplomáticas ---")
	
	if not DiplomacyManager:
		print("❌ DiplomacyManager no encontrado")
		return
	
	# Obtener relación entre Patriota y Realista
	var relation = DiplomacyManager.get_diplomatic_relation("Patriota", "Realista")
	if relation:
		print("✓ Relación encontrada: Patriota ↔ Realista")
		print("  Estado: %s" % relation.get_relation_name())
		print("  Color: %s" % relation.get_relation_color())
		print("  Opinión Patriota hacia Realista: %d" % relation.get_opinion_towards("Realista"))
	else:
		print("❌ No se encontró relación entre Patriota y Realista")
	
	# Probar todas las relaciones
	var all_relations = DiplomacyManager.get_all_relations()
	print("  Total de relaciones diplomáticas: %d" % all_relations.size())

func test_diplomatic_proposals():
	print("\n--- Prueba de Propuestas Diplomáticas ---")
	
	if not DiplomacyManager:
		print("❌ DiplomacyManager no encontrado")
		return
	
	# Enviar una propuesta de prueba
	DiplomacyManager.send_diplomatic_proposal("Patriota", "Realista", "alliance")
	print("✓ Propuesta de alianza enviada")
	
	# Verificar propuestas pendientes
	var pending = DiplomacyManager.get_pending_proposals_for_faction("Realista")
	print("  Propuestas pendientes para Realista: %d" % pending.size())
	
	# Responder a la propuesta
	if pending.size() > 0:
		var proposal_id = pending[0].get("id", "")
		if not proposal_id.is_empty():
			DiplomacyManager.respond_to_proposal(proposal_id, false)  # Rechazar
			print("✓ Propuesta rechazada")

func test_diplomatic_events():
	print("\n--- Prueba de Eventos Diplomáticos ---")
	
	if not DiplomacyManager:
		print("❌ DiplomacyManager no encontrado")
		return
	
	# Cambiar estado diplomático
	DiplomacyManager.set_diplomatic_status("Patriota", "Realista", DiplomaticRelation.RelationStatus.HOSTILE)
	print("✓ Estado diplomático cambiado a Hostil")
	
	# Verificar el cambio
	var relation = DiplomacyManager.get_diplomatic_relation("Patriota", "Realista")
	if relation:
		print("  Nuevo estado: %s" % relation.get_relation_name())
		print("  Eventos recientes: %d" % relation.recent_events.size())
	
	# Probar evento aleatorio manualmente
	var event_config = {
		"name": "test_event",
		"description": "Evento de prueba entre {faction_a} y {faction_b}",
		"opinion_change": -5
	}
	DiplomacyManager.trigger_random_event(event_config)
	print("✓ Evento aleatorio de prueba activado")

func _exit_tree():
	print("\n=== Test de Diplomacia Finalizado ===")