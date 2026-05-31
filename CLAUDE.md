# SSAFY Race

Autonomous driving racing bot for the SSAFY (Samsung Software Academy for Youth) competition.
The bot controls a vehicle in an AirSim (Unreal Engine 4) simulator via algorithm.

## Critical Constraint

**Only `MyCar.java` is submitted.** No other file changes are reflected on the server.

Allowed modification areas inside `MyCar.java`:
- Member variable declarations
- Inside the `control_driving` method
- Custom functions and classes
- `sensing_info.half_road_limit` is accessible

## Architecture

```
DrivingInterface.dll  →  calls control_driving() every 0.1 seconds
DrivingInterface.java →  raw data processing (do not modify)
MyCar.java            →  driving logic (the only file to edit and submit)
```

## Sensing API

Received as `sensing_info` parameter in `control_driving(sensing_info, car_controls)`.

| Field | Type | Description |
|-------|------|-------------|
| `to_middle` | float | Distance from road center (m). Positive = right, negative = left |
| `speed` | float | Current speed (km/h) |
| `moving_forward` | bool | true = forward, false = reverse |
| `moving_angle` | float | Alignment angle with road. 0 = parallel, + = right-leaning, − = left-leaning |
| `collided` | bool | Whether currently colliding |
| `lap_progress` | float | Completion percentage 0–100 |
| `track_forward_angles` | list[int] | Road angles for 20 segments (10m each) up to 200m ahead. Positive = right curve |
| `track_forward_obstacles` | list | Obstacles within 200m: `{dist, to_middle}`. Fixed width 2m (±1m from center) |
| `opponent_cars_info` | list | Nearby opponents within ±200m: `{car_name, dist, to_middle, speed}`. dist positive = ahead |
| `distance_to_way_points` | list[float] | Straight-line distances to next 20 waypoints |
| `half_road_limit` | float | Road-out threshold = half road width + half car width (1.25m) |

## Control API

Write values to `car_controls` inside `control_driving`.

| Field | Range | Description |
|-------|-------|-------------|
| `steering` | −1.0 to +1.0 | Positive = right, negative = left |
| `throttle` | −1.0 to +1.0 | Positive = forward, negative = reverse (auto gear) |
| `brake` | 0.0 to 1.0 | Decelerate/stop, independent of throttle |

When the car goes off-road, the simulator automatically sets brake = 0.9.

## Tracks

| Map ID | Name | Road Width | Length | Use |
|--------|------|-----------|--------|-----|
| 10 | Basic Round | 16m | 1,360m | Competition (no obstacles) |
| 31 | Speed Racing | 16m | 1,860m | Competition |
| 61 | SSAFY Track | 22m | 5,910m | Competition |
| 71 | SSAFY Track (low-spec) | 22m | 5,910m | Competition |
| 161 | Germany Track | 14m | 4,574m | Competition |
| 30/60/70/160 | Obstacle-free variants | — | — | Practice |

## Running the Simulator

`settings.json` location: `C:\Users\{username}\Documents\AirSim\settings.json`

Single-player example:
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

- Single: run `run.bat` → execute `MyCar.java`
- Multi (2-player): run `runsv.bat` → launch clients in order; set Car1 Y=−4, Car2 Y=4
- `Backspace`: reset simulator | `F8`: keyboard manual mode

## Project Layout

```
ssafy-race/
├── CLAUDE.md
├── .claude/logs/          # work logs
├── docs/
│   ├── 싸피레이스_Quick+Start_20260515.pdf
│   └── 싸피레이스_상세가이드_20260515.pdf
└── bot_java/              # place downloaded template here
    ├── DrivingInterface.java
    ├── DrivingInterface.dll
    └── MyCar.java         # develop and submit this file
```

Bot template: download separately from the competition board.

## Environment

- Language: Java (JDK 1.8+)
- IDE: IntelliJ or Eclipse
- Simulator OS: Windows 7 / Windows 10 64-bit
