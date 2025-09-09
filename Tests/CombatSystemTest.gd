extends Node

# Test script para verificar el funcionamiento del sistema de combate
# Ejecutar este script desde el editor para probar las funcionalidades básicas

func _ready():
	print("=== INICIANDO TESTS DEL SISTEMA DE COMBATE ===")
	test_combat_system_creation()
	test_division_data_creation()
	test_combat_detection()
	test_combat_logic()
	print("=== TESTS COMPLETADOS ===")

func test_combat_system_creation():
	print("\n1. Testing CombatSystem creation...")
	var combat_system = CombatSystem.new()
	assert(combat_system != null, "CombatSystem should be created")
	assert(not combat_system.is_combat_active(), "Combat should not be active initially")
	print("✓ CombatSystem creation test passed")

func test_division_data_creation():
	print("\n2. Testing DivisionData creation...")
	
	# Crear división patriota de prueba
	var patriota_div = DivisionData.new()
	patriota_div.nombre = "División Test Patriota"
	patriota_div.rama_principal = "infantería"
	patriota_div.faccion = "Patriota"
	patriota_div.cantidad_total = 500
	patriota_div.moral = 75
	patriota_div.experiencia = 30
	
	# Crear división realista de prueba
	var realista_div = DivisionData.new()
	realista_div.nombre = "División Test Realista"
	realista_div.rama_principal = "caballería"
	realista_div.faccion = "Realista"
	realista_div.cantidad_total = 300
	realista_div.moral = 80
	realista_div.experiencia = 25
	
	assert(patriota_div.faccion == "Patriota", "Patriota faction should be set")
	assert(realista_div.faccion == "Realista", "Realista faction should be set")
	print("✓ DivisionData creation test passed")

func test_combat_detection():
	print("\n3. Testing combat detection...")
	var combat_system = CombatSystem.new()
	
	# Crear divisiones de prueba
	var patriota_div = create_test_division("Patriota", "Patriota Test", 400, 70, 20)
	var realista_div = create_test_division("Realista", "Realista Test", 350, 75, 25)
	var patriota_div2 = create_test_division("Patriota", "Patriota Test 2", 200, 60, 15)
	
	# Test: Unidades de la misma facción no deberían poder combatir
	assert(not combat_system.can_units_combat(patriota_div, patriota_div2), "Same faction units should not combat")
	
	# Test: Unidades de facciones diferentes sí deberían poder combatir
	assert(combat_system.can_units_combat(patriota_div, realista_div), "Different faction units should be able to combat")
	
	# Test: Unidades sin tropas no deberían combatir
	realista_div.cantidad_total = 0
	assert(not combat_system.can_units_combat(patriota_div, realista_div), "Units with no troops should not combat")
	
	print("✓ Combat detection test passed")

func test_combat_logic():
	print("\n4. Testing combat logic...")
	var combat_system = CombatSystem.new()
	
	# Crear divisiones de prueba
	var attacker = create_test_division("Patriota", "Atacante Test", 400, 70, 20)
	var defender = create_test_division("Realista", "Defensor Test", 350, 75, 25)
	
	# Iniciar combate
	var combat_started = combat_system.start_combat(attacker, defender)
	assert(combat_started, "Combat should start successfully")
	assert(combat_system.is_combat_active(), "Combat should be active after start")
	
	# Ejecutar algunos turnos
	var turn_count = 0
	while combat_system.is_combat_active() and turn_count < 5:
		var turn_data = combat_system.execute_combat_turn()
		assert(turn_data != null, "Turn data should not be null")
		assert(turn_data.turn_number > 0, "Turn number should be positive")
		turn_count += 1
		
		print("  Turno %d: Atacante %d tropas, Defensor %d tropas" % [
			turn_data.turn_number, attacker.cantidad_total, defender.cantidad_total
		])
	
	print("✓ Combat logic test passed")

func create_test_division(faction: String, name: String, troops: int, moral: int, experience: int) -> DivisionData:
	"""Helper function to create test divisions"""
	var div = DivisionData.new()
	div.nombre = name
	div.faccion = faction
	div.rama_principal = "infantería"
	div.cantidad_total = troops
	div.moral = moral
	div.experiencia = experience
	div.estado = "activo"
	return div