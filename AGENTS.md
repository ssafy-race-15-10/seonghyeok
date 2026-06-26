# SSAFY Race Agent Guide

This repository contains an autonomous driving racing bot for the SSAFY competition.

## Critical Constraint

Only `Bot_Java/MyCar.java` is submitted to the competition server. Keep behavior changes there unless the user explicitly asks for local tooling, tests, docs, or simulator configuration.

Allowed in `MyCar.java`:
- Member variable declarations
- The `control_driving` method body
- Custom helper functions and classes

Do not modify `Bot_Java/DrivingInterface.java` unless the user explicitly asks; it provides raw data processing and the simulator callback surface.

## Architecture

```text
DrivingInterface.dll  -> calls control_driving() every 0.1 seconds
DrivingInterface.java -> raw data processing; avoid modifying
MyCar.java            -> driving logic; the only submitted source file
TestRunner.java       -> local unit test harness; not submitted
```

`car_controls` is the static `MyCar` instance. Write control outputs directly through `car_controls.steering`, `car_controls.throttle`, and `car_controls.brake`.

## Useful References

- Sensing and control API: `docs/api-reference.md`
- Tracks, `settings.json`, and simulator shortcuts: `docs/simulator.md`
- Algorithm design: `docs/superpowers/specs/2026-05-31-driving-algorithm-design.md`
- Implementation plan: `docs/superpowers/plans/2026-05-31-driving-algorithm.md`

## Development Notes

- Language/runtime: Java, JDK 1.8+
- Primary local project: `Bot_Java`
- Simulator target OS: Windows 7 / Windows 10 64-bit
- Match the existing Java style in `MyCar.java`; keep edits small and competition-focused.
- Avoid broad refactors, new dependencies, or generated artifacts unless they are directly needed for the requested task.

## Verification

For changes to driving logic, prefer targeted local checks first:

```sh
cd Bot_Java
javac MyCar.java TestRunner.java
java TestRunner
```

If simulator behavior matters, state which `settings/*.json` map or simulator scenario was used. If the simulator cannot be run from the current environment, report the compile/test evidence and the remaining simulator-validation gap.
