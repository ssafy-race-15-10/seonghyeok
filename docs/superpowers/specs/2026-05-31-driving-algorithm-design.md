# SSAFY Race Bot — Driving Algorithm Design

**Date:** 2026-05-31
**Target:** Map 10 (Basic Round) first, all tracks eventually
**Mode:** Single player
**Goal:** Fastest lap time

---

## Overview

A weighted lookahead driving algorithm implemented entirely within `MyCar.java`.
Four logical blocks handle track detection, parameter selection, steering, and speed control.
No external files or libraries required beyond what the bot template provides.

---

## Architecture

```
MyCar
├── TrackDetector       — identifies track at runtime, selects active TrackParams
├── TrackParams         — per-track tuning constants (inner class)
├── SteeringController  — computes steering output from lookahead + position signals
└── SpeedController     — computes target speed and throttle/brake from curve severity
```

All state is held in member variables. `control_driving` reads sensing data, passes it through each block in order, and writes the result to `car_controls`.

---

## Track Detection

Runs once on the first `control_driving` call. Uses `sensing_info.half_road_limit` to identify road width category, then locks in the result.

| `half_road_limit` | Track category |
|-------------------|---------------|
| ≈ 12.25 | TRACK_SSAFY |
| ≈ 8.25 | TRACK_GERMANY |
| ≈ 9.25 | TRACK_BASIC (default) |

After TRACK_BASIC is set, the detector monitors `track_forward_obstacles` each tick. On first non-empty observation, it upgrades to TRACK_SPEED. This transition is one-way and happens at most once.

A boolean flag `trackInitialized` gates the `half_road_limit` read so it only runs on the first call.

---

## Steering Controller

Steering is the sum of three weighted error signals:

```
steering = K1 * centerError + K2 * angleError + K3 * lookaheadAngle
```

**centerError** — pulls the car back to the road center:
```
centerError = -(to_middle / half_road_limit)
```
Negative because positive `to_middle` (right of center) requires left steering.

**angleError** — aligns the car with the road direction:
```
angleError = -(moving_angle / 90.0)
```

**lookaheadAngle** — anticipates upcoming curves using exponential decay weighting:
```
weight[i]    = exp(-i * decayFactor)
lookaheadAngle = Σ (track_forward_angles[i] * weight[i]) / Σ weight[i]
               for i in [0, steerLookAhead)
```
A larger `decayFactor` focuses on near segments; a smaller value gives more influence to distant segments.

Final output is clamped to `[-1.0, +1.0]`.

---

## Speed Controller

Reads the upcoming road shape and sets a target speed, then decides throttle vs brake.

**Target speed:**
```
maxCurveAngle = max(|track_forward_angles[i]|)  for i in [0, speedLookAhead)
targetSpeed   = clamp(maxSpeed - slowdownFactor * maxCurveAngle, minSpeed, maxSpeed)
```

**Throttle / brake decision:**
```
speedDiff = targetSpeed - currentSpeed

if speedDiff > 0:
    throttle = min(1.0, speedDiff / accelerationRange)
    brake    = 0.0
else:
    throttle = 0.0
    brake    = min(1.0, -speedDiff / brakeRange)
```

Gentle deceleration is handled by reducing throttle; hard deceleration engages the brake.

---

## TrackParams

All tuning constants are grouped in a `TrackParams` inner class. One instance per track category.

| Parameter | BASIC | SPEED | SSAFY | GERMANY |
|-----------|-------|-------|-------|---------|
| `maxSpeed` (km/h) | 130 | 120 | 110 | 100 |
| `minSpeed` (km/h) | 40 | 35 | 30 | 25 |
| `slowdownFactor` | 0.8 | 0.9 | 1.0 | 1.2 |
| `steerLookAhead` | 5 | 6 | 7 | 8 |
| `speedLookAhead` | 6 | 7 | 8 | 10 |
| `K1` (center weight) | 0.3 | 0.3 | 0.4 | 0.5 |
| `K2` (angle weight) | 0.4 | 0.4 | 0.5 | 0.6 |
| `K3` (lookahead weight) | 0.3 | 0.3 | 0.3 | 0.4 |
| `decayFactor` | 0.4 | 0.4 | 0.3 | 0.5 |
| `accelerationRange` | 30 | 30 | 25 | 20 |
| `brakeRange` | 40 | 40 | 35 | 30 |

Initial values are estimates based on track characteristics. All values are expected to be tuned after first test runs.

**Track rationale:**
- **BASIC**: No obstacles, gentle curves — high max speed, short lookahead.
- **SPEED**: Long straight + obstacles — slightly lower max speed; obstacle avoidance to be added later.
- **SSAFY**: Wide road but right-angle corners and elevation changes — higher slowdown sensitivity.
- **GERMANY**: Narrowest road, hairpin corners — long lookahead, high steering weights.

---

## Constraints

- Only `MyCar.java` is submitted. All logic must live in this file.
- Modifiable areas: member variables, `control_driving` body, custom methods and inner classes.
- `sensing_info.half_road_limit` is accessible anywhere.
- Control loop period: 0.1 seconds. No async or threading.

---

## Out of Scope (this iteration)

- Obstacle avoidance logic for SPEED / SSAFY / GERMANY tracks
- Multi-player opponent handling
- Racing line optimization (apex-in, apex-out positioning)
