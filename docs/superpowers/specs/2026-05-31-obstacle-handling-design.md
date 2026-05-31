# Obstacle Handling & Enhanced Logging — Design Spec

**Date:** 2026-05-31
**Scope:** `Bot_Java/MyCar.java` only
**Goal:** Reduce obstacle collisions, guarantee escape when stuck, improve log data

---

## Problem

1. Car collides with obstacles and gets physically stuck (zero speed, cannot proceed).
2. Existing recovery logic only brakes — no reverse/escape.
3. Log lacks obstacle and stuck-state data needed for tuning.

---

## Architecture Changes

Adds two new logical blocks to the existing four-block structure:

```
MyCar
├── TrackDetector       (existing)
├── TrackParams         (existing)
├── ObstacleHandler     (NEW) — proactive speed reduction + avoidance steering
├── StuckDetector       (NEW) — stuck detection + reverse escape
├── SteeringController  (existing)
├── SpeedController     (existing)
└── LapLogger           (enhanced)
```

`control_driving` call order:
1. TrackDetector
2. SteeringController → raw steering
3. **ObstacleHandler** → blends avoidance into steering, caps target speed
4. SpeedController → uses capped target speed
5. **StuckDetector** → overrides throttle/steering when stuck
6. LapLogger → records all outputs

---

## ObstacleHandler

**Purpose:** Reduce approach speed and strengthen avoidance steering before a collision occurs.

**Speed reduction:**
- Scan `track_forward_obstacles` for obstacles within `obstacleSlowRange = 40m`.
- Closest obstacle at distance `d` → speed cap: `maxSpeed * (1 - maxSlowdown * (1 - d / obstacleSlowRange))`
- `maxSlowdown = 0.4f` → up to 40% speed reduction at distance 0.
- Cap is applied as an upper bound on `targetSpeed` inside `computeTargetSpeed`.

**Avoidance steering:**
- Use closest obstacle only (not sum) to avoid over-correction.
- Signal: `avoidSteer = -2.0 * proximity * (obs.to_middle / half_road_limit)`
  where `proximity = 1 - (obs.dist / obstacleSteerRange)`, `obstacleSteerRange = 25m`.
- Blended into final steering: `steering = clamp(rawSteering + avoidSteer, -1, 1)`.
- Replaces current multi-obstacle sum with proximity threshold of 25m and strength 2.0.

**Parameters (in TrackParams or as constants):**

| Constant | Value | Meaning |
|----------|-------|---------|
| `obstacleSlowRange` | 40m | Distance at which speed reduction begins |
| `obstacleSteerRange` | 25m | Distance at which avoidance steering begins |
| `obstacleMaxSlowdown` | 0.4f | Max fraction of speed reduction |
| `obstacleSteerStrength` | 2.0f | Avoidance steering multiplier |

---

## StuckDetector

**Purpose:** Detect when the car is physically stuck and execute a reverse escape.

**Stuck detection:**
- Each tick: if `speed < 3 km/h` AND `throttle > 0.3` → `stuckTicks++`
- Otherwise: `stuckTicks = 0`
- At `stuckTicks >= 5` (0.5 s): enter REVERSE mode.

**Reverse escape:**
- `reverseTicks = 20` (2 s at 0.1 s/tick)
- Each reverse tick:
  - `throttle = -0.5` (reverse)
  - `brake = 0f`
  - `steering = clamp(-(to_middle / half_road_limit), -1, 1)` ← steer toward center
  - `reverseTicks--`
- At `reverseTicks == 0`: reset `stuckTicks`, resume normal driving.

**Replaces** existing `recoveryTicks` collision-brake logic entirely.
Collision braking is no longer needed: ObstacleHandler reduces speed before impact,
and StuckDetector handles post-impact escape.

**State variables added:**
```java
private int stuckTicks   = 0;
private int reverseTicks = 0;
```

---

## Enhanced Logging

### CSV columns

```
tick, lap, progress, speed, to_middle, moving_angle,
steering, throttle, brake, collided,
obs_count, obs_nearest_dist, target_speed,
stuck_ticks, reverse_ticks,
elapsed_ms
```

`obs_nearest_dist` = distance to closest obstacle, `-1` if none.
`target_speed` = value computed by SpeedController before StuckDetector override.

### Event marker rows

Inserted as comment lines in the CSV when state changes:

```
# STUCK at progress=34.2 speed=0.3
# REVERSE START at progress=34.2
# REVERSE DONE at progress=35.8
# OBSTACLE CLOSE: dist=8.5 to_middle=2.1 avoid_steer=-0.74
# LAP N COMPLETE: Xs
```

### Console output

Printed only on events (not per tick):
- `[STUCK] progress=X speed=Y`
- `[REVERSE] START at progress=X`
- `[REVERSE] DONE at progress=X`
- `[LAP N] Xs`

All other `System.out.println` calls (debug block) remain gated behind `is_debug`.

---

## Success Criteria

1. Car completes a full lap on Map 31 (Speed Racing with obstacles) without permanent stops.
2. CSV shows `stuck_ticks` reaches 5 and `reverse_ticks` counts down at least once per run.
3. `obs_nearest_dist` reflects real obstacle proximity data each tick.
