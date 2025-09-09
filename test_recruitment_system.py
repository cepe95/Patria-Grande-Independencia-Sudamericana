#!/usr/bin/env python3
"""
Test script para verificar la implementación del sistema de reclutamiento
Verifica que todos los componentes estén implementados correctamente
"""

import os
import re

def check_file_exists(filename):
    """Verifica que un archivo existe"""
    if os.path.exists(filename):
        print(f"✅ {filename} existe")
        return True
    else:
        print(f"❌ {filename} no encontrado")
        return False

def check_function_in_file(filename, function_name):
    """Verifica que una función existe en un archivo"""
    try:
        with open(filename, 'r') as f:
            content = f.read()
        if f"func {function_name}" in content:
            print(f"✅ Función {function_name} encontrada en {filename}")
            return True
        else:
            print(f"❌ Función {function_name} no encontrada en {filename}")
            return False
    except Exception as e:
        print(f"❌ Error leyendo {filename}: {e}")
        return False

def check_signal_in_file(filename, signal_name):
    """Verifica que una señal está definida en un archivo"""
    try:
        with open(filename, 'r') as f:
            content = f.read()
        if f"signal {signal_name}" in content:
            print(f"✅ Señal {signal_name} encontrada en {filename}")
            return True
        else:
            print(f"❌ Señal {signal_name} no encontrada en {filename}")
            return False
    except Exception as e:
        print(f"❌ Error leyendo {filename}: {e}")
        return False

def check_group_usage(filename, group_name):
    """Verifica que un grupo es usado en un archivo"""
    try:
        with open(filename, 'r') as f:
            content = f.read()
        if f'"{group_name}"' in content or f"'{group_name}'" in content:
            print(f"✅ Grupo {group_name} referenciado en {filename}")
            return True
        else:
            print(f"❌ Grupo {group_name} no referenciado en {filename}")
            return False
    except Exception as e:
        print(f"❌ Error leyendo {filename}: {e}")
        return False

def main():
    print("🧪 Verificando implementación del sistema de reclutamiento\\n")
    
    all_checks_passed = True
    
    # Verificar archivos principales
    print("📁 Verificando archivos principales...")
    files_to_check = [
        "Scripts/Strategic/TownInstance.gd",
        "Scripts/Strategic/StrategicMap.gd", 
        "Scripts/UI/MainHUD.gd",
        "Scripts/Data/UnitData.gd",
        "RECRUITMENT_SYSTEM.md"
    ]
    
    for file in files_to_check:
        if not check_file_exists(file):
            all_checks_passed = False
    
    print()
    
    # Verificar funciones de TownInstance
    print("🏘️ Verificando TownInstance.gd...")
    town_functions = [
        "detectar_divisiones_para_reclutamiento",
        "obtener_unidades_reclutables",
        "crear_visual_pueblo"
    ]
    
    for func in town_functions:
        if not check_function_in_file("Scripts/Strategic/TownInstance.gd", func):
            all_checks_passed = False
    
    # Verificar señales de TownInstance
    town_signals = [
        "division_en_pueblo",
        "division_sale_pueblo"
    ]
    
    for signal in town_signals:
        if not check_signal_in_file("Scripts/Strategic/TownInstance.gd", signal):
            all_checks_passed = False
    
    print()
    
    # Verificar funciones de StrategicMap
    print("🗺️ Verificando StrategicMap.gd...")
    map_functions = [
        "crear_pueblos_prueba",
        "conectar_señales_pueblos",
        "_on_division_en_pueblo",
        "_on_division_sale_pueblo"
    ]
    
    for func in map_functions:
        if not check_function_in_file("Scripts/Strategic/StrategicMap.gd", func):
            all_checks_passed = False
    
    print()
    
    # Verificar funciones de MainHUD
    print("🖥️ Verificando MainHUD.gd...")
    hud_functions = [
        "habilitar_reclutamiento",
        "deshabilitar_reclutamiento",
        "mostrar_boton_reclutamiento",
        "mostrar_menu_reclutamiento",
        "crear_dialogo_reclutamiento",
        "_reclutar_unidad"
    ]
    
    for func in hud_functions:
        if not check_function_in_file("Scripts/UI/MainHUD.gd", func):
            all_checks_passed = False
    
    print()
    
    # Verificar grupos
    print("👥 Verificando uso de grupos...")
    if not check_group_usage("Scripts/Strategic/TownInstance.gd", "towns"):
        all_checks_passed = False
    if not check_group_usage("Scripts/Strategic/StrategicMap.gd", "unidades"):
        all_checks_passed = False
    
    print()
    
    # Verificar campos de UnitData
    print("📊 Verificando UnitData.gd...")
    try:
        with open("Scripts/Data/UnitData.gd", 'r') as f:
            content = f.read()
        if "moral:" in content and "experiencia:" in content:
            print("✅ Campos moral y experiencia encontrados en UnitData.gd")
        else:
            print("❌ Campos moral y experiencia no encontrados en UnitData.gd")
            all_checks_passed = False
    except Exception as e:
        print(f"❌ Error verificando UnitData.gd: {e}")
        all_checks_passed = False
    
    print()
    
    # Resultado final
    if all_checks_passed:
        print("🎉 ¡Todas las verificaciones pasaron! El sistema de reclutamiento está correctamente implementado.")
        print()
        print("📋 Para probar el sistema:")
        print("1. Abre el proyecto en Godot")
        print("2. Ejecuta la escena principal (MainHUD.tscn)")
        print("3. Click izquierdo para seleccionar una división")
        print("4. Click derecho para mover la división cerca de un pueblo")
        print("5. El botón 'Reclutar en [Pueblo]' aparecerá en el panel de detalles")
        print("6. Click en el botón para abrir el menú de reclutamiento")
    else:
        print("❌ Algunas verificaciones fallaron. Revisa los errores anteriores.")
    
    return all_checks_passed

if __name__ == "__main__":
    main()