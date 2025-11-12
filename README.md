# NEON BELT: Echo of the Drift

**A twin-stick roguelite shooter** about salvaging rare matter, dueling raiders/UFOs, and routing debris storms away from frontier colonies.

## Core Fantasy

You're a lone pilot skimming the rim of a volatile asteroid belt. Every run is about threading impossible gaps, chaining shots, and kitbashing your ship into a monster.

## Project Status

**Phase**: Setup & Pre-production
**Target**: 20-week MVP → 1.0 release
**Current Sprint**: Project initialization

## Quick Links

- [Game Design Document](docs/design/GDD.md)
- [Technical Architecture](docs/technical/ARCHITECTURE.md)
- [Production Roadmap](docs/production/ROADMAP.md)
- [Data Schemas](data/README.md)

## Directory Structure

```
/NeonBeltEchooftheDrift/
├── docs/               # All documentation
│   ├── design/         # Game design documents
│   ├── technical/      # Architecture & technical specs
│   └── production/     # Roadmaps, schedules, postmortems
├── data/               # JSON schemas & game data
│   ├── asteroids/      # Asteroid definitions
│   ├── weapons/        # Weapon configurations
│   ├── ships/          # Ship archetypes
│   ├── upgrades/       # Upgrade/module definitions
│   ├── sectors/        # Biome & sector data
│   ├── enemies/        # Enemy/boss configurations
│   └── contracts/      # Contract definitions
├── src/                # Source code
├── assets/             # Game assets
│   ├── sprites/        # 2D art & animations
│   ├── audio/          # SFX & music
│   └── vfx/            # Particle effects & shaders
├── config/             # Engine & build configs
├── tests/              # Unit & integration tests
├── tools/              # Dev tools & scripts
└── scripts/            # Build automation
```

## Development Setup

> **Note**: Tech stack to be determined. This structure supports Unity, Godot, Unreal, or custom engine.

### Prerequisites

- TBD based on engine choice
- Git for version control
- Node.js (for tooling/scripting)

### Installation

```bash
# Clone repository
git clone <repo-url>
cd NeonBeltEchooftheDrift

# Install dependencies (TBD)
# npm install / pip install requirements.txt / etc.

# Run game (TBD)
# npm run dev / dotnet run / etc.
```

## Design Pillars

1. **Arcade Purity** - Tight handling, instantly readable goals
2. **Toybox Creativity** - Tethers, refracts, grav slings enable emergent combos
3. **Skill Expression** - Geometry matters: bank shots, lens curves, drift arcs
4. **Inclusive Difficulty** - Photosensitivity presets, game speed, separate assist leaderboards
5. **Replay Ethic** - Daily seeds, contracts, mutators, genuine build synergies

## Roadmap Summary

- **Phase 1 (Weeks 1–6)**: Core flight, asteroids, 2 ships, 3 weapons, Arcade mode
- **Phase 2 (Weeks 7–12)**: Depth systems (shops, contracts, meta-progression)
- **Phase 3 (Weeks 13–18)**: Content variety (exotic weapons, co-op, leaderboards)
- **Phase 4 (Weeks 19–20)**: Polish (VFX, audio, balance, QA)

See [ROADMAP.md](docs/production/ROADMAP.md) for full breakdown.

## Contributing

This is currently a solo/small-team project. Contribution guidelines TBD.

## License

TBD

---

**Last Updated**: 2025-11-12
**Version**: 0.1.0-alpha
