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

- `Main`: owns round state, initial spawning, elimination, in-place reset, and
  pause-menu coordination.
- `Court`: static collision and spawn markers only.
- `Player`: normal/sprint movement, grounded jump, safe crouch, mouse look,
  possession, throw charging, catch window, and collision-safe dodge cooldown.
- `Ball`: physical motion, ownership state, collision reporting, pickup eligibility, and reset.
- `Target`: receives valid hits and reports elimination.
- `UI`: crosshair, minimal catch/dodge/result indicators, and the basic
  pause/controls overlay.

## Communication

Use signals for major events such as:

- ball picked up
- ball thrown
- valid hit
- catch succeeded
- entity eliminated
- round reset

`Main` coordinates the round. Player and ball should not directly own global round state.

`Main.restart_round()` resets the existing player, ball, and target through
their reset methods. It must not instantiate replacements or reconnect signals.
`Main` also handles Escape and R before ordinary player input. Its process mode,
and the pause overlay's process mode, remain active while the `SceneTree` is
paused; gameplay nodes retain normal processing and therefore stop.

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
