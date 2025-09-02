extends Node

# Devuelve el nombre textual según el nivel numérico
func get_nombre_nivel(nivel: int) -> String:
	match nivel:
		1: return "Pelotón"
		2: return "Compañía"
		3: return "Batallón"
		4: return "Regimiento"
		_: return "Unidad"

# Fusiona unidades del mismo tipo y nivel en una sola
func fusionar_unidades(unidades: Array) -> UnitData:
	if unidades.size() < 2:
		return null

	var base: UnitData = unidades[0]
	var rama: String = base.rama
	var nivel: int = base.nivel

	# Validar compatibilidad
	for u in unidades:
		if u.rama != rama or u.nivel != nivel or not u.fusionable:
			return null

	# Calcular tamaño total
	var total: int = 0
	for u in unidades:
		total += u.tamaño

	# Crear unidad fusionada
	var fusionada := UnitData.new()
	fusionada.rama = rama
	fusionada.nivel = nivel
	fusionada.tamaño = total
	fusionada.nombre = "%s Fusionada (%d)" % [get_nombre_nivel(nivel), total]
	fusionada.fusionable = true

	var ruta: String = "res://assets/icons/%s %s.png" % [get_nombre_nivel(nivel), rama.capitalize()]
	var textura: Texture2D = load(ruta)
	if textura:
		fusionada.icono = textura

	return fusionada
