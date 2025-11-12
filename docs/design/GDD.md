# Game Design Document: NEON BELT

**Working Title**: NEON BELT: Echo of the Drift
**Genre**: Twin-Stick Shooter Roguelite
**Target Platforms**: PC (primary), Console (stretch)
**Version**: 0.1.0
**Last Updated**: 2025-11-12

---

## Table of Contents

1. [Core Fantasy](#core-fantasy)
2. [Game Loops](#game-loops)
3. [Controls](#controls)
4. [Asteroid Ecology](#asteroid-ecology)
5. [Hostiles & Bosses](#hostiles--bosses)
6. [Ships](#ships)
7. [Weapons](#weapons)
8. [Utilities & Modules](#utilities--modules)
9. [Progression Systems](#progression-systems)
10. [Sectors & Structure](#sectors--structure)
11. [Scoring & Leaderboards](#scoring--leaderboards)
12. [Tuning Reference](#tuning-reference)

---

## Core Fantasy

**You're a lone pilot skimming the rim of a volatile asteroid belt**, salvaging rare matter, dueling raiders/UFOs, and routing the debris storm away from frontier colonies.

Every run is about **threading impossible gaps**, **chaining shots**, and **kitbashing your ship into a monster**.

### Design Pillars

1. **Arcade Purity** - Tight handling, instantly readable goals
2. **Toybox Creativity** - Tethers, refracts, grav slings enable emergent play
3. **Skill Expression Through Geometry** - Bank shots, lens curves, comet tail drifts
4. **Inclusive Difficulty** - Photosensitivity presets, game speed control, assist leaderboards
5. **Replay Ethic** - Daily seeds, contracts, mutators, genuine build synergies

---

## Game Loops

### Minute Loop (Moment-to-Moment)

**Drift, thrust, slice the field:**
- Destroy/deflect asteroids
- Loot drops
- Dodge shards + UFO fire

**Risk–Reward Choices:**
- Chase rare ore vein while a Volatile is ticking
- Vent heat to fire super burst but disable shields briefly

**Micro-Goals:**
- Clear wave
- Fill combo meter
- Complete Contract ("pop 3 Volatiles without taking damage")

### Session Loop (One Run)

- Progress through **3–5 Sectors** (biomes) of escalating waves + mini-boss/boss
- **Between waves**: quick-fit upgrades, craft ammo, swap modules, take Contract, repair, bank score
- **Branching events** on lightweight sector map (shop, cache, distress call, ambush)

### Lifetime Loop (Meta)

- Earn **Research Data** to unlock new ships, guns, modules, mutators
- Complete **Masteries** (e.g., "Win with no missiles") → unlock variants/skins
- **Daily/Weekly Challenges** with fixed seeds and leaderboards

---

## Controls

### Default Schemes

**Twin-Stick** (recommended):
- **Left Stick**: Impulse thrust (relative to ship orientation)
- **Right Stick**: Aim + fire

**Classic** (rotate-thrust-fire):
- Rotation + forward thrust + fire button

### Special Actions

- **Overdrive** (one button): Damage + handling boost for 4s → heat spike
- **Hypershift Dash**: Brief invuln + velocity redirect (1.2s cooldown)

### Accessibility

- All controls **fully remappable**
- Screen-shake & flash **intensity sliders**
- **Photosensitivity preset** (reduced effects)

---

## Asteroid Ecology

### Core Types (4 Tiers)

#### 1. Basalt (Common)
- **Behavior**: Breaks into 2–3 medium shards → 3–4 small shards
- **Traits**: Predictable trajectories, good for combo chains
- **HP**: L:240 / M:120 / S:60
- **Drops**: Standard scrap

#### 2. Crystal (Unstable, High-Value)
- **Behavior**: Refracts beam weapons
- **Traits**: Bonus damage from beams, reduced from kinetic
- **HP**: L:180 / M:90 / S:45
- **Drops**: Flux Shards (beam/plasma crafting)

#### 3. Volatile (Hazard)
- **Behavior**: Pulses; explodes if not "defused" (hold mining beam 1s)
- **Traits**: Huge AoE chain if multiple Volatiles nearby
- **HP**: L:180
- **Explosion**: 150 dmg, 220 radius, chain reaction
- **Drops**: High scrap + rare components

#### 4. Armored (Nickel-Iron, Tank)
- **Behavior**: Ricochets bullets at shallow angles; weak to railguns/mines
- **Traits**: On death, ejects Slugs (dangerous high-speed fragments)
- **HP**: L:500
- **Weakness**: Railgun +60% damage
- **Drops**: Heavy scrap, metal

### Special Spawns

- **Grav-Lens**: Tiny singulars that curve shots and debris (clever slingshot plays)
- **Mimic**: Looks like rock; becomes homing drone at 50% HP
- **Comet** (rare wave event): Screen-crossing "boss rock" with icy tail that slows on contact

---

## Hostiles & Bosses

### Common Enemies

**UFO Sentries**
- Circle outside FOV, snipe with telegraphed beams
- Weak to missiles
- Drops: Tech scrap

**Scavenger Drones**
- Steal drops; if they escape → next shop prices +20%
- Fast, low HP
- Priority targets

**Corsair Frigates** (Mini-Boss)
- Turret arcs + mine layers
- Drops: Module cores
- Appears at sector mid-points

### Apex Bosses (Per Sector)

**The Quarrymind** (Prism Verge)
- Magnetic brain that assembles asteroid armor mid-fight
- Strips armor to expose weak point
- Mechanic: Destroy armor segments → DPS window

**Ion Wyrm** (Stormtrack)
- Serpent of plasma riding circular arcs
- Weak point rotates along body
- Mechanic: Track weak spot, avoid plasma trail

**Archivist** (Silent Archive)
- UFO carrier that spawns enemy loadouts you've used
- Mirror fight mechanic
- Adapts to your previous builds

---

## Ships

Each ship has base stats for:
- **Hull** / **Shields** / **Speed** / **Turn Rate** / **Energy** / **Heat Capacity**
- **2 Weapon Hardpoints** (A/B)
- **2 Utility Slots**
- **1 Unique Signature Ability**

### Archetypes

#### 1. Interceptor (Viper Mk-II) – "Precision Hunter"
- **Signature**: Bullet Time (auto time-dilate to 70% when collision within 0.4s)
- **Passive**: Bonus crit chance at 0 heat
- **Role**: High-skill, high-reward glass cannon

#### 2. Gunship (Anvil-4) – "Guns Blazing"
- **Signature**: Overcharge (2× rate-of-fire for 3s; heat skyrockets)
- **Passive**: +1 internal ammo bay
- **Role**: Sustained DPS, ammo-hungry builds

#### 3. Miner (Prospect S) – "Economy King"
- **Signature**: Remote Drones (toggle 2 collectors/defusers)
- **Passive**: +20% resource yield, shops -15% price
- **Role**: Safe farming, long-term scaling

#### 4. Trickster (Mirage) – "Control the Chaos"
- **Signature**: Echo Decoy (hologram attracts aim + asteroid drift)
- **Passive**: Hypershift distance +25%
- **Role**: Repositioning, crowd control

#### 5. Support (Chord) – "Co-op Conductor"
- **Signature**: Resonance Field (nearby bullets gain pierce/chain; allies gain DR)
- **Passive**: Shield recharge delay -30%
- **Role**: Multiplayer buffer, beam synergies

---

## Weapons

### Kinetic

**Autocannon**
- 8 RPS, 12 dmg, 0.5 heat/shot, 10% crit
- Upgrades: Ricochet, Chain on Crit

**Railgun**
- 1.2 RPS, 120 dmg, 30 heat/shot
- Pierce line, +60% vs Armored
- Upgrades: Faster charge, overpenetration

**Flak**
- Timed airburst, cone AoE
- Perfect anti-shard/anti-drone
- Upgrades: Larger radius, sticky proximity mode

### Energy

**Beam Lance**
- 40 DPS → 110 DPS ramp (1.5s), 18 heat/s
- Refracts in Crystal asteroids
- Upgrades: Extra refract bounces, faster ramp

**Pulse Laser**
- Rhythmic bursts
- Upgrades: Harmonic (beats sync with music for crits)

**Plasma Cutter**
- Short-range cone, melts Volatiles safely
- Low heat generation

### Explosive

**Rockets**
- 120 dmg + 40 AoE, carry 6, manual/lock-on
- Leaves AoE fire (booster exhaust)
- Craft: 2 scrap + 1 flux

**Mines**
- Sticky or proximity
- Shine vs Armored/Frigate fights
- Upgrades: EMP burst, chain detonation

### Exotic

**Grav Sling**
- Tethers a rock → flings it along aim
- Creative chaos plays

**Arc Harpoon**
- Anchors two bodies (asteroid↔enemy or enemy↔enemy)
- Collision damage on tether tension

---

## Utilities & Modules

### Shield Mods
- **Prism**: Reflects at small angles
- **Phase**: Short i-frames at 0 shield
- **Kinetic Mesh**: Reduces shard damage

### Thrusters
- **Vector**: Strafe authority
- **Pulse**: Short bursts, less heat
- **Inertial Dampers**: Faster stops

### Targeting
- **Smart Lead**: Predictive aim assist
- **Gyro Aim**: Controller fine-tuning
- **Multilock**: Rocket guidance

### Drone Bay
- **Collector**: Auto-pickup
- **Defuser**: Auto-defuse Volatiles
- **Gun Drone**: Low DPS turret

### Economy
- **Magnet**: Pickup radius +50%
- **Furnace**: Converts junk to ammo
- **Fabricator**: Craft random mod each shop

---

## Progression Systems

### Run-Based (Roguelite Cards/Shop)

**Upgrade Tags**:
- Pierce, Ricochet, Chain
- On-Crit: Shock, On-Kill: Heat Vent
- Beam Refract (extra bounces)
- Rail Capacitors (faster charge)
- Volatile Whisperer (defuse time -50%, extra drops)
- Overdrive Edges (+handling + DR during Overdrive)

### Permanent Meta (Research Tree)

**Unlock progression**:
- Ships, weapons, modules, mutators
- **Row Bonuses**:
  - Row 1: +1 Contract slot
  - Row 2: Extra utility slot for Miner
  - Row 3: "Second Chance" (1 revive/run at 20% HP)

### Synergy Examples

- **Grav Sling + Flak**: Throw rock into flak cloud → cluster chain
- **Beam Lance + Crystal**: Refracted multi-hit lasers + Harmonic rhythm crits
- **Mines + Arc Harpoon**: Chain enemies → mine detonation doubles

---

## Sectors & Structure

### Biomes (4 Total)

1. **Rustfields** – Tutorial-ish, Basalt/Armored mix, Corsair mini-boss
2. **Prism Verge** – Crystal-heavy, Grav-lens hazards, Quarrymind boss
3. **Stormtrack** – Lightning surges, EMP hazards, Ion Wyrm boss
4. **Silent Archive** – UFO architecture, Archivist boss

### Run Structure

- **3–5 Sectors** per run
- Each sector: **5–7 waves → mini-boss → shop/event → boss**
- **Contracts**: Side objectives with cash/Research rewards
- **Shops**: Sell ammo, repairs, mods, rerolls (Miner gets discounts)

### Modes

- **Arcade** (pure score chase)
- **Roguelite Campaign** (meta unlocks)
- **Boss Rush**
- **Daily Seed** (fixed shop RNG)
- **2P Co-op** (local/online)

---

## Scoring & Leaderboards

### Combo Multiplier
- Rises while hitting targets
- Decays with idle/whiffs

### Style Bonuses
- Ricochet kill
- Refracted beam chain
- Mine double
- Tether collision KO

### Leaderboard Separation
- **Assisted runs** → separate boards
- **Daily Seed** → fixed shop RNG for fairness

---

## Tuning Reference

### Player Base Stats
- **Speed**: 210 u/s
- **Turn Rate**: 320°/s (twin-stick ship)

### Weapon Stats (Starting Values)

| Weapon | RPS/DPS | Damage | Heat | Special |
|--------|---------|--------|------|---------|
| Autocannon | 8 RPS | 12 | 0.5/shot | 10% crit |
| Railgun | 1.2 RPS | 120 | 30/shot | Pierce, +60% vs Armor |
| Beam Lance | 40→110 DPS | Ramp | 18/s | Refract |
| Rocket | - | 120+40 AoE | - | Carry 6, Craft: 2 scrap+1 flux |

### Asteroid HP Values

| Type | Large | Medium | Small | Special |
|------|-------|--------|-------|---------|
| Basalt | 240 | 120 | 60 | Split 2→3 |
| Crystal | 180 | 90 | 45 | Beam weakness |
| Volatile | 180 | - | - | 150 dmg, 220 radius |
| Armored | 500 | - | - | Reflect <20°, eject Slugs |

### Boss HP Target
`(base_DPS × 90s) × difficulty_scalar`
- Easy: 0.9
- Normal: 1.0
- Hard: 1.2
- Brutal: 1.5

---

## Content Tables (JSON Seeds)

See [/data](../../data/README.md) for full JSON schema definitions.

**Example Weapon Entry**:
```json
{
  "id": "autocannon",
  "slot": "A",
  "type": "kinetic",
  "rps": 8,
  "dmg": 12,
  "heat": 0.5,
  "tags": ["starter", "ricochet+"]
}
```

**Example Asteroid Entry**:
```json
{
  "id": "basalt",
  "hpL": 240,
  "hpM": 120,
  "hpS": 60,
  "split": [2, 3],
  "traits": ["predictable"]
}
```

---

## Procedural Generation

### Wave Recipe Formula
`asteroid_budget (by HP) + hazard_rolls + enemy_points`

### Difficulty Curve (Per Sector)
- +5–8% asteroid speed
- +2–3% spawn density
- +10% hostile accuracy

### Mutators (One Per Sector)
- Low Friction
- EMP Drizzle
- Heavy Volatiles
- Grav Storm

### Design Principles
- **Early waves**: Teach
- **Mid waves**: Mix
- **Late waves**: Test

---

## UX & Clarity

### Visual Language

**Color Coding**:
- Blue = Shield/Energy
- Orange = Kinetic
- Violet = Plasma
- Green = Economy
- Red = Hazard

### Telegraphs
- UFO beam sweep line
- Volatile pulse rate quickens pre-detonation
- Trajectory hints for big rocks entering FOV

### Accessibility Presets
- Low flash
- Reduced shake
- Thicker outlines
- Larger text
- 80% game speed option

---

**End of GDD v0.1.0**
