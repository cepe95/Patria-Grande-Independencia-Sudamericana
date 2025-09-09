extends Node

## Test para verificar que el sistema de ciudades funciona correctamente
## Este test verifica que se pueden cargar todas las ciudades desde Data/Ciudades/

const CiudadResource = preload("res://Scripts/Data/CiudadResource.gd")

func test_cargar_todas_las_ciudades():
	"""Test que simula la funcionalidad de un CityManager cargando todas las ciudades"""
	print("=== Test: Cargar todas las ciudades ===")
	
	var ciudades_cargadas = []
	var archivos_ciudades = [
		"res://Data/Ciudades/cordoba_capital.tres",
		"res://Data/Ciudades/villa_maria.tres", 
		"res://Data/Ciudades/rio_cuarto.tres",
		"res://Data/Ciudades/san_francisco.tres",
		"res://Data/Ciudades/villa_dolores.tres",
		"res://Data/Ciudades/jesus_maria.tres"
	]
	
	for archivo in archivos_ciudades:
		var ciudad = load(archivo) as CiudadResource
		if ciudad:
			ciudades_cargadas.append(ciudad)
			print("✓ Ciudad cargada: %s (Tipo: %s, Población: %d, Posición: %s)" % [
				ciudad.nombre, ciudad.tipo, ciudad.poblacion, str(ciudad.pos_mapa)
			])
		else:
			print("✗ Error cargando ciudad: %s" % archivo)
	
	print("Total de ciudades cargadas: %d/6" % ciudades_cargadas.size())
	
	# Verificar que todas las ciudades tienen las propiedades requeridas
	for ciudad in ciudades_cargadas:
		assert(ciudad.nombre != "", "Ciudad debe tener nombre")
		assert(ciudad.tipo != "", "Ciudad debe tener tipo")
		assert(ciudad.poblacion > 0, "Ciudad debe tener población")
		assert(ciudad.pos_mapa != Vector2.ZERO, "Ciudad debe tener posición en mapa")
		assert(ciudad.recursos_base.size() > 0, "Ciudad debe tener recursos base")
		assert(ciudad.produccion_actual.size() > 0, "Ciudad debe tener producción actual")
		assert(ciudad.capacidad_reclutamiento >= 0, "Ciudad debe tener capacidad de reclutamiento")
	
	print("✓ Todas las ciudades tienen las propiedades requeridas")
	return ciudades_cargadas

func test_propiedades_especificas_ciudades():
	"""Test para verificar propiedades específicas de algunas ciudades"""
	print("\n=== Test: Propiedades específicas ===")
	
	# Test Córdoba Capital
	var cordoba = load("res://Data/Ciudades/cordoba_capital.tres") as CiudadResource
	assert(cordoba.tipo == "capital", "Córdoba debe ser capital")
	assert(cordoba.poblacion == 150000, "Córdoba debe tener 150000 habitantes")
	assert("capital_provincial" in cordoba.especiales, "Córdoba debe tener característica capital_provincial")
	print("✓ Córdoba Capital verificada")
	
	# Test Villa María
	var villa_maria = load("res://Data/Ciudades/villa_maria.tres") as CiudadResource
	assert(villa_maria.tipo == "ciudad", "Villa María debe ser ciudad")
	assert("centro_agricola" in villa_maria.especiales, "Villa María debe ser centro agrícola")
	print("✓ Villa María verificada")
	
	# Test Villa Dolores
	var villa_dolores = load("res://Data/Ciudades/villa_dolores.tres") as CiudadResource
	assert(villa_dolores.tipo == "villa", "Villa Dolores debe ser villa")
	assert("zona_montanosa" in villa_dolores.especiales, "Villa Dolores debe estar en zona montañosa")
	print("✓ Villa Dolores verificada")

func _ready():
	print("Iniciando tests del sistema de ciudades...")
	test_cargar_todas_las_ciudades()
	test_propiedades_especificas_ciudades()
	print("\n=== Tests completados exitosamente ===")