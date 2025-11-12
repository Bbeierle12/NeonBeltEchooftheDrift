# Telemetry System Documentation

**Version**: 0.1.0
**Last Updated**: 2025-11-12

---

## Overview

NEON BELT implements a privacy-respecting telemetry system to collect gameplay data for balancing, bug detection, and feature prioritization.

### Principles

1. **Privacy First**: No PII (personally identifiable information) collected
2. **Opt-in**: Players can disable telemetry entirely
3. **Transparency**: Clear documentation of what is collected
4. **Purpose-Limited**: Data used only for game improvement
5. **Secure**: HTTPS transmission, encrypted storage

---

## Data Collection Events

### Run Lifecycle

**run_start**
```json
{
  "event": "run_start",
  "timestamp": 1734024000,
  "session_id": "uuid-v4",
  "player_id": "anonymous-hash",
  "game_version": "0.1.0",
  "platform": "PC",
  "seed": 123456789,
  "difficulty": "normal",
  "ship_id": "interceptor",
  "control_scheme": "twin_stick",
  "assist_mode": false
}
```

**run_end**
```json
{
  "event": "run_end",
  "timestamp": 1734024900,
  "session_id": "uuid-v4",
  "duration_seconds": 900,
  "final_sector": "prism_verge",
  "final_wave": 5,
  "death_cause": "asteroid_collision",
  "final_score": 125000,
  "kills": {
    "basalt": 120,
    "crystal": 45,
    "volatile": 12,
    "armored": 8,
    "ufo_sentry": 15,
    "scavenger_drone": 20
  },
  "damage_dealt": 85000,
  "damage_taken": 100,
  "deaths": 1
}
```

### Combat Metrics

**weapon_stats**
```json
{
  "event": "weapon_stats",
  "timestamp": 1734024900,
  "session_id": "uuid-v4",
  "sector": "prism_verge",
  "wave": 5,
  "weapon_id": "autocannon",
  "slot": "A",
  "usage_time_seconds": 120,
  "shots_fired": 960,
  "shots_hit": 672,
  "accuracy": 0.70,
  "damage_dealt": 12000,
  "kills": 45,
  "crits": 96,
  "heat_generated": 480,
  "heat_vented": 2
}
```

**asteroid_encounter**
```json
{
  "event": "asteroid_encounter",
  "timestamp": 1734024500,
  "session_id": "uuid-v4",
  "asteroid_type": "volatile",
  "size": "large",
  "outcome": "defused",
  "time_to_resolve": 3.2,
  "damage_taken": 0,
  "chain_triggered": false
}
```

### Progression

**upgrade_chosen**
```json
{
  "event": "upgrade_chosen",
  "timestamp": 1734024300,
  "session_id": "uuid-v4",
  "sector": "rustfields",
  "wave": 3,
  "upgrade_id": "ricochet",
  "other_options": ["pierce", "chain_crit"],
  "current_build": ["autocannon", "beam_lance", "ricochet"],
  "credits_spent": 120
}
```

**shop_interaction**
```json
{
  "event": "shop_interaction",
  "timestamp": 1734024400,
  "session_id": "uuid-v4",
  "sector": "rustfields",
  "action": "buy",
  "item_id": "rocket",
  "price": 150,
  "credits_before": 300,
  "credits_after": 150,
  "rerolls_used": 1
}
```

**contract_result**
```json
{
  "event": "contract_result",
  "timestamp": 1734024450,
  "session_id": "uuid-v4",
  "contract_id": "volatile_master",
  "objective": "pop_3_volatiles_no_damage",
  "result": "completed",
  "attempts": 2,
  "reward_credits": 200,
  "reward_research": 10
}
```

### Boss Encounters

**boss_encounter**
```json
{
  "event": "boss_encounter",
  "timestamp": 1734024600,
  "session_id": "uuid-v4",
  "boss_id": "quarrymind",
  "sector": "prism_verge",
  "attempt": 1,
  "player_hp_start": 100,
  "player_shields_start": 75,
  "current_build": ["autocannon", "ricochet", "pierce"],
  "result": "victory",
  "duration_seconds": 180,
  "damage_dealt": 8500,
  "damage_taken": 60,
  "deaths_during_fight": 0,
  "phase_times": {
    "phase_1": 60,
    "phase_2": 75,
    "phase_3": 45
  }
}
```

### Performance

**performance_snapshot**
```json
{
  "event": "performance_snapshot",
  "timestamp": 1734024700,
  "session_id": "uuid-v4",
  "sector": "prism_verge",
  "wave": 6,
  "avg_fps": 58.5,
  "min_fps": 42,
  "max_fps": 60,
  "frame_time_99th_percentile": 18.2,
  "object_counts": {
    "asteroids": 85,
    "projectiles": 120,
    "particles": 450,
    "enemies": 8
  },
  "memory_usage_mb": 1024,
  "gpu_memory_mb": 512
}
```

### Accessibility

**accessibility_settings**
```json
{
  "event": "accessibility_settings",
  "timestamp": 1734024000,
  "session_id": "uuid-v4",
  "photosensitivity_mode": true,
  "game_speed": 0.8,
  "screen_shake_intensity": 0.3,
  "flash_intensity": 0.2,
  "colorblind_mode": "deuteranopia",
  "reduced_motion": true,
  "subtitles": true
}
```

---

## Data Pipeline

### Collection Flow

```
Game Client
    │
    ├──► Local Buffer (100 events)
    │
    ├──► Batch Send (every 60s or on run end)
    │
    ▼
API Gateway (HTTPS)
    │
    ├──► Validation
    ├──► Sanitization
    ├──► Rate Limiting
    │
    ▼
Message Queue
    │
    ├──► Processing Worker
    │   ├──► Aggregation
    │   ├──► Anomaly Detection
    │   └──► Storage
    │
    ▼
PostgreSQL / Time-Series DB
    │
    └──► Analytics Dashboard
```

### Storage Schema (PostgreSQL)

**runs** table
```sql
CREATE TABLE runs (
    id UUID PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    player_id VARCHAR(64) NOT NULL,
    game_version VARCHAR(16),
    platform VARCHAR(16),
    seed BIGINT,
    difficulty VARCHAR(16),
    ship_id VARCHAR(32),
    control_scheme VARCHAR(16),
    assist_mode BOOLEAN,
    duration_seconds INT,
    final_sector VARCHAR(32),
    final_wave INT,
    death_cause VARCHAR(64),
    final_score INT,
    damage_dealt INT,
    damage_taken INT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_runs_timestamp ON runs(timestamp);
CREATE INDEX idx_runs_ship_difficulty ON runs(ship_id, difficulty);
```

**weapon_usage** table
```sql
CREATE TABLE weapon_usage (
    id SERIAL PRIMARY KEY,
    run_id UUID REFERENCES runs(id),
    weapon_id VARCHAR(32),
    usage_time_seconds INT,
    shots_fired INT,
    shots_hit INT,
    damage_dealt INT,
    kills INT,
    crits INT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_weapon_usage_weapon ON weapon_usage(weapon_id);
```

---

## Analytics Queries

### Weapon Win Rate
```sql
SELECT
    wu.weapon_id,
    COUNT(DISTINCT r.id) as total_runs,
    SUM(CASE WHEN r.death_cause IS NULL THEN 1 ELSE 0 END) as wins,
    ROUND(100.0 * SUM(CASE WHEN r.death_cause IS NULL THEN 1 ELSE 0 END) / COUNT(DISTINCT r.id), 2) as win_rate,
    AVG(wu.damage_dealt) as avg_damage
FROM weapon_usage wu
JOIN runs r ON wu.run_id = r.id
WHERE r.timestamp > NOW() - INTERVAL '7 days'
GROUP BY wu.weapon_id
ORDER BY win_rate DESC;
```

### Difficulty Curve Analysis
```sql
SELECT
    final_wave,
    AVG(duration_seconds) as avg_duration,
    COUNT(*) as total_runs,
    AVG(final_score) as avg_score,
    AVG(damage_dealt) as avg_damage_dealt
FROM runs
WHERE timestamp > NOW() - INTERVAL '30 days'
GROUP BY final_wave
ORDER BY final_wave;
```

### Boss Clear Rate
```sql
SELECT
    boss_id,
    difficulty,
    COUNT(*) as attempts,
    SUM(CASE WHEN result = 'victory' THEN 1 ELSE 0 END) as clears,
    ROUND(100.0 * SUM(CASE WHEN result = 'victory' THEN 1 ELSE 0 END) / COUNT(*), 2) as clear_rate,
    AVG(duration_seconds) as avg_duration
FROM boss_encounters
WHERE timestamp > NOW() - INTERVAL '7 days'
GROUP BY boss_id, difficulty
ORDER BY clear_rate ASC;
```

---

## Privacy & Compliance

### Player ID Generation

```python
import hashlib
import uuid

def generate_anonymous_player_id():
    """
    Generate a stable, anonymous player ID.
    Uses machine ID + salt, hashed for anonymity.
    """
    machine_id = get_machine_id()  # OS-specific
    salt = "neonbelt_2025"
    combined = f"{machine_id}:{salt}"
    return hashlib.sha256(combined.encode()).hexdigest()[:16]
```

### Opt-Out

Players can disable telemetry in settings:
```json
{
  "telemetry_enabled": false
}
```

When disabled:
- No events sent to server
- Local analytics only (for debugging)
- Leaderboards still functional

### Data Retention

- **Raw events**: 90 days
- **Aggregated stats**: Indefinite
- **Player ID mapping**: Never stored (one-way hash)

---

## Development Setup

### Local Telemetry Server

```bash
# Start local telemetry receiver
cd tools/telemetry
docker-compose up

# Endpoint: http://localhost:8080/api/telemetry
```

### Testing

```bash
# Send test event
curl -X POST http://localhost:8080/api/telemetry \
  -H "Content-Type: application/json" \
  -d '{
    "event": "run_start",
    "timestamp": 1734024000,
    "session_id": "test-123",
    "ship_id": "interceptor"
  }'
```

---

## Future Enhancements

- Real-time dashboard for live balancing
- A/B testing framework
- Heatmaps for player deaths
- Replay recording (opt-in)
- Community aggregate stats API

---

**End of Telemetry Documentation v0.1.0**
