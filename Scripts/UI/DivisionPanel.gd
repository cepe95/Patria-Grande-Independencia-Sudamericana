extends Panel

var division_data: DivisionData

@onready var title := $TitleLabel
@onready var unit_list := $UnitList
@onready var btn_fusionar := $BtnFusionar

func _ready() -> void:
	btn_fusionar.pressed.connect(fusionar_seleccionadas)

func mostrar_composicion(data: DivisionData) -> void:
	division_data = data
	title.text = data.nombre
	unit_list.clear()

	for unidad in data.unidades_componentes:
		var entrada := crear_entrada(unidad)
		unit_list.add_child(entrada)

	show()

func crear_entrada(unit_data: UnitData) -> Control:
	var hbox := HBoxContainer.new()

	var check := CheckBox.new()
	check.focus_mode = Control.FOCUS_NONE

	var icon := TextureRect.new()
	icon.texture = unit_data.icono
	icon.custom_min_size = Vector2(32, 32)

	var label := Label.new()
	label.text = "%s (%d)" % [unit_data.nombre, unit_data.tamaño]

	var btn := Button.new()
	btn.text = "Quitar"
	btn.pressed.connect(func(): quitar_unidad(unit_data))

	hbox.add_child(check)
	hbox.add_child(icon)
	hbox.add_child(label)
	hbox.add_child(btn)

	hbox.set_meta("unit_data", unit_data)
	hbox.set_meta("check", check)

	return hbox

func quitar_unidad(unit_data: UnitData) -> void:
	var instancia := preload("res://scenes/strategic/UnitInstance.tscn").instantiate()
	instancia.set_data(unit_data)
	instancia.global_position = global_position + Vector2(randf() * 40 - 20, randf() * 40 - 20)
	get_tree().current_scene.add_child(instancia)

	division_data.unidades_componentes.erase(unit_data)
	division_data.cantidad_total -= unit_data.tamaño

	mostrar_composicion(division_data)

func fusionar_seleccionadas() -> void:
	var seleccionadas := []

	for entrada in unit_list.get_children():
		var check := entrada.get_meta("check") as CheckBox
		if check and check.button_pressed:
			var unit := entrada.get_meta("unit_data") as UnitData
			seleccionadas.append(unit)

	if seleccionadas.size() < 2:
		return

	var utils := preload("res://scripts/strategic/UnitUtils.gd").new()
	var fusionada := utils.fusionar_unidades(seleccionadas)

	if fusionada == null:
		return

	var instancia := preload("res://scenes/strategic/UnitInstance.tscn").instantiate()
	instancia.set_data(fusionada)
	instancia.global_position = global_position + Vector2(randf() * 20 - 10, randf() * 20 - 10)
	get_tree().current_scene.add_child(instancia)

	for u in seleccionadas:
		division_data.unidades_componentes.erase(u)
		division_data.cantidad_total -= u.tamaño

	mostrar_composicion(division_data)
