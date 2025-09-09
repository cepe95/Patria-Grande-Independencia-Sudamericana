# Manual Testing Checklist for Combat System

## Prerequisites
- Open the project in Godot 4.x
- Load the main scene or TestMainHUD scene
- Ensure both Patriota and Realista divisions are visible on the strategic map

## Test Cases

### 1. Basic Combat Detection
**Steps:**
1. Select a division (click on it)
2. Move it close to an enemy division (different faction)
3. **Expected Result:** Combat interface should appear automatically
4. **Verify:** Combat panel shows both units with correct information

### 2. Combat Interface Functionality
**Steps:**
1. Once combat interface is open, verify:
   - Both units show correct names, icons, and stats
   - Combat log displays initial combat message
   - All action buttons are enabled (Attack, Defend, Retreat, Auto)

### 3. Manual Combat Execution
**Steps:**
1. Click "Atacar" (Attack) button
2. **Expected Result:** 
   - Combat log shows turn results
   - Unit stats update (troop numbers, moral)
   - Turn counter advances

### 4. Automatic Combat
**Steps:**
1. Click "Auto" button
2. **Expected Result:**
   - Combat proceeds automatically
   - Multiple turns execute with delays
   - Combat ends when conditions are met

### 5. Combat Retreat
**Steps:**
1. During combat, click "Retirarse" (Retreat)
2. **Expected Result:**
   - Combat ends immediately
   - Event is logged in combat log and main HUD events

### 6. Combat Completion
**Steps:**
1. Let a combat run to completion
2. **Expected Result:**
   - Victory message appears
   - Casualty summary is shown
   - Combat interface closes automatically after delay
   - Results are logged in main HUD events panel

### 7. Event Log Integration
**Steps:**
1. After any combat, check the main HUD events panel
2. **Expected Result:**
   - Combat events are logged with timestamps
   - Different event types have appropriate colors

### 8. Multiple Combat Sessions
**Steps:**
1. Complete one combat
2. Move units to initiate another combat
3. **Expected Result:**
   - System handles multiple combats correctly
   - No conflicts between sessions

## Debug Information

### Console Output to Check
- "✓ MainHUD inicializado"
- "✓ Sistema de combate inicializado" 
- "⚔ Iniciando combate: [Unit1] vs [Unit2]"
- "💥 Turno X: [results]"
- "🏁 Combate terminado: [winner]"

### UI Elements to Verify
- Combat panel appears centered on screen
- Unit icons load correctly (Patriota/Realista)
- Stats update in real-time during combat
- Combat log scrolls automatically
- Buttons respond correctly

### Integration Points to Test
- Strategic map combat detection
- HUD event logging
- Unit data modifications
- Division instance movement callbacks

## Known Limitations
- Combat only triggers on unit movement completion
- Distance threshold is 50 pixels (may need adjustment)
- No terrain modifiers implemented yet
- Combat interface may need UI polish

## Success Criteria
✅ All test cases pass without errors
✅ Combat logic produces reasonable results
✅ UI is responsive and informative
✅ Events are properly logged
✅ System integrates seamlessly with existing game

## Troubleshooting

### If Combat Doesn't Trigger:
- Check that units are from different factions
- Verify units are close enough (< 50 pixels)
- Ensure units have troops (cantidad_total > 0)
- Check console for error messages

### If UI Doesn't Appear:
- Verify CombatPanel.tscn is properly referenced in MainHUD.tscn
- Check that CombatUI node exists in scene tree
- Ensure no script errors in console

### If Combat Logic Fails:
- Check DivisionData has all required fields
- Verify faction names match exactly ("Patriota", "Realista")
- Ensure units are in "activo" state