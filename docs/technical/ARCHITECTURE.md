# Technical Architecture: NEON BELT

**Version**: 0.1.0
**Last Updated**: 2025-11-12

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Core Systems](#core-systems)
3. [Data Architecture](#data-architecture)
4. [Procedural Generation](#procedural-generation)
5. [Networking](#networking)
6. [Performance Targets](#performance-targets)
7. [Tech Stack](#tech-stack)

---

## System Overview

NEON BELT follows a modular, data-driven architecture optimized for:
- **Rapid iteration** on balance and content
- **Deterministic gameplay** for seed verification
- **Network synchronization** for co-op
- **Telemetry collection** for balancing

### High-Level Architecture

```
┌─────────────────────────────────────────────────┐
│               Game Manager                       │
│  (Mode selection, meta-progression, telemetry)  │
└─────────────────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
┌──────────────┐ ┌──────────┐ ┌──────────────┐
│  Run Manager │ │   UI     │ │ Leaderboards │
│   (Session)  │ │ Manager  │ │   Manager    │
└──────────────┘ └──────────┘ └──────────────┘
        │
        ├──► Wave Manager ──► Spawn Controller
        ├──► Shop Manager
        ├──► Event Manager
        └──► Sector Progression
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
┌──────────────┐ ┌──────────┐ ┌──────────────┐
│    Player    │ │ Asteroid │ │   Hostile    │
│   Controller │ │  System  │ │    System    │
└──────────────┘ └──────────┘ └──────────────┘
        │             │             │
        └─────────────┼─────────────┘
                      ▼
            ┌──────────────────┐
            │  Physics Engine  │
            │  (Collision etc) │
            └──────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
┌──────────────┐ ┌──────────┐ ┌──────────────┐
│  VFX System  │ │  Audio   │ │   Renderer   │
└──────────────┘ └──────────┘ └──────────────┘
```

---

## Core Systems

### 1. Flight Model

**Responsibilities**:
- Player ship physics (thrust, drift, rotation)
- Hypershift dash (invuln + velocity redirect)
- Screen wrapping / boundary handling

**Key Components**:
```
RigidBody2D
├── velocity: Vector2
├── angularVelocity: float
├── mass: float (ship-dependent)
└── drag: float (thruster-dependent)

ShipController
├── ApplyThrust(direction, magnitude)
├── ApplyRotation(degrees)
├── Hypershift(targetDirection)
└── HandleScreenWrap()
```

**Determinism Requirements**:
- Fixed timestep physics (60 FPS)
- Consistent floating-point math across platforms
- Seed-based RNG for procedural elements

---

### 2. Combat System

**Responsibilities**:
- Weapon firing logic (kinetic/energy/explosive)
- Heat management
- Ammo tracking
- Damage calculation
- Overdrive state

**Key Components**:
```
WeaponSystem
├── WeaponSlot A: WeaponInstance
├── WeaponSlot B: WeaponInstance
├── Heat: float (0-100)
├── Fire(slot, targetDirection)
├── VentHeat(amount) → DisableShields(1s)
└── Overdrive() → DamageBuff(4s) → HeatSpike

WeaponInstance
├── Config: WeaponData (JSON)
├── CurrentAmmo: int
├── CurrentHeat: float
├── FireCooldown: float
├── ApplyUpgrades(List<Upgrade>)
└── CalculateDamage(target) → float
```

**Damage Pipeline**:
```
1. Base damage (from WeaponData)
2. Crit roll (ship/upgrade bonuses)
3. Type modifiers (beam vs Crystal, railgun vs Armored)
4. Upgrades (Pierce, Chain, etc.)
5. Apply to target (hull/shield reduction)
6. Trigger effects (Heat Vent, Shock, etc.)
```

---

### 3. Asteroid System

**Responsibilities**:
- Spawning (wave recipes)
- Movement (velocity, rotation)
- Splitting logic (Basalt L→M→S)
- Special behaviors (Crystal refract, Volatile explode, Armored ricochet)

**Key Components**:
```
Asteroid (Base Class)
├── Type: AsteroidType (Basalt, Crystal, Volatile, Armored)
├── Size: AsteroidSize (Large, Medium, Small)
├── HP: float
├── Velocity: Vector2
├── OnDestroy() → virtual
└── OnHit(damage, damageType) → virtual

BasaltAsteroid : Asteroid
└── OnDestroy() → SpawnFragments(2-3 medium)

CrystalAsteroid : Asteroid
├── RefractBeam(incomingRay) → List<Ray>
└── OnHit(damage, damageType) → ApplyTypeModifier()

VolatileAsteroid : Asteroid
├── DefuseProgress: float (0-1)
├── PulseTimer: float
├── OnDefused() → DropExtraLoot()
└── OnDestroy() → ExplodeAoE(150 dmg, 220 radius, chain)

ArmoredAsteroid : Asteroid
├── RicochetAngle: float (20°)
├── OnHit(projectile) → CheckRicochet()
└── OnDestroy() → EjectSlugs(3-5)
```

**Refraction System** (Crystal):
```
BeamRaycast(origin, direction)
├── Hit Crystal?
│   ├── Calculate exit angle (refraction)
│   ├── Apply damage
│   ├── Recurse BeamRaycast(exitPoint, newDirection)
│   └── Max recursion: 3 (upgradeable to 5)
└── Hit other? → Apply damage
```

---

### 4. Procedural Generation

**Responsibilities**:
- Wave recipe generation (seeded RNG)
- Sector progression
- Shop inventory
- Event selection

**Key Components**:
```
WaveGenerator
├── Seed: int64
├── RNG: SeededRandom
├── GenerateWave(sector, waveNum) → WaveRecipe
│   ├── AsteroidBudget (HP-based)
│   ├── HazardRolls (Grav-lens, Comet)
│   ├── EnemyPoints (UFOs, Scavengers)
│   └── DifficultyCurve(sector) → Modifiers
└── ApplyMutator(mutator) → WaveRecipe

WaveRecipe
├── AsteroidSpawns: List<AsteroidSpawn>
│   └── AsteroidSpawn { type, size, count, velocityRange }
├── HazardSpawns: List<HazardSpawn>
├── EnemySpawns: List<EnemySpawn>
└── Duration: float
```

**Difficulty Curve**:
```
Per Sector Increase:
- Asteroid speed: +5–8%
- Spawn density: +2–3%
- Hostile accuracy: +10%
- Volatile frequency: +15%

Formula:
adjustedSpeed = baseSpeed × (1 + sector × 0.06)
adjustedDensity = baseDensity × (1 + sector × 0.025)
```

---

### 5. Progression System

**Responsibilities**:
- Run-based upgrades (cards/shop purchases)
- Meta-progression (Research Data, unlocks)
- Contracts (side objectives)

**Key Components**:
```
UpgradeManager
├── ActiveUpgrades: List<Upgrade>
├── ApplyUpgrade(upgrade) → ModifyStats()
├── RemoveUpgrade(upgrade)
└── CalculateSynergies() → List<SynergyBonus>

MetaProgressionManager
├── ResearchData: int
├── UnlockedShips: Set<ShipID>
├── UnlockedWeapons: Set<WeaponID>
├── UnlockedModules: Set<ModuleID>
├── UnlockTreeProgress: Dictionary<NodeID, bool>
└── SpendResearchData(nodeID) → Unlock

ContractManager
├── ActiveContracts: List<Contract> (max 2-3)
├── CheckProgress(eventType, eventData)
├── CompleteContract(contractID) → Rewards
└── GenerateContracts(sector) → List<Contract>

Contract
├── ID: string
├── Description: string
├── Objective: ObjectiveType (e.g., KillVolatilesWithoutDamage)
├── Progress: int / TargetProgress: int
├── Rewards: { credits: int, researchData: int }
└── OnEvent(eventType, eventData) → UpdateProgress()
```

---

### 6. Shop System

**Responsibilities**:
- Generate inventory (seeded)
- Buy/sell/reroll transactions
- Repair/refuel services

**Key Components**:
```
ShopManager
├── Seed: int64
├── Inventory: List<ShopItem>
├── PlayerCredits: int
├── GenerateInventory(sector, seed)
├── BuyItem(itemID) → DeductCredits, AddToPlayer
├── SellItem(itemID) → AddCredits
├── Reroll() → RegenerateInventory, DeductCredits
└── ApplyDiscounts(shipBonuses) → AdjustPrices

ShopItem
├── ItemType: (Weapon, Module, Upgrade, Ammo, Repair)
├── ItemID: string
├── Price: int
├── Stock: int
└── Description: string
```

---

## Data Architecture

### JSON-Driven Design

All game content defined in `/data/*.json` for:
- Weapons
- Asteroids
- Ships
- Upgrades
- Sectors
- Enemies
- Contracts

**Benefits**:
- Hot-reloading during development
- Easy balance tweaks
- Modding support (future)
- Version control friendly

### Schema Example: Weapon

```json
{
  "id": "autocannon",
  "displayName": "AC-40 Autocannon",
  "slot": "A",
  "type": "kinetic",
  "fireRate": 8.0,
  "baseDamage": 12,
  "heatPerShot": 0.5,
  "critChance": 0.1,
  "critMultiplier": 1.7,
  "projectileSpeed": 800,
  "maxRange": 1200,
  "ammoType": "standard",
  "tags": ["starter", "ricochet_upgradeable"],
  "sfx": {
    "fire": "sfx_autocannon_fire",
    "impact": "sfx_kinetic_impact"
  },
  "vfx": {
    "muzzleFlash": "vfx_autocannon_muzzle",
    "projectile": "vfx_bullet_tracer"
  }
}
```

### Schema Example: Asteroid

```json
{
  "id": "basalt",
  "displayName": "Basalt",
  "sizes": {
    "large": {
      "hp": 240,
      "radius": 64,
      "splitInto": { "medium": [2, 3] }
    },
    "medium": {
      "hp": 120,
      "radius": 32,
      "splitInto": { "small": [3, 4] }
    },
    "small": {
      "hp": 60,
      "radius": 16
    }
  },
  "speedRange": [50, 120],
  "rotationSpeedRange": [10, 45],
  "traits": ["predictable"],
  "dropTable": {
    "scrap": { "min": 5, "max": 15, "chance": 1.0 },
    "flux": { "min": 0, "max": 0, "chance": 0.0 }
  },
  "sprite": "asteroid_basalt",
  "destructionVFX": "vfx_rock_shatter"
}
```

### Schema Example: Ship

```json
{
  "id": "interceptor",
  "displayName": "Viper Mk-II",
  "archetype": "Interceptor",
  "stats": {
    "hull": 100,
    "shields": 75,
    "speed": 220,
    "turnRate": 340,
    "energy": 100,
    "heatCapacity": 100
  },
  "weaponSlots": ["A", "B"],
  "utilitySlots": 2,
  "signature": {
    "id": "bullet_time",
    "displayName": "Bullet Time",
    "description": "Auto time-dilate to 70% when collision imminent (<0.4s)",
    "cooldown": 8.0
  },
  "passive": {
    "id": "zero_heat_crit",
    "description": "+15% crit chance at 0 heat"
  },
  "sprite": "ship_viper",
  "thrusterVFX": "vfx_viper_thrust"
}
```

---

## Procedural Generation

### Seeded RNG

**Requirements**:
- Deterministic across platforms
- Reproducible for Daily Seeds
- Fast generation (< 1ms per wave)

**Implementation**:
```
SeededRNG
├── Seed: int64
├── State: int64 (internal)
├── Next() → int
├── NextFloat(min, max) → float
├── NextInt(min, max) → int
├── Shuffle<T>(list)
└── PickWeighted<T>(items, weights) → T
```

### Wave Budget System

```
CalculateWaveRecipe(sector, waveNum, seed):
    RNG = SeededRNG(seed + sector * 1000 + waveNum)

    budget = baseHP + (sector × 200) + (waveNum × 50)
    hazardChance = 0.1 + (sector × 0.05)
    enemyPoints = sector × 10 + waveNum × 2

    asteroids = []
    while budget > 0:
        type = RNG.PickWeighted([basalt, crystal, volatile, armored])
        size = RNG.PickWeighted([large, medium, small])
        count = RNG.NextInt(1, 5)

        cost = type.hp[size] × count
        if cost <= budget:
            asteroids.Add({type, size, count})
            budget -= cost

    if RNG.NextFloat() < hazardChance:
        hazards.Add(RNG.Pick([grav_lens, comet, mimic]))

    enemies = SpendEnemyPoints(enemyPoints, sector, RNG)

    return WaveRecipe(asteroids, hazards, enemies)
```

---

## Networking

### Co-op Architecture (Phase 3)

**Approach**: Client-server with deterministic simulation

**Network Model**:
```
Host (Server)
├── Authoritative physics
├── Validates client inputs
├── Broadcasts game state (30 Hz)
└── Handles RNG seed

Client
├── Sends inputs (60 Hz)
├── Predicts local state
├── Reconciles with server updates
└── Interpolates remote players
```

**Synchronization**:
- **Fixed timestep**: 16.67ms (60 FPS)
- **Input delay**: 2 frames (33ms) to absorb jitter
- **Rollback**: Re-simulate last 100ms on misprediction

**Bandwidth Target**: < 50 KB/s per client

**Packet Structure**:
```
InputPacket (Client → Server)
├── FrameNumber: uint32
├── Thrust: Vector2 (quantized 12-bit)
├── Aim: Vector2 (quantized 12-bit)
├── Buttons: uint8 (bitflags)
└── Checksum: uint16

StatePacket (Server → Clients)
├── FrameNumber: uint32
├── PlayerStates: List<PlayerState>
├── AsteroidStates: List<AsteroidState> (delta-compressed)
├── ProjectileStates: List<ProjectileState>
└── Checksum: uint32
```

---

## Performance Targets

### Framerate
- **Target**: 60 FPS (locked)
- **Minimum**: 60 FPS on GTX 1060 / RX 580 equivalent
- **Optimization budget**: 16.67ms per frame

### Frame Budget Breakdown
```
Physics:       3.0ms (18%)
Rendering:     8.0ms (48%)
Gameplay:      2.5ms (15%)
Audio:         1.0ms (6%)
UI:            1.0ms (6%)
Overhead:      1.17ms (7%)
────────────────────────
Total:        16.67ms (100%)
```

### Object Limits (Per Frame)
- **Asteroids**: 200 (Large: 20, Medium: 80, Small: 100)
- **Projectiles**: 500
- **Particles**: 2000
- **Enemies**: 30

### Memory Target
- **RAM**: < 2 GB
- **VRAM**: < 1 GB

---

## Tech Stack

### TBD - Engine Options

**Option 1: Unity**
- Pro: Mature tooling, C# productivity, asset store
- Con: License costs, bloat

**Option 2: Godot**
- Pro: Open-source, GDScript rapid iteration, lightweight
- Con: Smaller ecosystem, 3.x vs 4.x decision

**Option 3: Custom (C++ / Rust)**
- Pro: Full control, performance, learning
- Con: Development time, reinventing wheels

**Recommendation**: **Godot 4.x** for MVP (lightweight, fast iteration), with custom engine as post-launch option.

### Supporting Technologies

**Version Control**: Git + GitHub
**CI/CD**: GitHub Actions
**Telemetry**: Custom REST API → PostgreSQL
**Leaderboards**: AWS Lambda + DynamoDB
**Audio**: FMOD or Wwise (TBD)
**Localization**: JSON-based string tables

---

## File Structure (Engine-Agnostic)

```
/src/
├── core/
│   ├── Game.{ext}              # Main game loop
│   ├── Input.{ext}             # Input handling
│   └── Time.{ext}              # Fixed timestep
├── physics/
│   ├── RigidBody.{ext}
│   ├── Collision.{ext}
│   └── Spatial.{ext}           # Quadtree/grid
├── entities/
│   ├── Ship.{ext}
│   ├── Asteroid.{ext}
│   ├── Projectile.{ext}
│   └── Enemy.{ext}
├── systems/
│   ├── WeaponSystem.{ext}
│   ├── HeatSystem.{ext}
│   ├── ShopSystem.{ext}
│   ├── ContractSystem.{ext}
│   └── ProgressionSystem.{ext}
├── procedural/
│   ├── WaveGenerator.{ext}
│   ├── SectorGenerator.{ext}
│   └── SeededRNG.{ext}
├── network/
│   ├── Server.{ext}
│   ├── Client.{ext}
│   └── Sync.{ext}
├── ui/
│   ├── HUD.{ext}
│   ├── Menu.{ext}
│   └── Leaderboard.{ext}
└── utils/
    ├── DataLoader.{ext}        # JSON parsing
    ├── Telemetry.{ext}
    └── Math.{ext}              # Vector, Angle utils
```

---

**End of Architecture v0.1.0**
