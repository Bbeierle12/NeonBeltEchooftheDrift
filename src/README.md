# Source Code

Godot 4 game implementation for NEON BELT: Echo of the Drift.

## Directory Structure

```
/src/
├── core/              # Core systems (autoloads)
│   ├── game_manager.gd    # Game state, runs, telemetry
│   └── data_loader.gd      # JSON data loading
├── entities/          # Game entities
│   ├── ship.gd        # Player ship controller
│   ├── ship.tscn      # Ship scene
│   ├── asteroid.gd    # Base asteroid class
│   └── asteroid.tscn  # Asteroid scene
├── scenes/            # Game scenes
│   ├── main.gd        # Main game scene
│   └── main.tscn      # Main scene file
├── weapons/           # Weapon systems (TBD)
├── ui/                # UI components (TBD)
└── utils/             # Utility scripts (TBD)
```

## Key Systems

### Core Autoloads

**GameManager** (`core/game_manager.gd`)
- Singleton managing game state
- Run tracking (score, kills, damage)
- Telemetry collection
- Settings management

**DataLoader** (`core/data_loader.gd`)
- Loads JSON game data from `/data`
- Provides getter functions for content
- Hot-reloadable in dev mode

### Ship Controller

**Ship** (`entities/ship.gd`)
- Twin-stick flight physics
- Heat management system
- Weapon hardpoints (A/B)
- Hypershift dash ability
- Overdrive ability
- Shield/hull damage
- Screen wrapping

Controls (default):
- WASD - Movement
- Mouse/Arrows - Aim
- LMB/Space - Fire
- Shift - Hypershift
- E - Overdrive
- R - Vent Heat

### Asteroid System

**Asteroid** (`entities/asteroid.gd`)
- Base class for all asteroid types
- Physics-based movement
- Damage system with type modifiers
- Splitting logic (L→M→S)
- Loot dropping
- Screen wrapping

Asteroid types (from JSON):
- Basalt - Common, splits predictably
- Crystal - Refracts beams, high value
- Volatile - Explosive, defusable
- Armored - Ricochets bullets, ejects slugs

## Running the Game

### Prerequisites

- Godot 4.2+ installed
- Project opened in Godot Editor

### Launch

1. Open `project.godot` in Godot Editor
2. Press F5 or click "Run Project"
3. Main scene (`scenes/main.tscn`) will load

### Debug Controls

- F3 - Toggle debug overlay
- ESC - Pause (TBD)

## Development Notes

### Physics

- Fixed timestep: 60 FPS
- Zero gravity (space environment)
- Custom drag/friction per entity

### Data-Driven Design

All game content loaded from JSON in `/data`:
- Weapons
- Asteroids
- Ships
- Upgrades
- Sectors

Edit JSON → hot-reload → test immediately.

### Code Style

- GDScript with static typing (`var name: Type`)
- DocComments with `##` for all classes
- Signal-based communication
- Composition over inheritance where possible

## Current Phase

**Phase 1 - Core Systems** (Weeks 1-6)

✅ Completed:
- Godot project setup
- Core autoloads (GameManager, DataLoader)
- Ship flight model
- Asteroid base system
- JSON data integration

🚧 In Progress:
- Weapon systems
- Combat feedback
- Basic UI/HUD

⏳ Pending:
- Additional asteroid types (Crystal, Volatile, Armored)
- Wave generation
- Loot drops
- Scoring

---

**Last Updated**: 2025-11-12
