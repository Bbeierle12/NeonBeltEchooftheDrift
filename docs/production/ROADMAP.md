# Production Roadmap: NEON BELT

**Target**: 20-week MVP → 1.0 Release
**Last Updated**: 2025-11-12

---

## Overview

This roadmap breaks down development into 4 major phases, each building progressively toward a shippable 1.0 release.

### Success Metrics (MVP)

- **New player**: Survive 8–10 waves by run 3
- **D1 retention**: ≥35% (demo)
- **Average session**: ≥15 min
- **Flow state**: Within 2 min
- **Build diversity**: At least 3 viable S-tier builds across archetypes

---

## Phase 1: CORE (Weeks 1–6)

**Goal**: Playable vertical slice with tight core loop

### Deliverables

#### Flight & Physics
- ✅ Flight model (thrust, drift, rotation, screen wrap)
- ✅ Collision detection system
- ✅ Physics integration (velocity, inertia, friction)

#### Ships (2)
- ✅ **Interceptor** (Viper Mk-II): Bullet Time signature
- ✅ **Gunship** (Anvil-4): Overcharge signature

#### Asteroids (4 Types)
- ✅ **Basalt**: Splitting logic (L→M→S)
- ✅ **Crystal**: Refraction mechanics
- ✅ **Volatile**: Defuse/explosion + chain reactions
- ✅ **Armored**: Ricochet angles + Slug eject

#### Weapons (3)
- ✅ **Autocannon**: Kinetic baseline
- ✅ **Beam Lance**: Energy ramp + refraction
- ✅ **Rockets**: Explosive AoE + ammo system

#### Core Systems
- ✅ Heat management (generation, venting, shield penalty)
- ✅ Ammo crafting (basic)
- ✅ Loot drop + resource pickup
- ✅ Hypershift dash (invuln + cooldown)
- ✅ Overdrive ability

#### Content
- ✅ 6 wave recipes (escalating difficulty)
- ✅ Arcade mode structure
- ✅ Basic UI (health, shields, heat, ammo, score, combo)

#### Tuning
- ✅ Initial balance pass (see GDD Tuning Reference)
- ✅ Playtesting feedback loop

### Week Breakdown

**Week 1–2**: Foundation
- Project setup, architecture, core flight model
- Collision + physics basics
- Basalt asteroid prototype

**Week 3–4**: Combat Feel
- Autocannon + Beam Lance implementation
- Heat system + venting
- Interceptor ship + Bullet Time
- Crystal refraction

**Week 5–6**: Depth + Juice
- Volatile + Armored asteroids
- Rockets + ammo
- Gunship + Overcharge
- Hypershift + Overdrive
- 6 wave recipes + Arcade mode
- UI pass

### Exit Criteria

- [ ] Can play 10-wave run with Interceptor + Autocannon/Beam
- [ ] Refraction feels satisfying
- [ ] Volatile defuse is readable and tense
- [ ] Heat venting creates meaningful risk
- [ ] One synergy shines (Beam + Crystal)

---

## Phase 2: DEPTH (Weeks 7–12)

**Goal**: Progression hooks, build diversity, meta loop

### Deliverables

#### Weapons (3 More)
- ✅ **Railgun**: Charge + pierce + armor damage
- ✅ **Flak**: Airburst AoE
- ✅ **Mines**: Sticky/proximity modes

#### Ships (1 More)
- ✅ **Miner** (Prospect S): Drone signature + economy bonuses

#### Drone System
- ✅ Collector drone (auto-pickup)
- ✅ Defuser drone (auto-Volatile)
- ✅ Gun drone (turret)

#### Modules & Utilities
- ✅ **Shield Mods**: Prism, Phase, Kinetic Mesh
- ✅ **Thrusters**: Vector, Pulse, Inertial Dampers
- ✅ **Targeting**: Smart Lead, Gyro, Multilock
- ✅ **Economy**: Magnet, Furnace, Fabricator

#### Progression
- ✅ **Contracts**: Side objectives with rewards
- ✅ **Shops**: Buy/sell, repairs, mods, rerolls
- ✅ **Run-based upgrades**: Pierce, Ricochet, Chain, etc.
- ✅ **Research Data**: Meta currency
- ✅ **Meta unlock tree**: Ships, weapons, modules + row bonuses

#### Content
- ✅ **Prism Verge sector**: Crystal biome
- ✅ **Grav-lens hazard**: Shot/debris curvature
- ✅ **Quarrymind boss**: Magnetic armor assembly
- ✅ Sector progression system (3–5 sectors/run)
- ✅ **Daily Seed mode**: Fixed RNG

### Week Breakdown

**Week 7–8**: Weapons + Modules
- Railgun, Flak, Mines
- Shield mods + Thrusters
- Targeting + Economy utilities

**Week 9–10**: Progression Systems
- Contract system
- Shop implementation
- Run-based upgrades (card system)
- Research Data economy

**Week 11–12**: Content + Meta
- Miner ship + drone AI
- Prism Verge sector + Grav-lens
- Quarrymind boss
- Meta unlock tree
- Daily Seed infrastructure

### Exit Criteria

- [ ] 5+ meaningful build archetypes (sniper, spray, beam refract, mine control, etc.)
- [ ] Contracts add texture without overwhelming
- [ ] Shop economy feels fair (Miner advantage is clear)
- [ ] Meta unlocks motivate "one more run"
- [ ] Quarrymind is a memorable skill check

---

## Phase 3: VARIETY (Weeks 13–18)

**Goal**: Content explosion, replayability, social features

### Deliverables

#### Weapons (4 More)
- ✅ **Grav Sling**: Exotic (tether + fling rocks)
- ✅ **Arc Harpoon**: Exotic (chain bodies)
- ✅ **Pulse Laser**: Harmonic music sync crits
- ✅ **Plasma Cutter**: Short-range Volatile melter

#### Ships (2 More)
- ✅ **Trickster** (Mirage): Echo Decoy
- ✅ **Support** (Chord): Resonance Field (co-op)

#### Sectors (2 More)
- ✅ **Stormtrack**: Lightning/EMP biome
- ✅ **Silent Archive**: UFO architecture

#### Bosses & Mini-Bosses
- ✅ **Ion Wyrm** (Stormtrack): Serpent with rotating weak point
- ✅ **Archivist** (Silent Archive): Mirror fight
- ✅ **Corsair Frigate**: Turret + mine mini-boss

#### Enemies
- ✅ **UFO Sentries**: Sniper drones
- ✅ **Scavenger Drones**: Loot thieves

#### Special Spawns
- ✅ **Mimic**: Fake rock → homing drone
- ✅ **Comet**: Screen-crossing boss rock with slow tail

#### Systems
- ✅ **Event system**: Shop, cache, distress, ambush
- ✅ **Branching sector map**
- ✅ **Online leaderboards** + seed verification
- ✅ **Assist-mode leaderboards** (separate)
- ✅ **2P Co-op** netcode (local/online)
- ✅ **Streamer mode** (hide seeds, overlay-friendly)
- ✅ **Photosensitivity preset**

### Week Breakdown

**Week 13–14**: Exotic Weapons + Trickster
- Grav Sling + Arc Harpoon
- Trickster ship + Echo Decoy
- Pulse Laser + Plasma Cutter

**Week 15–16**: Sectors + Bosses
- Stormtrack sector
- Ion Wyrm boss
- Silent Archive sector
- Archivist boss
- Corsair Frigate mini-boss

**Week 17–18**: Multiplayer + Social
- Netcode infrastructure
- 2P Co-op mode
- Support ship (Chord)
- Online leaderboards + seed verification
- Streamer mode
- Photosensitivity preset
- Event system + sector map

### Exit Criteria

- [ ] Exotic weapons enable "highlight reel" moments
- [ ] All 3 new bosses test different skills
- [ ] Co-op feels cooperative (buffs matter)
- [ ] Leaderboards are cheat-resistant
- [ ] Photosensitivity preset is genuinely helpful

---

## Phase 4: POLISH (Weeks 19–20)

**Goal**: Ship-ready quality, balance, onboarding

### Deliverables

#### Audio & Visual
- ✅ **VFX pass**: Heat vents, refracts, explosions, beams
- ✅ **Audio pass**: Weapons, impacts, ambience, music
- ✅ **Hitstop + screen shake**: With intensity sliders
- ✅ **Camera juice**: Tracking improvements

#### Scoring & Meta
- ✅ **Scoring system**: Combo multiplier
- ✅ **Style bonuses**: Ricochet, refract chains, tether KO
- ✅ **Achievement system**
- ✅ **Mastery system**: Challenge unlocks
- ✅ **Weekly Challenges**
- ✅ **Boss Rush mode**
- ✅ **Mutator system**: Low Friction, EMP Drizzle, etc.

#### Content
- ✅ **Rustfields sector**: Tutorial-ish starter biome

#### UX & Accessibility
- ✅ **Tutorial + onboarding** flow
- ✅ **UI/UX polish**: Menus, transitions, clarity
- ✅ **Trajectory hints** for incoming asteroids
- ✅ **Telegraph system**: UFO beams, Volatile pulses
- ✅ **Color coding** (blue/orange/violet/green/red)
- ✅ **Full accessibility pass**: Game speed, comfort toggles, colorblind
- ✅ **Controller support** + full remapping

#### Quality Assurance
- ✅ **Balance sweep**: Weapons, ships, enemies
- ✅ **Daily Seed curation**: Ensure quality runs
- ✅ **Full QA pass**: Bug fixing
- ✅ **Performance optimization**
- ✅ **Telemetry verification**: Data collection + analysis

#### Release Prep
- ✅ **Store page assets**: Screenshots, trailers, key art
- ✅ **Marketing materials**
- ✅ **Final build prep**
- ✅ **Platform deployment**

### Week Breakdown

**Week 19**: Polish + Balance
- VFX + Audio passes
- Hitstop, shake, camera juice
- Scoring + style bonuses
- Balance sweep (all content)
- Achievements + Masteries
- Boss Rush + Mutators
- Rustfields sector

**Week 20**: QA + Ship
- Tutorial + onboarding
- Full accessibility pass
- Controller support
- UI/UX polish (trajectory hints, telegraphs, color coding)
- QA pass + bug fixing
- Performance optimization
- Telemetry verification
- Store assets
- Final build + deployment

### Exit Criteria

- [ ] New player can reach wave 8 by run 3
- [ ] D1 retention ≥35%
- [ ] Average session ≥15 min
- [ ] Flow state within 2 min
- [ ] 3+ S-tier viable builds
- [ ] All accessibility features tested
- [ ] Zero critical bugs
- [ ] Store page ready

---

## Telemetry Plan (Ship from Day 1)

### Core Metrics

**Run Data**:
- `run_start`, `run_finish`, `sector`, `wave`, `seed`
- `death_cause`, `final_score`, `time_played`

**Weapon Stats**:
- `weapon_usage_time`, `damage_dealt`, `accuracy`
- `heat_vent_events`

**Economy**:
- `upgrades_chosen`, `upgrades_ignored`
- `shop_rerolls`, `contracts_win_rate`

**Boss Metrics**:
- `boss_phase_time`, `attempts_to_kill`

**Asteroid Stats**:
- `asteroid_type_kill_counts`
- `volatile_chain_stats`

**Accessibility**:
- `comfort_toggles_used`
- `avg_game_speed`
- `photosensitivity_preset_adoption`

### Analysis Goals

- Identify overperforming/underperforming builds
- Balance asteroid spawn rates
- Tune boss difficulty curves
- Validate accessibility feature usage
- Optimize onboarding flow

---

## Risk Mitigation

### High-Risk Areas

1. **Co-op Netcode** (Phase 3)
   - Mitigation: Start early in Phase 2, allocate buffer time
   - Fallback: Ship local co-op first, online in patch

2. **Balance Complexity** (Phase 4)
   - Mitigation: Continuous playtesting from Phase 1
   - Fallback: Focus on 5 "core" builds, balance rest post-launch

3. **Performance** (Phases 3–4)
   - Mitigation: Profile regularly, optimize particle systems early
   - Fallback: Scale down max asteroid counts on low-end hardware

4. **Scope Creep**
   - Mitigation: Strict "must-have / nice-to-have" triage
   - Fallback: Cut exotic weapons to post-launch content

---

## Post-Launch Considerations

**Patch 1.1** (4 weeks post-launch):
- Balance adjustments based on telemetry
- Community-requested QoL features
- Bug fixes

**DLC/Expansion Ideas** (TBD):
- New sector (e.g., "Void Rift")
- 2 new ships
- 3 new exotic weapons
- Endless mode
- More mutators

---

**End of Roadmap v0.1.0**
