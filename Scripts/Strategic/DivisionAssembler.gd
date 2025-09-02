extends Node

func puede_formar_division(unidades: Array) -> bool:
	# Se requiere al menos 2 unidades para formar una división
	return unidades.size() >= 2

func ensamblar_division(unidades: Array):
	if not puede_formar_division(unidades):
		return

	var division_data := DivisionData.new()
	division_data.nombre = "División Compuesta"
	division_data.rama_principal = get_rama_principal(unidades)  # opcional
	division_data.unidades_componentes = unidades
	division_data.cantidad_total = unidades.reduce(func(acc, u): return acc + u.cantidad, 0)
	division_data.icono_path = "res://assets/icons/division.png"

	var division_scene := preload("res://scenes/strategic/DivisionInstance.tscn")
	var division := division_scene.instantiate()
	division.set_data(division_data)

	for u in unidades:
		u.queue_free()

	get_tree().current_scene.add_child(division)

func get_rama_principal(unidades: Array) -> String:
	var conteo := {}
	for u in unidades:
		conteo[u.tipo] = conteo.get(u.tipo, 0) + 1
	var max_tipo := ""
	var max_valor := -1
	for tipo in conteo.keys():
		if conteo[tipo] > max_valor:
			max_valor = conteo[tipo]
			max_tipo = tipo
	return max_tipo
