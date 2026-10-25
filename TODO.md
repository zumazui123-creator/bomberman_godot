# Bomberman Godot - Todo List

## ✅ Progress Overview
- Kimme scripts and systems sind vorhanden
- Gemming ist im Arbeit
- Einfache Gegner-Steuerung implementiert
- Input-Configuration festgelegt

## 🔴 Critical - Needs Completion

### Scripts mit `pass stub()` oder unvollständig:
- [ ] **bomb.gd**: `_ready()` Methode implementieren
- [ ] **bomb.gd**: `spawn_explosion()` Methode komplettieren (missing resolution logic)
- [ ] **collision_system.gd**: COLLISION SYSTEM implementieren (empty file)
- [ ] **level_tscn.gd**: Empty file - Level loading logic erstellen
- [ ] **explosion.gd**: `check_collisions()` komplettieren
- [ ] **explosion.gd**: `directions()` implementieren
- [ ] **explosion.gd**: `destroy_tile()` implementieren
- [ ] **player_controller.gd**: `_physical_process()` mit Kollisionsbehandlung
- [ ] **player_controller.gd**: `_process()` mit unsichtbarkeit timeout
- [ ] **player_controller.gd**: `can_collide()` mit tilemap check

### Empty Scripts (leere Dateien):
- [ ] `scripts/collisions_bomb.gd` - Bomben-Kollisionen
- [ ] `scripts/collision_system.gd` - Zentrale Kollisionsverarbeitung
- [ ] `scripts/level_tscn.gd` - Level-Scene Management

## 🟡 Important - Implementation Needed

### Empty Enemy Scripts:
- [ ] `scripts/enemies/patroller.gd`: `take_damage()`, `start_interview()`, `end_interview()`, `_on_body_entered()`
- [ ] `scripts/enemies/tracer.gd`: `on_die()`, Collision handling

### Empty Folders (遗漏的内容):
- [ ] **`scripts/items/`** - Power-ups, potion items, weapon upgrades
- [ ] **`scripts/ui/`** - Score display, health bars, timer, game over screen
- [ ] **`scenes/`** - 
  - `main.tscn` (referenced in project.godot but missing)
  - `player.tscn` 
  - `explosion.tscn`
  - `tilemap.tscn`
- [ ] **`level_data/`** - Level definition files (JSON or Godot scene files)

## 🟢 Nice to Have - Future Features

### Game Loop & Logic:
- [ ] Game state management (menu, playing, paused, game over)
- [ ] Win/lose conditions
- [ ] Score tracking system
- [ ] Timer/level progress
- [ ] Restart level functionality

### AI Improvements:
- [ ] Better enemy pathfinding
- [ ] Enemy stacking avoidance
- [ ] Different enemy behaviors (flee, attack patterns)
- [ ] Multiple enemy variants

### Polish:
- [ ] Sound effects (explosions, player steps, power-ups)
- [ ] Particle effects (dirt, sparks, death animation)
- [ ] Camera follow
- [ ] Jump history / directional movement bug fix in player_controller
- [ ] Bomb collision with walls (walls should block bombs properly)

## 📝 Notes
- N64-style bomb mechanic: bombing in multiple directions simultaneously
- Player speed severely limited by WASD/mouse collision solution
- Enemy vision tracking requires door/wall logic for blocking
- N64 Mod 3 behavior: bombs that don't reset blocks
