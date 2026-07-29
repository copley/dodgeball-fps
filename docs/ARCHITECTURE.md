# Architecture

## Intended structure

```text
dodgeball-fps/
├── project.godot
├── AGENTS.md
├── README.md
├── docs/
│   ├── SPEC.md
│   ├── ARCHITECTURE.md
│   ├── TASKS.md
│   └── TESTING.md
├── scenes/
│   ├── main.tscn
│   ├── court.tscn
│   ├── player.tscn
│   ├── ball.tscn
│   ├── target.tscn
│   └── ui.tscn
├── scripts/
│   ├── main.gd
│   ├── player.gd
│   ├── ball.gd
│   ├── target.gd
│   └── ui.gd
└── assets/
    ├── materials/
    ├── models/
    ├── textures/
    └── audio/
```

## Node responsibilities

- `Main`: owns round state, spawning, elimination, and reset.
- `Court`: static collision and spawn markers only.
- `Player`: movement, mouse look, possession, throw charging, catch window, and dodge cooldown.
- `Ball`: physical motion, ownership state, collision reporting, pickup eligibility, and reset.
- `Target`: receives valid hits and reports elimination.
- `UI`: crosshair and minimal state indicators only.

## Communication

Use signals for major events such as:

- ball picked up
- ball thrown
- valid hit
- catch succeeded
- entity eliminated
- round reset

`Main` coordinates the round. Player and ball should not directly own global round state.

## State boundaries

Ball state should be explicit and mutually exclusive:

```text
AVAILABLE -> HELD -> THROWN -> AVAILABLE
                    -> CAUGHT -> HELD
```

Player state remains lightweight:

```text
ACTIVE
CATCHING
DODGING
ELIMINATED
```

Avoid introducing a general-purpose framework or ECS for the pilot.
