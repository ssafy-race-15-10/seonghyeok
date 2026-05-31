# SSAFY Race — Driving Algorithm Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a weighted lookahead driving bot in `MyCar.java` that auto-detects the track and achieves competitive lap times across all four SSAFY Race tracks.

**Architecture:** Four logical blocks (TrackDetector, TrackParams, SteeringController, SpeedController) live entirely within `MyCar.java` as static inner classes and static helper methods. Pure static helpers enable local unit testing without the simulator.

**Tech Stack:** Java (JDK 1.8+), IntelliJ or Eclipse, AirSim simulator (Windows only)

---

## Prerequisites

Download the bot template from the competition board and place it at `bot_java/` under the project root. Verify these files exist:
- `bot_java/DrivingInterface.java`
- `bot_java/DrivingInterface.dll`
- `bot_java/MyCar.java`

Open `DrivingInterface.java` and confirm the following names match. If they differ, update this plan before proceeding:
- `sensing_info.to_middle`, `sensing_info.half_road_limit`, `sensing_info.speed`
- `sensing_info.moving_angle`, `sensing_info.track_forward_angles` (type: `ArrayList<Integer>`)
- `sensing_info.track_forward_obstacles` (type: `ArrayList<?>`, non-empty when obstacles present)
- `car_controls.steering`, `car_controls.throttle`, `car_controls.brake`

---

## File Structure

```
bot_java/
├── DrivingInterface.java   — template base class (do not modify)
├── DrivingInterface.dll    — native simulator bridge (do not modify)
├── MyCar.java              — all implementation goes here (submitted to competition)
└── TestRunner.java         — local unit test harness (NOT submitted)
```

---

## Task 1: Git init and project scaffold

**Files:**
- Create: `bot_java/TestRunner.java`
- Modify: `bot_java/MyCar.java` (add skeleton only)

- [ ] **Step 1: Initialize git**

```bash
cd /Users/whqtker/Documents/SSAFY/ssafy-race
git init
git add CLAUDE.md docs/
git commit -m "chore: initial project structure and design docs"
```

- [ ] **Step 2: Add skeleton constants and inner class declaration to MyCar.java**

Inside `MyCar.java`, above the `control_driving` method (and below any existing imports/class declaration), add:

```java
    // --- Track type constants ---
    static final int TRACK_BASIC   = 0;
    static final int TRACK_SPEED   = 1;
    static final int TRACK_SSAFY   = 2;
    static final int TRACK_GERMANY = 3;

    // --- TrackParams inner class (populated in Task 2) ---
    static class TrackParams {
        // fields added in Task 2
    }

    // --- State ---
    private boolean trackInitialized = false;
    private int trackType = TRACK_BASIC;
```

- [ ] **Step 3: Create TestRunner.java**

```java
public class TestRunner {
    public static void main(String[] args) {
        System.out.println("TestRunner ready. Add test calls here.");
    }

    static void assertTrue(boolean condition, String message) {
        if (!condition) throw new AssertionError("FAIL: " + message);
    }
}
```

- [ ] **Step 4: Verify TestRunner compiles**

In IntelliJ: open `bot_java/` as a project, run `TestRunner.main`. Expected output:
```
TestRunner ready. Add test calls here.
```

- [ ] **Step 5: Commit**

```bash
git add bot_java/
git commit -m "chore: add skeleton constants and TestRunner scaffold"
```

---

## Task 2: TrackParams inner class

**Files:**
- Modify: `bot_java/MyCar.java` — replace empty `TrackParams` with full definition and static `PARAMS` array

- [ ] **Step 1: Add failing test to TestRunner**

In `TestRunner.main`, add before the final println:

```java
testTrackParams();
```

Add the test method:

```java
static void testTrackParams() {
    MyCar.TrackParams basic = MyCar.PARAMS[MyCar.TRACK_BASIC];
    assertTrue(basic.maxSpeed == 130f, "BASIC maxSpeed should be 130");
    assertTrue(basic.minSpeed == 40f,  "BASIC minSpeed should be 40");
    assertTrue(basic.steerLookAhead == 5, "BASIC steerLookAhead should be 5");
    assertTrue(basic.speedLookAhead == 6, "BASIC speedLookAhead should be 6");

    MyCar.TrackParams germany = MyCar.PARAMS[MyCar.TRACK_GERMANY];
    assertTrue(germany.maxSpeed == 100f, "GERMANY maxSpeed should be 100");
    assertTrue(germany.steerLookAhead == 8, "GERMANY steerLookAhead should be 8");
    assertTrue(germany.speedLookAhead == 10, "GERMANY speedLookAhead should be 10");

    System.out.println("PASS: TrackParams");
}
```

- [ ] **Step 2: Run TestRunner — expect compile error** (PARAMS does not exist yet)

- [ ] **Step 3: Replace the empty TrackParams class in MyCar.java**

```java
static class TrackParams {
    final float maxSpeed, minSpeed, slowdownFactor;
    final float K1, K2, K3, decayFactor;
    final float accelerationRange, brakeRange;
    final int steerLookAhead, speedLookAhead;

    TrackParams(float maxSpeed, float minSpeed, float slowdownFactor,
                int steerLookAhead, int speedLookAhead,
                float K1, float K2, float K3, float decayFactor,
                float accelerationRange, float brakeRange) {
        this.maxSpeed          = maxSpeed;
        this.minSpeed          = minSpeed;
        this.slowdownFactor    = slowdownFactor;
        this.steerLookAhead    = steerLookAhead;
        this.speedLookAhead    = speedLookAhead;
        this.K1                = K1;
        this.K2                = K2;
        this.K3                = K3;
        this.decayFactor       = decayFactor;
        this.accelerationRange = accelerationRange;
        this.brakeRange        = brakeRange;
    }
}

static final TrackParams[] PARAMS = {
    // BASIC:   maxSpd minSpd slow  steerLA speedLA K1    K2    K3    decay  accR  brkR
    new TrackParams(130, 40, 0.8f,  5,  6, 0.3f, 0.4f, 0.3f, 0.4f, 30, 40),
    // SPEED
    new TrackParams(120, 35, 0.9f,  6,  7, 0.3f, 0.4f, 0.3f, 0.4f, 30, 40),
    // SSAFY
    new TrackParams(110, 30, 1.0f,  7,  8, 0.4f, 0.5f, 0.3f, 0.3f, 25, 35),
    // GERMANY
    new TrackParams(100, 25, 1.2f,  8, 10, 0.5f, 0.6f, 0.4f, 0.5f, 20, 30)
};
```

- [ ] **Step 4: Run TestRunner — expect PASS**

Expected output:
```
PASS: TrackParams
TestRunner ready. Add test calls here.
```

- [ ] **Step 5: Commit**

```bash
git add bot_java/MyCar.java bot_java/TestRunner.java
git commit -m "feat: add TrackParams inner class with per-track constants"
```

---

## Task 3: Track detection

**Files:**
- Modify: `bot_java/MyCar.java` — add `detectTrackType` static method
- Modify: `bot_java/TestRunner.java` — add `testTrackDetection`

- [ ] **Step 1: Add failing test**

In `TestRunner.main`, add:
```java
testTrackDetection();
```

Add the method:
```java
static void testTrackDetection() {
    assertTrue(MyCar.detectTrackType(12.25f) == MyCar.TRACK_SSAFY,
               "half_road_limit 12.25 should be SSAFY");
    assertTrue(MyCar.detectTrackType(8.25f) == MyCar.TRACK_GERMANY,
               "half_road_limit 8.25 should be GERMANY");
    assertTrue(MyCar.detectTrackType(9.25f) == MyCar.TRACK_BASIC,
               "half_road_limit 9.25 should be BASIC");
    assertTrue(MyCar.detectTrackType(9.0f) == MyCar.TRACK_BASIC,
               "half_road_limit 9.0 boundary should be BASIC");
    assertTrue(MyCar.detectTrackType(11.1f) == MyCar.TRACK_SSAFY,
               "half_road_limit 11.1 should be SSAFY");
    System.out.println("PASS: track detection");
}
```

- [ ] **Step 2: Run TestRunner — expect compile error** (`detectTrackType` not yet defined)

- [ ] **Step 3: Add detectTrackType to MyCar.java**

Add as a static method inside `MyCar` (outside `control_driving`, alongside other helpers):

```java
static int detectTrackType(float halfRoadLimit) {
    if (halfRoadLimit > 11.0f) return TRACK_SSAFY;
    if (halfRoadLimit < 9.0f)  return TRACK_GERMANY;
    return TRACK_BASIC;
}
```

- [ ] **Step 4: Run TestRunner — expect PASS**

Expected output includes:
```
PASS: track detection
```

- [ ] **Step 5: Commit**

```bash
git add bot_java/MyCar.java bot_java/TestRunner.java
git commit -m "feat: add static detectTrackType with half_road_limit thresholds"
```

---

## Task 4: Steering controller

**Files:**
- Modify: `bot_java/MyCar.java` — add `computeLookaheadAngle`, `computeSteering`, `clamp`, `toIntArray`
- Modify: `bot_java/TestRunner.java` — add `testSteering`

- [ ] **Step 1: Add failing tests**

In `TestRunner.main`, add:
```java
testSteering();
```

Add the method:
```java
static void testSteering() {
    MyCar.TrackParams p = MyCar.PARAMS[MyCar.TRACK_BASIC];

    // Straight road, centered, aligned → near-zero steering
    int[] straight = new int[20];
    float s1 = MyCar.computeSteering(0f, 9.25f, 0f, straight, p);
    assertTrue(Math.abs(s1) < 0.05f,
               "Centered car on straight should steer ~0, got: " + s1);
    System.out.println("  straight+centered: " + s1);

    // Car to the right of center → should steer left (negative)
    float s2 = MyCar.computeSteering(5f, 9.25f, 0f, straight, p);
    assertTrue(s2 < 0,
               "Car right of center should steer left (negative), got: " + s2);
    System.out.println("  right of center:   " + s2);

    // Right curve ahead → should steer right (positive)
    int[] rightCurve = new int[20];
    for (int i = 0; i < 5; i++) rightCurve[i] = 30;
    float s3 = MyCar.computeSteering(0f, 9.25f, 0f, rightCurve, p);
    assertTrue(s3 > 0,
               "Right curve ahead should steer right (positive), got: " + s3);
    System.out.println("  right curve ahead: " + s3);

    // All three signals maxed left → raw = K1*(-1)+K2*(-1)+K3*(-1) = -1.0 → clamp holds
    int[] leftCurve90 = new int[20];
    for (int i = 0; i < 5; i++) leftCurve90[i] = -90;
    float s4 = MyCar.computeSteering(9.25f, 9.25f, 90f, leftCurve90, p);
    assertTrue(Math.abs(s4 - (-1.0f)) < 0.001f,
               "All signals maxed left should yield -1.0, got: " + s4);
    System.out.println("  all-left maxed (clamped): " + s4);

    System.out.println("PASS: steering");
}
```

- [ ] **Step 2: Run TestRunner — expect compile error**

- [ ] **Step 3: Add helper methods to MyCar.java**

Add these static methods inside `MyCar`:

```java
static float computeLookaheadAngle(int[] angles, TrackParams p) {
    double wSum = 0, aSum = 0;
    int n = Math.min(p.steerLookAhead, angles.length);
    for (int i = 0; i < n; i++) {
        double w = Math.exp(-i * p.decayFactor);
        aSum += angles[i] * w;
        wSum += w;
    }
    return wSum == 0 ? 0f : (float) (aSum / wSum / 90.0);
}

static float computeSteering(float toMiddle, float halfRoadLimit,
                               float movingAngle, int[] angles, TrackParams p) {
    float centerError    = -(toMiddle / halfRoadLimit);
    float angleError     = -(movingAngle / 90.0f);
    float lookaheadAngle = computeLookaheadAngle(angles, p);
    float raw = p.K1 * centerError + p.K2 * angleError + p.K3 * lookaheadAngle;
    return clamp(raw, -1.0f, 1.0f);
}

static float clamp(float v, float min, float max) {
    return Math.max(min, Math.min(max, v));
}

static int[] toIntArray(java.util.ArrayList<Integer> list) {
    int[] arr = new int[list.size()];
    for (int i = 0; i < list.size(); i++) arr[i] = list.get(i);
    return arr;
}
```

- [ ] **Step 4: Run TestRunner — expect PASS**

Expected output includes:
```
  straight+centered: 0.0
  right of center:   -0.32...
  right curve ahead: 0.09...
  extreme right (clamped): -1.0
PASS: steering
```

- [ ] **Step 5: Commit**

```bash
git add bot_java/MyCar.java bot_java/TestRunner.java
git commit -m "feat: add weighted lookahead steering with center/angle/curve signals"
```

---

## Task 5: Speed controller

**Files:**
- Modify: `bot_java/MyCar.java` — add `computeTargetSpeed`, `applySpeedControl`
- Modify: `bot_java/TestRunner.java` — add `testSpeed`

- [ ] **Step 1: Add failing tests**

In `TestRunner.main`, add:
```java
testSpeed();
```

Add the method:
```java
static void testSpeed() {
    MyCar.TrackParams p = MyCar.PARAMS[MyCar.TRACK_BASIC];

    // Straight road → target equals maxSpeed
    int[] straight = new int[20];
    float t1 = MyCar.computeTargetSpeed(straight, p);
    assertTrue(t1 == 130f,
               "Straight road target should be maxSpeed (130), got: " + t1);
    System.out.println("  straight target speed: " + t1);

    // Sharp curve (angle=60) → reduced speed
    int[] sharp = new int[20];
    sharp[0] = 60;
    float t2 = MyCar.computeTargetSpeed(sharp, p);
    assertTrue(t2 < 100f,
               "Sharp curve should reduce speed below 100, got: " + t2);
    System.out.println("  sharp curve target:    " + t2);

    // Extreme curve → clamped to minSpeed
    int[] extreme = new int[20];
    for (int i = 0; i < 6; i++) extreme[i] = 90;
    float t3 = MyCar.computeTargetSpeed(extreme, p);
    assertTrue(t3 == 40f,
               "Extreme curve should clamp to minSpeed (40), got: " + t3);
    System.out.println("  extreme curve target:  " + t3);

    System.out.println("PASS: speed control");
}
```

- [ ] **Step 2: Run TestRunner — expect compile error**

- [ ] **Step 3: Add speed control methods to MyCar.java**

```java
static float computeTargetSpeed(int[] angles, TrackParams p) {
    float maxCurve = 0;
    int n = Math.min(p.speedLookAhead, angles.length);
    for (int i = 0; i < n; i++) {
        maxCurve = Math.max(maxCurve, Math.abs(angles[i]));
    }
    return clamp(p.maxSpeed - p.slowdownFactor * maxCurve, p.minSpeed, p.maxSpeed);
}

static void applySpeedControl(float currentSpeed, int[] angles,
                               TrackParams p, CarControls car_controls) {
    float targetSpeed = computeTargetSpeed(angles, p);
    float diff = targetSpeed - currentSpeed;
    if (diff > 0) {
        car_controls.throttle = Math.min(1.0f, diff / p.accelerationRange);
        car_controls.brake    = 0f;
    } else {
        car_controls.throttle = 0f;
        car_controls.brake    = Math.min(1.0f, -diff / p.brakeRange);
    }
}
```

- [ ] **Step 4: Run TestRunner — expect PASS**

Expected output includes:
```
  straight target speed: 130.0
  sharp curve target:    82.0
  extreme curve target:  40.0
PASS: speed control
```

- [ ] **Step 5: Commit**

```bash
git add bot_java/MyCar.java bot_java/TestRunner.java
git commit -m "feat: add curve-based speed controller with throttle/brake decision"
```

---

## Task 6: Wire control_driving

**Files:**
- Modify: `bot_java/MyCar.java` — implement `control_driving` body

- [ ] **Step 1: Replace the body of control_driving with the full wiring**

```java
@Override
public void control_driving(DrivingInfo sensing_info, CarControls car_controls) {
    // Track detection: once on first call, upgrade Basic→Speed on first obstacle
    if (!trackInitialized) {
        trackType = detectTrackType(sensing_info.half_road_limit);
        trackInitialized = true;
    }
    if (trackType == TRACK_BASIC && !sensing_info.track_forward_obstacles.isEmpty()) {
        trackType = TRACK_SPEED;
    }

    TrackParams p = PARAMS[trackType];
    int[] angles = toIntArray(sensing_info.track_forward_angles);

    car_controls.steering = computeSteering(
        sensing_info.to_middle,
        sensing_info.half_road_limit,
        sensing_info.moving_angle,
        angles, p
    );

    applySpeedControl(sensing_info.speed, angles, p, car_controls);
}
```

- [ ] **Step 2: Verify entire project compiles**

In IntelliJ: Build > Build Project. Expected: no errors.

- [ ] **Step 3: Run TestRunner one final time — all tests must pass**

Expected:
```
PASS: TrackParams
PASS: track detection
PASS: steering
PASS: speed control
TestRunner ready. Add test calls here.
```

- [ ] **Step 4: Commit**

```bash
git add bot_java/MyCar.java
git commit -m "feat: wire control_driving with track detection, steering, and speed control"
```

---

## Task 7: Simulator test on Map 10

**Goal:** confirm the bot completes a lap on Basic Round without going off-road.

- [ ] **Step 1: Set settings.json to Map 10**

File: `C:\Users\{username}\Documents\AirSim\settings.json`
```json
{
  "SettingsVersion": 1.2,
  "SimMode": "Car",
  "Algo": { "Map": "10" },
  "Vehicles": {
    "Car1": { "VehicleType": "PhysXCar", "X": 0, "Y": 0, "Z": 0 }
  }
}
```

- [ ] **Step 2: Launch simulator**

Run `run.bat`. Wait for the simulator window to appear and show the track.

- [ ] **Step 3: Run MyCar.java**

In IntelliJ: right-click `MyCar.java` > Run. The car should start moving.

- [ ] **Step 4: Observe and record**

Watch for:
- Car stays on road through all curves
- `lap_progress` reaches 100 (one full lap)
- No prolonged off-road penalty (brake=0.9 forced by simulator)

Note the lap time shown in the simulator HUD.

- [ ] **Step 5: Tune if needed**

If the car consistently goes off-road at a specific curve, increase `K1` or `K2` in `PARAMS[TRACK_BASIC]`.
If the car is too slow on straights, increase `maxSpeed` or decrease `slowdownFactor`.
Rebuild and re-run after each change.

- [ ] **Step 6: Commit final tuned values**

```bash
git add bot_java/MyCar.java
git commit -m "tune: adjust BASIC track params after simulator test"
```

---

## Out of Scope (future plans)

- Obstacle avoidance for SPEED / SSAFY / GERMANY tracks
- Multi-player opponent handling (`opponent_cars_info`)
- Racing line optimization (apex positioning via `to_middle` control)
