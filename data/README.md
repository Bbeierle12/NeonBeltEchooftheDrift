# Game Data Schemas

All game content is defined in JSON format for easy iteration, balancing, and potential modding support.

## Directory Structure

```
/data/
├── weapons/        # Weapon definitions (kinetic, energy, explosive, exotic)
├── asteroids/      # Asteroid type configurations
├── ships/          # Ship archetypes and stats
├── upgrades/       # Run-based upgrade cards
├── sectors/        # Biome/sector definitions
├── enemies/        # Enemy and boss configurations
└── contracts/      # Contract objectives
```

## Schema Overview

### Weapons (`/weapons/*.json`)

Defines all weapon systems including:
- Base stats (damage, fire rate, heat, ammo)
- Type (kinetic/energy/explosive/exotic)
- Slot compatibility (A/B)
- Upgrade compatibility tags
- SFX/VFX references

**Example**: `/weapons/autocannon.json`

### Asteroids (`/asteroids/*.json`)

Defines asteroid types:
- Size variants (Large/Medium/Small)
- HP values per size
- Split behavior
- Special traits (refract, explode, ricochet)
- Drop tables
- Visual/audio assets

**Example**: `/asteroids/basalt.json`

### Ships (`/ships/*.json`)

Defines ship archetypes:
- Base stats (hull, shields, speed, turn, energy, heat)
- Weapon/utility slots
- Signature ability
- Passive bonuses
- Unlock requirements
- Visual assets

**Example**: `/ships/interceptor.json`

### Upgrades (`/upgrades/*.json`)

Defines run-based upgrades:
- Display name and description
- Stat modifiers
- Behavior tags (pierce, ricochet, chain)
- Rarity tier
- Synergy tags
- Unlock requirements

**Example**: `/upgrades/ricochet.json`

### Sectors (`/sectors/*.json`)

Defines biome characteristics:
- Wave count and difficulty curve
- Asteroid spawn weights
- Hazard types
- Enemy spawn tables
- Boss encounter
- Visual theme
- Music track

**Example**: `/sectors/prism_verge.json`

### Enemies (`/enemies/*.json`)

Defines hostile entities:
- HP and shields
- Movement patterns
- Attack patterns
- Drop tables
- AI behavior type
- Visual/audio assets

**Example**: `/enemies/ufo_sentry.json`

### Contracts (`/contracts/*.json`)

Defines side objectives:
- Objective type (kill count, no damage, time limit, etc.)
- Target values
- Reward amounts (credits, research data)
- Difficulty tier
- Unlock requirements

**Example**: `/contracts/volatile_master.json`

## Validation

All JSON files should be validated against their respective schemas before committing.

Run validation script:
```bash
# TBD: Add validation script once tech stack is chosen
npm run validate-data   # or equivalent
```

## Hot Reloading (Development)

In development builds, JSON files can be hot-reloaded without restarting the game:
1. Edit JSON file
2. Save
3. Game automatically detects changes and reloads affected data

**Note**: Hot reload only works for data files, not code changes.

## Modding Support (Future)

This JSON structure is designed to support community modding:
- Place custom JSON in `/mods/<mod_name>/data/`
- Game merges/overrides base data with mod data
- Mods can add new content or modify existing

---

**Last Updated**: 2025-11-12
