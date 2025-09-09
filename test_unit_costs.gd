# Test script para verificar el sistema de costos de unidades
# Se puede ejecutar desde la consola de Godot para verificar que todo funciona correctamente

extends SceneTree

func _init():
	print("=== Test del Sistema de Costos de Unidades ===")
	test_unit_data_loading()
	test_recruitment_costs()
	test_maintenance_costs()
	test_all_resources_used()
	print("=== Test completado ===")
	quit()

func test_unit_data_loading():
	print("\n1. Probando carga de datos de unidades...")
	
	var units_to_test = [
		"res://Data/Units/Infantería/Pelotón.tres",
		"res://Data/Units/Caballería/Escuadrón.tres", 
		"res://Data/Units/Artillería/Batería_Pequeña.tres"
	]
	
	for unit_path in units_to_test:
		var unit_data = load(unit_path)
		if unit_data:
			print("  ✓ %s cargado correctamente" % unit_data.nombre)
			print("    - Tamaño: %d hombres" % unit_data.tamaño)
			print("    - Rama: %s" % unit_data.rama)
		else:
			print("  ✗ Error cargando: %s" % unit_path)

func test_recruitment_costs():
	print("\n2. Probando costos de reclutamiento...")
	
	var peloton = load("res://Data/Units/Infantería/Pelotón.tres")
	if peloton and peloton.costos_reclutamiento:
		print("  ✓ Pelotón de Infantería - Costos de reclutamiento:")
		for resource in peloton.costos_reclutamiento:
			print("    - %s: %s" % [resource, peloton.costos_reclutamiento[resource]])
	else:
		print("  ✗ Error: No se encontraron costos de reclutamiento para Pelotón")

func test_maintenance_costs():
	print("\n3. Probando costos de mantenimiento...")
	
	var escuadron = load("res://Data/Units/Caballería/Escuadrón.tres")
	if escuadron and escuadron.costos_mantenimiento:
		print("  ✓ Escuadrón de Caballería - Costos de mantenimiento:")
		for resource in escuadron.costos_mantenimiento:
			print("    - %s: %s" % [resource, escuadron.costos_mantenimiento[resource]])
	else:
		print("  ✗ Error: No se encontraron costos de mantenimiento para Escuadrón")

func test_all_resources_used():
	print("\n4. Verificando que todos los recursos requeridos están en uso...")
	
	var required_resources = [
		"Pan", "Carne", "Sables", "Mosquetes", "Municion", 
		"Caballos", "Cañones", "Vino", "Aguardiente", "Tabaco", "Biblias"
	]
	
	var used_resources = {}
	
	# Verificar todas las unidades
	var all_units = [
		"res://Data/Units/Infantería/Pelotón.tres",
		"res://Data/Units/Infantería/Compañia.tres",
		"res://Data/Units/Infantería/Batallón.tres",
		"res://Data/Units/Infantería/Regimiento.tres",
		"res://Data/Units/Caballería/Escuadrón.tres",
		"res://Data/Units/Caballería/Compañia.tres",
		"res://Data/Units/Caballería/Regimiento.tres",
		"res://Data/Units/Artillería/Batería_Pequeña.tres",
		"res://Data/Units/Artillería/Batería_Mediana.tres",
		"res://Data/Units/Artillería/Batería_Grande.tres"
	]
	
	for unit_path in all_units:
		var unit_data = load(unit_path)
		if unit_data:
			# Verificar costos de reclutamiento
			for resource in unit_data.costos_reclutamiento:
				if unit_data.costos_reclutamiento[resource] > 0:
					used_resources[resource] = true
			
			# Verificar costos de mantenimiento
			for resource in unit_data.costos_mantenimiento:
				if unit_data.costos_mantenimiento[resource] > 0:
					used_resources[resource] = true
	
	print("  Recursos en uso:")
	for resource in required_resources:
		if used_resources.has(resource):
			print("    ✓ %s" % resource)
		else:
			print("    ✗ %s (NO USADO)" % resource)
	
	# Verificar si todos los recursos requeridos están siendo usados
	var all_used = true
	for resource in required_resources:
		if not used_resources.has(resource):
			all_used = false
			break
	
	if all_used:
		print("  ✓ ¡Todos los recursos requeridos están siendo utilizados!")
	else:
		print("  ⚠ Algunos recursos requeridos no están siendo utilizados")